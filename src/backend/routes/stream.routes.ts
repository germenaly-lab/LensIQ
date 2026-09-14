import { Router } from 'express';
import { StreamController } from '../controllers/stream.controller';

export function createStreamRoutes(controller: StreamController): Router {
  const router = Router();

  // Playback token verification (Placed first to avoid route shadowing by :cameraId)
  router.get('/playback/:token', controller.verifyPlayback);

  // Unified stream session creation or attachment (re-uses existing pipeline if active)
  router.post('/:cameraId/session', controller.createSession);

  // Trigger explicit reconnection cycle
  router.post('/:cameraId/reconnect', controller.reconnect);

  // Release viewer session (initiates idle reaper if 0 viewers remain)
  router.post('/:cameraId/stop', controller.stopSession);

  // Live telemetry and health metrics
  router.get('/:cameraId/status', controller.getStatus);

  return router;
}
