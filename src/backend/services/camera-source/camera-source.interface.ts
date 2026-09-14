import { Camera, CameraSourceType, StreamProfile } from '../../../types/camera';
import { ConnectionStatus, StreamSessionDescriptor } from '../../types/backend.types';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

/**
 * CameraSourceService Interface
 * Decouples backend logic from transport specifics (RTSP vs Hikvision P2P).
 */
export interface ICameraSourceService {
  readonly sourceType: CameraSourceType;

  /**
   * Validate configuration specific to this source type.
   */
  validateConfiguration(camera: Camera): ValidationResult;

  /**
   * Assess connection status.
   * Returns: 'configured' | 'connecting' | 'online' | 'offline' | 'unsupported' | 'error'
   */
  checkConnectionStatus(camera: Camera): Promise<ConnectionStatus>;

  /**
   * Initialize a new streaming session through the streaming gateway.
   * Produces a normalized stream descriptor for clients and AI vision service.
   */
  createStreamingSession(
    camera: Camera,
    gatewayBaseUrl: string,
    streamProfile?: StreamProfile
  ): Promise<StreamSessionDescriptor>;
}
