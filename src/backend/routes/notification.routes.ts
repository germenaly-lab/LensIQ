import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller';

export function createNotificationRoutes(controller: NotificationController): Router {
  const router = Router();

  // Device token registration (FCM)
  router.post('/tokens', controller.registerToken);

  // User notification preferences
  router.get('/preferences', controller.getPreferences);
  router.put('/preferences', controller.updatePreferences);

  // User notifications & read status
  router.get('/', controller.getNotifications);
  router.patch('/:id/read', controller.markRead);
  router.post('/read-all', controller.markAllRead);

  // Dispatch trigger (AI pipeline or simulation)
  router.post('/dispatch', controller.dispatchNotification);

  return router;
}
