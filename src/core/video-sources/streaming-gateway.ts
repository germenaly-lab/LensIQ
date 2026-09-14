import { VideoSource, StreamDescriptor, GatewayPipelinePayload } from './video-source.interface';
import { CredentialsVaultService } from '../security/credentials-vault';

export interface GatewaySession {
  sessionId: string;
  cameraId: string;
  sourceType: string;
  status: 'initializing' | 'active' | 'terminated';
  pipeline: GatewayPipelinePayload;
  descriptor: StreamDescriptor;
  startedAt: Date;
}

/**
 * Streaming Gateway Service
 * Operates purely on the VideoSource abstraction without assuming an RTSP URL.
 * Handles pipeline registration, token injection from the Credentials Vault,
 * and stream descriptor generation for Web and Flutter clients.
 */
export class StreamingGateway {
  private activeSessions: Map<string, GatewaySession> = new Map();
  private baseUrl: string;
  private vaultService: CredentialsVaultService;

  constructor(baseUrl: string = 'https://stream.lensiq.cloud', vaultService?: CredentialsVaultService) {
    this.baseUrl = baseUrl;
    this.vaultService = vaultService || new CredentialsVaultService();
  }

  /**
   * Start or retrieve an active streaming pipeline for any supported VideoSource.
   */
  async initializeStreamPipeline(videoSource: VideoSource): Promise<GatewaySession> {
    // 1. Validate the source configuration through the abstraction
    const validation = videoSource.validateConfiguration();
    if (!validation.isValid) {
      throw new Error(`Invalid camera source configuration: ${validation.errors.join(', ')}`);
    }

    if (!videoSource.enabled) {
      throw new Error(`Camera '${videoSource.name}' is currently disabled.`);
    }

    // Check if session already exists
    const existingSession = this.activeSessions.get(videoSource.id);
    if (existingSession && existingSession.status === 'active') {
      return existingSession;
    }

    // 2. Resolve credentials from the protected Vault if a reference exists
    let secretToken: string | undefined;
    if (videoSource.credentialsReference) {
      secretToken = await this.vaultService.resolveSecret(videoSource.credentialsReference);
    }

    // 3. Obtain pipeline payload from the VideoSource abstraction
    const pipelinePayload = videoSource.getGatewayPipelinePayload(secretToken);

    // 4. Generate client descriptor
    const descriptor = videoSource.getStreamDescriptor(this.baseUrl);

    const session: GatewaySession = {
      sessionId: `sess_${videoSource.id}_${Date.now()}`,
      cameraId: videoSource.id,
      sourceType: videoSource.sourceType,
      status: 'active',
      pipeline: pipelinePayload,
      descriptor,
      startedAt: new Date(),
    };

    this.activeSessions.set(videoSource.id, session);
    return session;
  }

  /**
   * Terminate stream pipeline
   */
  terminateStreamPipeline(cameraId: string): boolean {
    const session = this.activeSessions.get(cameraId);
    if (!session) return false;
    session.status = 'terminated';
    this.activeSessions.delete(cameraId);
    return true;
  }

  /**
   * Get active session info
   */
  getSession(cameraId: string): GatewaySession | undefined {
    return this.activeSessions.get(cameraId);
  }

  /**
   * List all currently active gateway streams
   */
  listActiveSessions(): GatewaySession[] {
    return Array.from(this.activeSessions.values());
  }
}
