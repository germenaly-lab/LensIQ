import { Camera, StreamProfile } from '../../../types/camera';
import { AuthenticatedUser } from '../../types/backend.types';
import { IVideoSourceAdapter } from '../adapters/video-source.adapter';
import { RTSPSourceAdapter } from '../adapters/rtsp-source.adapter';
import { HikvisionP2PSourceAdapter } from '../adapters/hikvision-p2p-source.adapter';
import { StreamSecurityService } from './stream-security.service';
import { StreamHealthMonitor } from './stream-health-monitor';
import {
  UnifiedStreamSession,
  StreamSessionRequest,
  StreamInfo,
  StreamMonitoringStats,
  StreamProtocol,
} from '../types/streaming.types';

export interface ViewerSession {
  sessionId: string;
  userId: string;
  userRole: string;
  protocol: StreamProtocol;
  token: string;
  createdAt: string;
  expiresAt: string;
}

export interface IngestPipeline {
  cameraId: string;
  camera: Camera;
  adapter: IVideoSourceAdapter;
  streamInfo: StreamInfo;
  healthMonitor: StreamHealthMonitor;
  viewers: Map<string, ViewerSession>;
  idleTimeoutTimer: NodeJS.Timeout | null;
  state: 'active' | 'idle' | 'terminating';
  createdAt: string;
}

export interface StreamSessionManagerOptions {
  gatewayBaseUrl?: string;
  idleGracePeriodMs?: number; // Time to wait before stopping ingest when viewer count drops to 0
  sessionDurationMs?: number; // Viewer token TTL
}

/**
 * StreamSessionManager
 *
 * Enterprise Lifecycle & Pipeline Manager.
 * Solves the critical performance constraint:
 * "Do not create one uncontrolled FFmpeg process per API request.
 * Use managed stream sessions and proper process lifecycle management."
 *
 * Architecture:
 * - Ingest Pipeline Deduplication: Exactly ONE ingest pipeline per camera, regardless of viewer count.
 * - Multi-Viewer Multiplexing: Multiple branch managers / Flutter devices attach to the active pipeline.
 * - Graceful Idle Reaper: Automatically tears down source connections and frees memory when viewers leave.
 */
export class StreamSessionManager {
  private pipelines: Map<string, IngestPipeline> = new Map();
  private securityService: StreamSecurityService;
  private gatewayBaseUrl: string;
  private idleGracePeriodMs: number;
  private sessionDurationMs: number;

  constructor(
    securityService?: StreamSecurityService,
    options: StreamSessionManagerOptions = {}
  ) {
    this.securityService = securityService || new StreamSecurityService();
    this.gatewayBaseUrl = options.gatewayBaseUrl || 'https://stream.lensiq.cloud';
    this.idleGracePeriodMs = options.idleGracePeriodMs ?? 30000;
    this.sessionDurationMs = options.sessionDurationMs ?? 3600 * 1000;
  }

  get activePipelineCount(): number {
    return this.pipelines.size;
  }

  getPipeline(cameraId: string): IngestPipeline | undefined {
    return this.pipelines.get(cameraId);
  }

