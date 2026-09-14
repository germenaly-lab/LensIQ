import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { CameraService } from './services/camera.service';
import { StreamingGatewayService } from './services/streaming-gateway.service';
import { CameraController } from './controllers/camera.controller';
import { StreamController } from './controllers/stream.controller';
import { createCameraRoutes } from './routes/camera.routes';
import { createStreamRoutes } from './routes/stream.routes';
import { createInternalRoutes } from './routes/internal.routes';
import { authMiddleware } from './middleware/auth.middleware';

export function createApp(
  customCameraService?: CameraService,
  customGatewayService?: StreamingGatewayService
): Express {
  const app = express();

  // Middleware
  app.use(cors());
  app.use(express.json());

  // Services & Controllers
  const cameraService = customCameraService || new CameraService();
  const gatewayService = customGatewayService || new StreamingGatewayService(cameraService);

  const cameraController = new CameraController(cameraService);
  const streamController = new StreamController(gatewayService);

  // Health check
  app.get('/api/v1/health', (req: Request, res: Response) => {
    res.status(200).json({
      status: 'healthy',
      service: 'LensIQ Multi-Source CCTV Backend',
      version: '1.0.0',
      supportedSources: ['rtsp', 'hikvision_p2p'],
      timestamp: new Date().toISOString(),
    });
  });

  // Protected Routes
  app.use('/api/v1/cameras', authMiddleware, createCameraRoutes(cameraController));
  app.use('/api/v1/streams', authMiddleware, createStreamRoutes(streamController));
  app.use('/api/v1/internal', createInternalRoutes());

  // 404 Handler
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      error: `Endpoint '${req.method} ${req.originalUrl}' not found.`,
    });
  });

  // Global Error Handler
  app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error('[Backend Error]:', err.message);
    res.status(500).json({
      success: false,
      error: 'Internal Server Error',
    });
  });

  return app;
}
