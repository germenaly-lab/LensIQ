import { CameraService } from './camera.service';
import { StreamSessionDescriptor, AuthenticatedUser } from '../types/backend.types';
import { StreamProfile } from '../../types/camera';
import { StreamSessionManager } from '../streaming/gateway/stream-session.manager';
import { StreamSecurityService } from '../streaming/gateway/stream-security.service';
import {
  UnifiedStreamSession,
  StreamSessionRequest,
  StreamMonitoringStats,
  StreamProtocol,
} from '../streaming/types/streaming.types';

export type ExtendedStreamSession = UnifiedStreamSession & StreamSessionDescriptor;

/**
 * StreamingGatewayService
 * Upgraded in Phase 4 to incorporate multi-source stream session management,
 * viewer reference counting, single-pipeline-per-camera process management,
 * and zero credential exposure to Flutter clients.
 */
export class StreamingGatewayService {
  private cameraService: CameraService;
  private sessionManager: StreamSessionManager;
  private securityService: StreamSecurityService;
  private gatewayBaseUrl: string;

  constructor(
    cameraService: CameraService,
    gatewayBaseUrl: string = 'https://stream.lensiq.cloud',
    sessionManager?: StreamSessionManager
  ) {
    this.cameraService = cameraService;
    this.gatewayBaseUrl = gatewayBaseUrl;
    this.securityService = new StreamSecurityService();
    this.sessionManager =
      sessionManager ||
      new StreamSessionManager(this.securityService, {
        gatewayBaseUrl: this.gatewayBaseUrl,
        idleGracePeriodMs: 30000,
      });
  }

  get manager(): StreamSessionManager {
    return this.sessionManager;
  }

  /**
   * Orchestrates the creation of or attachment to a streaming session.
   * Conceptually:
   * camera ➔ source_type ➔ RTSPSourceAdapter OR HikvisionP2PSourceAdapter ➔ Streaming Gateway ➔ WebRTC/HLS
   *
   * Reuses active pipelines across multiple viewers to avoid spawning uncontrolled FFmpeg processes.
   */
  async createSession(
    user: AuthenticatedUser,
    cameraId: string,
    optionsOrProfile: StreamProfile | StreamSessionRequest = 'main'
  ): Promise<ExtendedStreamSession> {
    // 1. Fetch raw internal camera (verifies tenant authorization)
    const camera = await this.cameraService.getRawCamera(user, cameraId);

    // Normalize options
    const requestOptions: StreamSessionRequest =
      typeof optionsOrProfile === 'string'
        ? { streamProfile: optionsOrProfile }
        : optionsOrProfile;

    const profile: StreamProfile = requestOptions.streamProfile || camera.stream_profile || 'main';
    const protocol: StreamProtocol = requestOptions.protocol || 'webrtc';

    // 2. Request or attach to managed stream pipeline
    const unifiedSession = await this.sessionManager.requestSession(user, camera, {
      ...requestOptions,
      streamProfile: profile,
      protocol,
    });

    // 3. For Hikvision P2P, ensure endpoint matches expected routing
    const isP2P = camera.source_type === 'hikvision_p2p';
    const p2pEndpoint = isP2P
      ? `${this.gatewayBaseUrl}/api/v1/streams/live/p2p/${camera.hik_device_id || camera.hik_serial_number || camera.id}/ch${camera.hik_channel || 1}?token=${unifiedSession.token}`
      : unifiedSession.stream_url;

    // AI normalized URL consumed by Phase 2 Computer Vision microservice
    const aiNormalizedUrl = `${this.gatewayBaseUrl}/api/v1/internal/raw-feed/${camera.id}?token=${unifiedSession.token}`;

    // Combine Phase 4 unified session with Phase 3 descriptor properties for full backward compatibility
    return {
      ...unifiedSession,
      stream_url: isP2P ? p2pEndpoint : unifiedSession.stream_url,

      // Phase 3 compatibility aliases
      sessionId: unifiedSession.session_id,
      cameraId: camera.id,
      sourceType: camera.source_type,
      connectionStatus: unifiedSession.monitoring.connection_status === 'streaming' ? 'online' : (unifiedSession.monitoring.connection_status as any),
      streamProfile: profile,
      playbackProtocol: protocol,
      streamEndpoint: isP2P ? p2pEndpoint : unifiedSession.stream_url,
      aiNormalizedStreamUrl: aiNormalizedUrl,
      isP2P,
      createdAt: unifiedSession.created_at,
      expiresAt: unifiedSession.expires_at,
      metadata: {
        viewerCount: unifiedSession.viewer_count,
        demoMode: unifiedSession.demo_mode,
        codec: unifiedSession.stream_info.codec,
      },
    };
  }

  /**
   * Reconnect a camera stream
   */
  async reconnectCamera(user: AuthenticatedUser, cameraId: string): Promise<StreamMonitoringStats> {
    const camera = await this.cameraService.getRawCamera(user, cameraId);
    this.securityService.authorizeUserForCamera(user, camera);
    return this.sessionManager.reconnectCamera(cameraId);
  }

  /**
   * Stop / leave a stream session (decrements viewer count, triggers idle cleanup if 0)
   */
  async stopSession(
    user: AuthenticatedUser,
    cameraId: string,
    sessionId: string
  ): Promise<{ released: boolean; remainingViewers: number; pipelineState: string }> {
    const camera = await this.cameraService.getRawCamera(user, cameraId);
    this.securityService.authorizeUserForCamera(user, camera);
    return this.sessionManager.releaseSession(cameraId, sessionId);
  }

  /**
   * Get real-time health telemetry for a camera stream
   */
  async getStreamStatus(user: AuthenticatedUser, cameraId: string): Promise<StreamMonitoringStats> {
    const camera = await this.cameraService.getRawCamera(user, cameraId);
    this.securityService.authorizeUserForCamera(user, camera);
    return this.sessionManager.getMonitoringStats(cameraId);
  }

  /**
   * Validate a playback session token (called by media player before receiving WebRTC SDP or HLS manifest)
   */
  verifyPlaybackToken(token: string): { valid: boolean; session?: UnifiedStreamSession; error?: string } {
    return this.sessionManager.verifyPlayback(token);
  }
}
