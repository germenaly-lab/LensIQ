import { Request, Response } from 'express';
import { StreamingGatewayService } from '../services/streaming-gateway.service';
import { StreamProfile } from '../../types/camera';

export class StreamController {
  private gatewayService: StreamingGatewayService;

  constructor(gatewayService: StreamingGatewayService) {
    this.gatewayService = gatewayService;
  }

  /**
   * POST /streams/:cameraId/session
   * Initiates a live streaming session by resolving camera source type,
   * delegating to the appropriate source adapter (RTSP or Hikvision P2P),
   * and returning a sanitized stream session descriptor for WebRTC/HLS & AI Vision.
   */
  createSession = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const cameraId = String(req.params.cameraId);
      const { streamProfile } = req.body || {};

      const profile: StreamProfile = streamProfile === 'sub' ? 'sub' : 'main';

      const sessionDescriptor = await this.gatewayService.createSession(user, cameraId, profile);

      res.status(201).json({
        success: true,
        message: 'Streaming session initiated successfully.',
        data: sessionDescriptor,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      const statusCode = message.includes('Unauthorized') ? 403 : message.includes('not found') ? 404 : 400;
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  };
}
