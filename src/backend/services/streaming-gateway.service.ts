import { CameraService } from './camera.service';
import { SourceServiceFactory } from './camera-source/source-service.factory';
import { StreamSessionDescriptor, AuthenticatedUser } from '../types/backend.types';
import { StreamProfile } from '../../types/camera';

export class StreamingGatewayService {
  private cameraService: CameraService;
  private gatewayBaseUrl: string;

  constructor(cameraService: CameraService, gatewayBaseUrl: string = 'https://stream.lensiq.cloud') {
    this.cameraService = cameraService;
    this.gatewayBaseUrl = gatewayBaseUrl;
  }

  /**
   * Orchestrates the creation of a streaming session.
   * Conceptually:
   * camera ➔ source_type ➔ RTSPSourceService OR HikvisionP2PSourceService ➔ Streaming Gateway ➔ WebRTC/HLS
   */
  async createSession(
    user: AuthenticatedUser,
    cameraId: string,
    streamProfile: StreamProfile = 'main'
  ): Promise<StreamSessionDescriptor> {
    // 1. Fetch raw internal camera (verifies tenant authorization)
    const camera = await this.cameraService.getRawCamera(user, cameraId);

    // 2. Delegate to appropriate source adapter based on camera.source_type
    const sourceAdapter = SourceServiceFactory.getService(camera.source_type);

    // 3. Initiate pipeline session via adapter
    return sourceAdapter.createStreamingSession(camera, this.gatewayBaseUrl, streamProfile);
  }
}