  /**
   * Request or attach to a stream session for a camera.
   * If a pipeline already exists for this camera, reuses it and attaches the new viewer!
   */
  async requestSession(
    user: AuthenticatedUser,
    camera: Camera,
    request: StreamSessionRequest = {}
  ): Promise<UnifiedStreamSession> {
    // 1. Enforce Multi-tenant & Branch Authorization
    this.securityService.authorizeUserForCamera(user, camera);

    const protocol = request.protocol || 'webrtc';
    const profile = request.streamProfile || camera.stream_profile || 'main';

    let pipeline = this.pipelines.get(camera.id);

    // If pipeline does not exist or was terminating, spin up a single managed pipeline
    if (!pipeline || pipeline.state === 'terminating') {
      pipeline = await this.startNewPipeline(camera, profile, request.demoMode);
      this.pipelines.set(camera.id, pipeline);
    } else {
      // If pipeline was in idle countdown (waiting for reaper), cancel the timer
      if (pipeline.idleTimeoutTimer) {
        clearTimeout(pipeline.idleTimeoutTimer);
        pipeline.idleTimeoutTimer = null;
        pipeline.state = 'active';
      }
    }

    // 2. Register new viewer session onto the shared pipeline
    const sessionId = `sess_${camera.id.slice(0, 8)}_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const { token, expiresAt } = this.securityService.generateSessionToken(
      sessionId,
      camera,
      protocol,
      this.sessionDurationMs
    );

    const viewerSession: ViewerSession = {
      sessionId,
      userId: user.id,
      userRole: user.role,
      protocol,
      token,
      createdAt: new Date().toISOString(),
      expiresAt,
    };

    pipeline.viewers.set(sessionId, viewerSession);
    pipeline.healthMonitor.setViewerCount(pipeline.viewers.size);

    // 3. Construct unified session response for Flutter
    return this.buildUnifiedSession(pipeline, viewerSession);
  }

  /**
   * Release a viewer session.
   * Decrements viewer count. When 0, starts the idle grace timer to reap pipeline.
   */
  async releaseSession(
    cameraId: string,
    sessionId: string
  ): Promise<{ released: boolean; remainingViewers: number; pipelineState: string }> {
    const pipeline = this.pipelines.get(cameraId);
    if (!pipeline) {
      return { released: false, remainingViewers: 0, pipelineState: 'not_found' };
    }

    const removed = pipeline.viewers.delete(sessionId);
    pipeline.healthMonitor.setViewerCount(pipeline.viewers.size);

    // If no active viewers remain, enter idle grace period
    if (pipeline.viewers.size === 0) {
      pipeline.state = 'idle';
      if (!pipeline.idleTimeoutTimer) {
        pipeline.idleTimeoutTimer = setTimeout(async () => {
          await this.reapPipeline(cameraId);
        }, this.idleGracePeriodMs);
      }
    }

    return {
      released: removed,
      remainingViewers: pipeline.viewers.size,
      pipelineState: pipeline.state,
    };
  }

  /**
   * Explicit reconnect on camera source
   */
  async reconnectCamera(cameraId: string): Promise<StreamMonitoringStats> {
    const pipeline = this.pipelines.get(cameraId);
    if (!pipeline) {
      throw new Error(`Cannot reconnect camera '${cameraId}': No active stream session exists.`);
    }

    await pipeline.adapter.reconnect();
    const status = await pipeline.adapter.getStatus();
    pipeline.healthMonitor.updateFromAdapter(status);
    return pipeline.healthMonitor.getSnapshot();
  }

  /**
   * Get live monitoring statistics for a camera
   */
  async getMonitoringStats(cameraId: string): Promise<StreamMonitoringStats> {
    const pipeline = this.pipelines.get(cameraId);
    if (!pipeline) {
      return {
        connection_status: 'offline',
        latency_ms: 0,
        reconnect_count: 0,
        last_error: null,
        last_successful_frame: null,
        stream_start_time: null,
        uptime_seconds: 0,
        viewer_count: 0,
      };
    }

    const adapterStatus = await pipeline.adapter.getStatus();
    pipeline.healthMonitor.updateFromAdapter(adapterStatus);
    return pipeline.healthMonitor.getSnapshot();
  }

  /**
   * Verify token and retrieve session for playback verification
   */
  verifyPlayback(token: string): { valid: boolean; session?: UnifiedStreamSession; error?: string } {
    const check = this.securityService.verifySessionToken(token);
    if (!check.valid || !check.payload) {
      return { valid: false, error: check.error };
    }

    const pipeline = this.pipelines.get(check.payload.cameraId);
    if (!pipeline) {
      return { valid: false, error: 'Underlying camera stream is no longer active' };
    }

    const viewer = pipeline.viewers.get(check.payload.sessionId);
    if (!viewer) {
      return { valid: false, error: 'Viewer session has been terminated' };
    }

    return {
      valid: true,
      session: this.buildUnifiedSession(pipeline, viewer),
    };
  }

  /**
   * Clean up all active pipelines on shutdown
   */
  async shutdownAll(): Promise<void> {
    const cameraIds = Array.from(this.pipelines.keys());
    for (const id of cameraIds) {
      await this.reapPipeline(id);
    }
  }

  // --------------------------------------------------------------------------
  // Internal Helpers
  // --------------------------------------------------------------------------

  private async startNewPipeline(
    camera: Camera,
    profile: StreamProfile,
    demoMode?: boolean
  ): Promise<IngestPipeline> {
    // Instantiate appropriate source adapter
    let adapter: IVideoSourceAdapter;
    if (camera.source_type === 'rtsp') {
      adapter = new RTSPSourceAdapter({
        camera,
        isDemo: demoMode,
      });
    } else {
      adapter = new HikvisionP2PSourceAdapter({
        camera,
        isDemo: demoMode,
      });
    }

    const healthMonitor = new StreamHealthMonitor(camera.id);

    // Setup adapter telemetry event wiring
    adapter.on('frame', ({ timestamp }: { timestamp: string }) => {
      healthMonitor.recordFrame(timestamp);
    });

    adapter.on('reconnecting', ({ attempt }: { attempt: number }) => {
      healthMonitor.recordReconnect(attempt);
    });

    adapter.on('statusChange', ({ to }: { to: string }) => {
      if (to === 'error') {
        healthMonitor.recordError('Source adapter entered error state');
      }
    });

    // Establish connection and initiate stream acquisition
    await adapter.connect();
    const streamInfo = await adapter.startStream(profile);

    const adapterStatus = await adapter.getStatus();
    healthMonitor.updateFromAdapter(adapterStatus);

    return {
      cameraId: camera.id,
      camera,
      adapter,
      streamInfo,
      healthMonitor,
      viewers: new Map(),
      idleTimeoutTimer: null,
      state: 'active',
      createdAt: new Date().toISOString(),
    };
  }

  private async reapPipeline(cameraId: string): Promise<void> {
    const pipeline = this.pipelines.get(cameraId);
    if (!pipeline) return;

    pipeline.state = 'terminating';
    if (pipeline.idleTimeoutTimer) {
      clearTimeout(pipeline.idleTimeoutTimer);
      pipeline.idleTimeoutTimer = null;
    }

    try {
      await pipeline.adapter.stopStream();
      await pipeline.adapter.disconnect();
      pipeline.adapter.removeAllListeners();
    } catch (err) {
      console.error(`[StreamingGateway] Error while stopping adapter for camera ${cameraId}:`, err);
    } finally {
      this.pipelines.delete(cameraId);
    }
  }

  private buildUnifiedSession(
    pipeline: IngestPipeline,
    viewer: ViewerSession
  ): UnifiedStreamSession {
    const safeUrl = this.securityService.buildSafePlaybackUrl(
      this.gatewayBaseUrl,
      pipeline.cameraId,
      viewer.sessionId,
      viewer.protocol,
      viewer.token
    );

    return {
      session_id: viewer.sessionId,
      camera_id: pipeline.cameraId,
      source_type: pipeline.camera.source_type,
      stream_url: safeUrl,
      token: viewer.token,
      protocol: viewer.protocol,
      status: pipeline.state === 'active' ? 'active' : 'idle',
      created_at: viewer.createdAt,
      expires_at: viewer.expiresAt,
      viewer_count: pipeline.viewers.size,
      demo_mode: pipeline.streamInfo.isDemo,
      stream_info: {
        resolution: `${pipeline.streamInfo.resolution.width}x${pipeline.streamInfo.resolution.height}`,
        fps: pipeline.streamInfo.fps,
        codec: pipeline.streamInfo.codec,
        profile: pipeline.streamInfo.profile,
      },
      monitoring: pipeline.healthMonitor.getSnapshot(),
    };
  }
}
