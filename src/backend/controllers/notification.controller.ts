import { Request, Response } from 'express';
import { NotificationService } from '../services/notification.service';
import { DevicePlatform, IncidentContext } from '../types/notification.types';

export class NotificationController {
  private notificationService: NotificationService;

  constructor(notificationService: NotificationService) {
    this.notificationService = notificationService;
  }

  /**
   * POST /notifications/tokens
   * Registers or updates device push notification token (FCM)
   */
  registerToken = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const { token, platform, deviceModel } = req.body || {};

      if (!token || typeof token !== 'string') {
        return res.status(400).json({
          success: false,
          error: 'token is required and must be a string.',
        });
      }

      const validPlatforms: DevicePlatform[] = ['android', 'ios', 'web'];
      const devicePlatform: DevicePlatform = validPlatforms.includes(platform) ? platform : 'web';

      const tokenRecord = this.notificationService.registerDeviceToken(
        user.id,
        token,
        devicePlatform,
        deviceModel
      );

      res.status(200).json({
        success: true,
        message: 'Device notification token registered successfully.',
        data: tokenRecord,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * GET /notifications
   * Retrieves notification history and unread count for current user
   */
  getNotifications = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const result = this.notificationService.getUserNotifications(user.id);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * PATCH /notifications/:id/read
   * Marks a specific notification as read
   */
  markRead = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const notificationId = String(req.params.id);

      const success = this.notificationService.markAsRead(user.id, notificationId);
      if (!success) {
        return res.status(404).json({
          success: false,
          error: `Notification '${notificationId}' not found for user.`,
        });
      }

      res.status(200).json({
        success: true,
        message: 'Notification marked as read.',
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * POST /notifications/read-all
   * Marks all notifications as read for current user
   */
  markAllRead = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const updatedCount = this.notificationService.markAllAsRead(user.id);

      res.status(200).json({
        success: true,
        message: `${updatedCount} notifications marked as read.`,
        data: { updatedCount },
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * GET /notifications/preferences
   * Retrieves user notification preferences
   */
  getPreferences = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const prefs = this.notificationService.getPreferences(user.id);

      res.status(200).json({
        success: true,
        data: prefs,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * PUT /notifications/preferences
   * Updates user notification preferences
   */
  updatePreferences = async (req: Request, res: Response) => {
    try {
      const user = req.user!;
      const updates = req.body || {};

      const updated = this.notificationService.updatePreferences(user.id, updates);

      res.status(200).json({
        success: true,
        message: 'Notification preferences updated successfully.',
        data: updated,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };

  /**
   * POST /notifications/dispatch
   * Trigger incident notifications (used by AI service or demo simulators)
   */
  dispatchNotification = async (req: Request, res: Response) => {
    try {
      const incident: IncidentContext = req.body;

      if (!incident || !incident.id || !incident.branchId || !incident.title) {
        return res.status(400).json({
          success: false,
          error: 'Invalid incident payload. id, branchId, and title are required.',
        });
      }

      const result = await this.notificationService.dispatchIncidentNotification(incident);

      res.status(200).json({
        success: true,
        message: `Notification dispatched to ${result.totalRecipients} authorized recipients.`,
        data: result,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({ success: false, error: msg });
    }
  };
}
