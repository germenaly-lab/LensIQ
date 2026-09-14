import { Camera, CameraSourceType, StreamProfile } from '../../../types/camera';
import { ConnectionStatus, StreamSessionDescriptor } from '../../types/backend.types';
import { ICameraSourceService, ValidationResult } from './camera-source.interface';

/**
 * HikvisionP2PSourceService
 * Controlled adapter interface for Hik-Connect Cloud P2P protocol.
 * Clearly distinguishes between configured, connecting, online, offline, unsupported, and error.
 * Does NOT claim real P2P connectivity without an official mounted C++/Go SDK binding.
 */
export class HikvisionP2PSourceService implements ICameraSourceService {
  public readonly sourceType: CameraSourceType = 'hikvision_p2p';
  private hasNativeSdkBinding: boolean = false;

  constructor(hasNativeSdkBinding: boolean = false) {
    this.hasNativeSdkBinding = hasNativeSdkBinding;
  }

  validateConfiguration(camera: Camera): ValidationResult {
    const errors: string[] = [];

    if (!camera.hik_device_id || camera.hik_device_id.trim().length === 0) {
      errors.push('Hikvision Device Identifier (hik_device_id) is required.');
    }

    if (camera.hik_channel === undefined || camera.hik_channel === null) {
      errors.push('Hikvision Channel number is required.');
    } else if (camera.hik_channel < 1 || camera.hik_channel > 128) {
      errors.push('Hikvision Channel must be between 1 and 128.');
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

    // Without native SDK or cloud relay credentials mounted:
    if (!this.hasNativeSdkBinding && !camera.credentials_reference) {
      return 'unsupported';
    }

    // Device configured and credentials present in vault, ready for gateway relay
    return 'configured';
  }

  async createStreamingSession(
    camera: Camera,
    gatewayBaseUrl: string,
    streamProfile: StreamProfile = 'main'
  ): Promise<StreamSessionDescriptor> {
    const validation = this.validateConfiguration(camera);
    if (!validation.isValid) {
      throw new Error(`Invalid Hikvision P2P configuration: ${validation.errors.join(', ')}`);
    }

    const sessionId = `sess_hik_${camera.id}_${Date.now()}`;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 4 * 60 * 60 * 1000);

    const status = await this.checkConnectionStatus(camera);

    return {
      sessionId,
      cameraId: camera.id,
      sourceType: 'hikvision_p2p',
      connectionStatus: status === 'error' ? 'error' : 'configured',
      streamProfile,
      playbackProtocol: 'webrtc',
      streamEndpoint: `${gatewayBaseUrl}/live/p2p/${camera.hik_device_id}/ch${camera.hik_channel}.whip`,
      aiNormalizedStreamUrl: `${gatewayBaseUrl}/internal/raw-feed/${camera.id}/h264`,
      isP2P: true,
      createdAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      metadata: {
        rawTransport: 'Hik-Connect-Cloud-P2P',
        deviceId: camera.hik_device_id,
        serialNumber: camera.hik_serial_number || null,
        channel: camera.hik_channel,
        nativeSdkLoaded: this.hasNativeSdkBinding,
        profile: streamProfile,
      },
    };
  }
}
