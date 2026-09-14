import { VideoSource, StreamDescriptor, GatewayPipelinePayload } from './video-source.interface';
import { Camera } from '../../types/camera';

export class RTSPSource extends VideoSource {
  public readonly rtspUrl: string;

  constructor(camera: Camera) {
    super(camera);
    if (camera.source_type !== 'rtsp') {
      throw new Error(`Invalid source_type '${camera.source_type}' for RTSPSource`);
    }
    this.rtspUrl = camera.rtsp_url || '';
  }

  validateConfiguration(): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    if (!this.rtspUrl) {
      errors.push('RTSP URL is required for RTSP video source');
    } else if (!this.rtspUrl.startsWith('rtsp://') && !this.rtspUrl.startsWith('rtsps://')) {
      errors.push('RTSP URL must begin with rtsp:// or rtsps://');
    }
    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  getStreamDescriptor(gatewayBaseUrl: string): StreamDescriptor {
    return {
      cameraId: this.id,
      sourceType: 'rtsp',
      streamProfile: this.streamProfile,
      playbackProtocol: 'webrtc',
      streamEndpoint: `${gatewayBaseUrl}/api/v1/streams/${this.id}/${this.streamProfile}/live.whip`,
      isP2P: false,
      metadata: {
        rawTransport: 'RTSP-over-TCP',
        profile: this.streamProfile,
      },
    };
  }

  getGatewayPipelinePayload(secretToken?: string): GatewayPipelinePayload {
    const validation = this.validateConfiguration();
    if (!validation.isValid) {
      throw new Error(`Cannot create gateway payload: ${validation.errors.join(', ')}`);
    }

    return {
      cameraId: this.id,
      sourceType: 'rtsp',
      targetPipeline: `pipeline-rtsp-demuxer-${this.id}`,
      connectionConfig: {
        transportType: 'direct_tcp',
        endpointUri: this.rtspUrl,
        authenticatedHeaders: secretToken ? { Authorization: `Bearer ${secretToken}` } : undefined,
      },
    };
  }
}
