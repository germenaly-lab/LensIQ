import { VideoSource, StreamDescriptor, GatewayPipelinePayload } from './video-source.interface';
import { Camera } from '../../types/camera';

export class HikvisionP2PSource extends VideoSource {
  public readonly deviceId: string;
  public readonly serialNumber?: string | null;
  public readonly channel: number;
  public readonly username?: string | null;

  constructor(camera: Camera) {
    super(camera);
    if (camera.source_type !== 'hikvision_p2p') {
      throw new Error(`Invalid source_type '${camera.source_type}' for HikvisionP2PSource`);
    }
    this.deviceId = camera.hik_device_id || '';
    this.serialNumber = camera.hik_serial_number;
    this.channel = camera.hik_channel ?? 1;
    this.username = camera.hik_username;
  }

  validateConfiguration(): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    if (!this.deviceId || this.deviceId.trim().length === 0) {
      errors.push('Hikvision Device ID is required');
    }
    if (this.channel < 1 || this.channel > 128) {
      errors.push('Channel must be a valid number between 1 and 128');
    }
    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  getStreamDescriptor(gatewayBaseUrl: string): StreamDescriptor {
    return {
      cameraId: this.id,
      sourceType: 'hikvision_p2p',
      streamProfile: this.streamProfile,
      playbackProtocol: 'webrtc',
      streamEndpoint: `${gatewayBaseUrl}/api/v1/streams/${this.id}/${this.streamProfile}/live.whip`,
      isP2P: true,
      metadata: {
        rawTransport: 'Hik-Connect-Cloud-P2P',
        deviceId: this.deviceId,
        channel: this.channel,
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
      sourceType: 'hikvision_p2p',
      targetPipeline: `pipeline-hik-connect-relay-${this.deviceId}-ch${this.channel}`,
      connectionConfig: {
        transportType: 'cloud_p2p_relay',
        p2pParams: {
          deviceId: this.deviceId,
          serialNumber: this.serialNumber,
          channel: this.channel,
          protocol: 'hik_ezviz_cloud',
        },
        authenticatedHeaders: secretToken ? { 'X-Hik-Cloud-Auth': secretToken } : undefined,
      },
    };
  }
}
