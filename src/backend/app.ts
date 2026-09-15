import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { CameraService } from './services/camera.service';
import { StreamingGatewayService } from './services/streaming-gateway.service';
import { CameraController } from './controllers/camera.controller';
import { StreamController } from './controllers/stream.controller';
import { NotificationController } from './controllers/notification.controller';
import { NotificationService } from './services/notification.service';
import { createCameraRoutes } from './routes/camera.routes';
import { createStreamRoutes } from './routes/stream.routes';
import { createNotificationRoutes } from './routes/notification.routes';
import { createInternalRoutes } from './routes/internal.routes';
import { authMiddleware } from './middleware/auth.middleware';

export function createApp(
  customCameraService?: CameraService,
  customGatewayService?: StreamingGatewayService,
  customNotificationService?: NotificationService
): Express {
  const app = express();

  // 1. Security Headers (Helmet) with streaming/embedding allowance
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      crossOriginEmbedderPolicy: false,
    })
  );

  // 2. CORS & Parsing
  app.use(cors());
  app.use(express.json({ limit: '10mb' }));

  // 3. API Rate Limiting (DDoS & Brute-force protection)
  const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    limit: 500, // 500 requests per 15 minutes
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: {
      success: false,
      error: 'Too many requests, please try again later.',
    },
    skip: (req: Request) => req.path.startsWith('/api/v1/internal') || req.path === '/api/v1/health',
  });
  app.use('/api/', apiLimiter);

  // 4. Services & Controllers
  const cameraService = customCameraService || new CameraService();
  const gatewayService = customGatewayService || new StreamingGatewayService(cameraService);
  const notificationService = customNotificationService || new NotificationService();

  const cameraController = new CameraController(cameraService);
  const streamController = new StreamController(gatewayService);
  const notificationController = new NotificationController(notificationService);

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
  app.use('/api/v1/notifications', authMiddleware, createNotificationRoutes(notificationController));
  app.use('/api/v1/internal', createInternalRoutes());

  // 404 Handler
  app.use((req: Request, res: Response) => {
    res.status(404).json({
      success: false,
      error: `Endpoint '${req.method} ${req.originalUrl}' not found.`,
    });
  });

  // Global Error Handler (Never expose stack traces or DB internals)
  app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
    console.error(`[API Security Error] [${req.method} ${req.originalUrl}]:`, err.message);
    res.status(500).json({
      success: false,
      error: 'An internal server error occurred. Please contact security operations.',
    });
  });

  return app;
}
