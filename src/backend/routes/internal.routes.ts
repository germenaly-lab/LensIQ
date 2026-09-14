import { Router, Request, Response } from 'express';

export function createInternalRoutes(): Router {
  const router = Router();

  /**
   * POST /api/v1/internal/events
   * Ingests structured AI events from the Python AI microservice.
   */
  router.post('/events', (req: Request, res: Response) => {
    const authKey = req.headers['x-internal-service-key'];
    const expectedKey = process.env.INTERNAL_API_SECRET || 'lensiq-internal-service-secret-change-in-prod';

    if (authKey !== expectedKey) {
      return res.status(401).json({ error: 'Unauthorized: Invalid internal service key.' });
    }

    const event = req.body;
    // Log receipt of event without logging sensitive data
    console.log(`[Backend AI Ingestion] Received event '${event.event_type}' for camera '${event.camera_id}' (duration: ${event.duration}s)`);

    res.status(202).json({
      success: true,
      message: 'Event accepted by backend event bus.',
      eventId: event.id,
    });
  });

  return router;
}
