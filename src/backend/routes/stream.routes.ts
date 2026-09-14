import { Router } from 'express';
import { StreamController } from '../controllers/stream.controller';

export function createStreamRoutes(controller: StreamController): Router {
  const router = Router();

  // POST /streams/:cameraId/session
  router.post('/:cameraId/session', controller.createSession);

  return router;
}
