import { Camera, CameraSourceType, StreamProfile } from '../../types/camera';

/**
 * Descriptor provided to streaming consumers (Web / Flutter clients)
 * Does NOT contain sensitive credentials.
 */
export interface StreamDescriptor {
  cameraId: string;
  sourceType: CameraSourceType;
  streamProfile: StreamProfile;
  playbackProtocol: 'webrtc' | 'hls' | 'mse';
  streamEndpoint: string;
  isP2P: boolean;
  metadata: Record<string, unknown>;
}

/**
 * Internal payload passed to the Streaming Gateway
 * Contains resolved internal connection directives abstracted away from raw transport.
 */
export interface GatewayPipelinePayload {
  cameraId: string;
  sourceType: CameraSourceType;
  targetPipeline: string;
  connectionConfig: {
    transportType: 'direct_tcp' | 'cloud_p2p_relay' | 'onvif_gateway';
    endpointUri?: string;
    p2pParams?: {
      deviceId: string;
      serialNumber?: string | null;
      channel: number;
      protocol: 'hik_ezviz_cloud' | 'hik_isup5';
    };
    authenticatedHeaders?: Record<string, string>;
  };
}

/**
 * Base Abstract Class for all Video Sources
 * Decouples the application, gateway, and consumers from RTSP specifics.
 */
export abstract class VideoSource {
  public readonly id: string;
  public readonly name: string;
  public readonly sourceType: CameraSourceType;
  public readonly streamProfile: StreamProfile;
  public readonly enabled: boolean;
  public readonly credentialsReference?: string | null;

  constructor(camera: Camera) {
    this.id = camera.id;
    this.name = camera.name;
    this.sourceType = camera.source_type;
    this.streamProfile = camera.stream_profile;
    this.enabled = camera.enabled;
    this.credentialsReference = camera.credentials_reference;
  }

  /**
   * Validate that the camera source has all necessary configurations.
   */
  abstract validateConfiguration(): { isValid: boolean; errors: string[] };

  /**
   * Generates sanitized stream descriptor for frontends and mobile apps.
   */
  abstract getStreamDescriptor(gatewayBaseUrl: string): StreamDescriptor;

  /**
   * Generates pipeline directives for the streaming gateway.
   */
  abstract getGatewayPipelinePayload(secretToken?: string): GatewayPipelinePayload;
}
