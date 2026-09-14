import { Request, Response } from 'express';
import { StreamingGatewayService } from '../services/streaming-gateway.service';
import { StreamProfile } from '../../types/camera';
import { StreamProtocol } from '../streaming/types/streaming.types';

export class StreamController {
  private gatewayService: StreamingGatewayService;

  constructor(gatewayService: StreamingGatewayService) {
    this.gatewayService = gatewayService;
  }

  /**
   * POST /streams/:cameraId/session
   * Initiates or attaches to a live streaming session by resolving camera source type,
   * delegating to the appropriate source adapter (RTSP or Hikvision P2P),
   * and returning a sanitized stream session descriptor for WebRTC/HLS & AI Vision.
   */
  createSession = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const cameraId = String(req.params.cameraId);
      const { streamProfile, protocol, demoMode } = req.body || {};

      const profile: StreamProfile = streamProfile === 'sub' ? 'sub' : 'main';
      const streamProtocol: StreamProtocol = protocol === 'hls' ? 'hls' : 'webrtc';

      const sessionDescriptor = await this.gatewayService.createSession(user, cameraId, {
        streamProfile: profile,
        protocol: streamProtocol,
        demoMode: demoMode !== undefined ? Boolean(demoMode) : undefined,
      });

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

  /**
   * POST /streams/:cameraId/reconnect
   * Explicitly triggers reconnection on camera source adapter
   */
  reconnect = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const cameraId = String(req.params.cameraId);

      const stats = await this.gatewayService.reconnectCamera(user, cameraId);
      res.status(200).json({
        success: true,
        message: 'Camera reconnection executed successfully.',
        data: stats,
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

  /**
   * POST /streams/:cameraId/stop
   * Leaves or stops a viewer session, triggering idle teardown when 0 viewers remain
   */
  stopSession = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const cameraId = String(req.params.cameraId);
      const { sessionId } = req.body || {};

      if (!sessionId) {
        return res.status(400).json({
          success: false,
          error: 'sessionId is required in request body.',
        });
      }

      const result = await this.gatewayService.stopSession(user, cameraId, String(sessionId));
      res.status(200).json({
        success: true,
        message: 'Stream session released successfully.',
        data: result,
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

  /**
   * GET /streams/:cameraId/status
   * Real-time monitoring metrics: latency, reconnect count, uptime, viewer count
   */
  getStatus = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const cameraId = String(req.params.cameraId);

      const stats = await this.gatewayService.getStreamStatus(user, cameraId);
      res.status(200).json({
        success: true,
        data: stats,
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

  /**
   * GET /streams/playback/:token
   * Validates ephemeral session token for media player playback
   */
  verifyPlayback = async (req: Request, res: Response) => {
    const token = String(req.params.token || req.query.token || '');
    const verification = this.gatewayService.verifyPlaybackToken(token);

    if (!verification.valid || !verification.session) {
      return res.status(401).json({
        success: false,
        error: verification.error || 'Invalid or expired stream playback token.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Playback token verified.',
      data: verification.session,
    });
  };
}
