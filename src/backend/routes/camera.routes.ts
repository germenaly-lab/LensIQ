import { Router } from 'express';
import { CameraController } from '../controllers/camera.controller';

export function createCameraRoutes(controller: CameraController): Router {
  const router = Router();

  router.get('/', controller.listCameras);
  router.get('/:id', controller.getCamera);
  router.post('/', controller.createCamera);
  router.delete('/:id', controller.deleteCamera);

  return router;
}
