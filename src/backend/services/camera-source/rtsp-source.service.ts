import { Camera, CameraSourceType, StreamProfile } from '../../../types/camera';
import { ConnectionStatus, StreamSessionDescriptor } from '../../types/backend.types';
import { ICameraSourceService, ValidationResult } from './camera-source.interface';

export class RTSPSourceService implements ICameraSourceService {
  public readonly sourceType: CameraSourceType = 'rtsp';

  validateConfiguration(camera: Camera): ValidationResult {
    const errors: string[] = [];

    if (!camera.rtsp_url || camera.rtsp_url.trim().length === 0) {
      errors.push('RTSP URL is required for RTSP camera source.');
    } else if (!camera.rtsp_url.startsWith('rtsp://') && !camera.rtsp_url.startsWith('rtsps://')) {
      errors.push('RTSP URL must start with rtsp:// or rtsps:// protocol prefix.');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  async checkConnectionStatus(camera: Camera): Promise<ConnectionStatus> {
    const validation = this.validateConfiguration(camera);
    if (!validation.isValid) {
      return 'error';
    }

    if (!camera.enabled) {
      return 'offline';
    }

    // In a live RTSP gateway, an RTSP OPTIONS/DESCRIBE handshake is verified.
    // For healthy active cameras with valid RTSP endpoints:
    return 'online';
  }

  async createStreamingSession(
    camera: Camera,
    gatewayBaseUrl: string,
    streamProfile: StreamProfile = 'main'
  ): Promise<StreamSessionDescriptor> {
    const validation = this.validateConfiguration(camera);
    if (!validation.isValid) {
      throw new Error(`Invalid RTSP configuration: ${validation.errors.join(', ')}`);
    }

    const sessionId = `sess_rtsp_${camera.id}_${Date.now()}`;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 4 * 60 * 60 * 1000); // 4 hours

    return {
      sessionId,
      cameraId: camera.id,
      sourceType: 'rtsp',
      connectionStatus: 'online',
      streamProfile,
      playbackProtocol: 'webrtc',
      streamEndpoint: `${gatewayBaseUrl}/live/${camera.id}/${streamProfile}.whip`,
      aiNormalizedStreamUrl: `${gatewayBaseUrl}/internal/raw-feed/${camera.id}/h264`,
      isP2P: false,
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      metadata: {
        rawTransport: 'RTSP-over-TCP',
        profile: streamProfile,
        gatewayPipeline: `rtsp-demuxer-${camera.id}`,
      },
    };
  }
}
