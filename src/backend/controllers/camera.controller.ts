import { Request, Response } from 'express';
import { CameraService } from '../services/camera.service';
import { CameraSourceType } from '../../types/camera';

export class CameraController {
  private cameraService: CameraService;

  constructor(cameraService: CameraService) {
    this.cameraService = cameraService;
  }

  listCameras = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const { companyId, branchId, sourceType } = req.query;

      const cameras = await this.cameraService.listCameras(user, {
        companyId: companyId as string,
        branchId: branchId as string,
        sourceType: sourceType as CameraSourceType,
      });

      res.status(200).json({
        success: true,
        count: cameras.length,
        data: cameras,
      });
    } catch (err: unknown) {
      res.status(400).json({
        success: false,
        error: err instanceof Error ? err.message : String(err),
      });
    }
  };

  getCamera = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const id = String(req.params.id);

      const camera = await this.cameraService.getCameraById(user, id);
      res.status(200).json({
        success: true,
        data: camera,
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

  createCamera = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const body = req.body;

      if (!body.name || !body.company_id || !body.branch_id || !body.source_type) {
        return res.status(400).json({
          success: false,
          error: 'Missing required fields: name, company_id, branch_id, source_type are mandatory.',
        });
      }

      if (body.source_type !== 'rtsp' && body.source_type !== 'hikvision_p2p') {
        return res.status(400).json({
          success: false,
          error: `Invalid source_type '${body.source_type}'. Supported: 'rtsp', 'hikvision_p2p'.`,
        });
      }

      const camera = await this.cameraService.createCamera(user, body);

      res.status(201).json({
        success: true,
        message: 'Camera created successfully with zero credential exposure.',
        data: camera,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      const statusCode = message.includes('Unauthorized') ? 403 : 400;
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  };

  deleteCamera = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const id = String(req.params.id);

      await this.cameraService.deleteCamera(user, id);
      res.status(200).json({
        success: true,
        message: `Camera '${id}' deleted successfully.`,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      const statusCode = message.includes('Unauthorized') ? 403 : 404;
      res.status(statusCode).json({
        success: false,
        error: message,
      });
    }
  };
}
