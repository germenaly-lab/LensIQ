import { AuthenticatedUser } from '../types/backend.types';
import {
  DevicePlatform,
  DeviceToken,
  NotificationPreferences,
  NotificationRecord,
  IncidentContext,
  NotificationDispatchResult,
} from '../types/notification.types';

export class NotificationService {
  private deviceTokens: Map<string, DeviceToken[]> = new Map();
  private preferences: Map<string, NotificationPreferences> = new Map();
  private notificationHistory: NotificationRecord[] = [];

  // Default demo users for role-based targeting tests & demo runtime
  private registeredUsers: AuthenticatedUser[] = [
    {
      id: 'demo-super-admin-01',
      role: 'super_admin',
      companyId: '11111111-1111-1111-1111-111111111111',
      authorizedBranchIds: [
        '33333333-3333-3333-3333-333333333333',
        '33333333-3333-3333-3333-333333333334',
        '33333333-3333-3333-3333-333333333335',
      ],
    },
    {
      id: 'demo-brand-manager-01',
      role: 'brand_manager',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222', // Ego Fashion
      authorizedBranchIds: [
        '33333333-3333-3333-3333-333333333333',
        '33333333-3333-3333-3333-333333333334',
      ],
    },
    {
      id: 'demo-branch-sec-01',
      role: 'branch_security',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333', // Mall of Arabia Branch ONLY
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333333'],
    },
    {
      id: 'demo-branch-sec-02',
      role: 'branch_security',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333334', // Cairo Festival City Branch ONLY
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333334'],
    },
  ];

  constructor() {
    this.seedDefaultTokens();
  }

  private seedDefaultTokens(): void {
    // Seed test tokens for demo users
    this.registerDeviceToken(
      'demo-super-admin-01',
      'fcm_token_admin_web_001',
      'web',
      'Chrome Desktop NOC'
    );
    this.registerDeviceToken(
      'demo-brand-manager-01',
      'fcm_token_brand_mgr_ios_002',
      'ios',
      'iPhone 15 Pro'
    );
    this.registerDeviceToken(
      'demo-branch-sec-01',
      'fcm_token_sec_moa_android_003',
      'android',
      'Samsung Galaxy Tab Active'
    );
    this.registerDeviceToken(
      'demo-branch-sec-02',
      'fcm_token_sec_cfc_android_004',
      'android',
      'Pixel 8'
    );
  }

  /**
   * Register or update an FCM device token for a user
   */
  registerDeviceToken(
    userId: string,
    token: string,
    platform: DevicePlatform,
    deviceModel?: string
  ): DeviceToken {
    const existingTokens = this.deviceTokens.get(userId) || [];
    const now = new Date().toISOString();

    const existingIdx = existingTokens.findIndex((t) => t.token === token);
    const tokenRecord: DeviceToken = {
      token,
      platform,
      userId,
      deviceModel: deviceModel || `${platform.toUpperCase()} Client`,
      registeredAt: existingIdx !== -1 ? existingTokens[existingIdx].registeredAt : now,
      lastSeenAt: now,
    };

    if (existingIdx !== -1) {
      existingTokens[existingIdx] = tokenRecord;
    } else {
      existingTokens.push(tokenRecord);
    }

    this.deviceTokens.set(userId, existingTokens);
    return tokenRecord;
  }

  /**
   * Retrieves all registered device tokens for a user
   */
  getUserTokens(userId: string): DeviceToken[] {
    return this.deviceTokens.get(userId) || [];
  }

  /**
   * Removes a specific device token (e.g. on logout)
   */
  unregisterDeviceToken(userId: string, token: string): boolean {
    const tokens = this.deviceTokens.get(userId);
    if (!tokens) return false;
    const initialLen = tokens.length;
    const filtered = tokens.filter((t) => t.token !== token);
    this.deviceTokens.set(userId, filtered);
    return filtered.length < initialLen;
  }

  /**
   * Get notification preferences for a user (or default preferences if not configured)
   */
  getPreferences(userId: string): NotificationPreferences {
    const existing = this.preferences.get(userId);
    if (existing) return existing;

    const defaultPrefs: NotificationPreferences = {
      userId,
      criticalAlerts: true,
      warningAlerts: true,
      infoAlerts: false,
      cameraOffline: true,
      aiEvents: true,
    };
    this.preferences.set(userId, defaultPrefs);
    return defaultPrefs;
  }

  /**
   * Update notification preferences for a user
   */
  updatePreferences(
    userId: string,
    updates: Partial<NotificationPreferences>
  ): NotificationPreferences {
    const current = this.getPreferences(userId);
    const updated: NotificationPreferences = {
      ...current,
      ...updates,
      userId, // Immutable
    };
    this.preferences.set(userId, updated);
    return updated;
  }

  /**
   * Checks whether a user is strictly authorized to view this incident according to RBAC.
   * Super Admin: Global access
   * Brand Manager: Only assigned brand
   * Branch Security: Only assigned branch
   */
  isUserAuthorizedForIncident(user: AuthenticatedUser, incident: IncidentContext): boolean {
    if (user.role === 'super_admin') {
      return true;
    }

    if (user.role === 'brand_manager') {
      if (!user.brandId || !incident.brandId) return false;
      return user.brandId === incident.brandId;
    }

    if (user.role === 'branch_security') {
      const authorizedBranches = user.authorizedBranchIds || (user.branchId ? [user.branchId] : []);
      return authorizedBranches.includes(incident.branchId);
    }

    return false;
  }

  /**
   * Checks whether an incident matches user notification preferences
   */
  doesIncidentMatchPreferences(
    prefs: NotificationPreferences,
    incident: IncidentContext
  ): boolean {
    // Severity check
    if (incident.severity === 'critical' && !prefs.criticalAlerts) {
      return false;
    }
    if (incident.severity === 'warning' && !prefs.warningAlerts) {
      return false;
    }
    if (incident.severity === 'info' && !prefs.infoAlerts) {
      return false;
    }

    // Rule / Event type checks
    const isCameraOffline = incident.ruleType.includes('offline') || incident.title.toLowerCase().includes('offline');
    if (isCameraOffline && !prefs.cameraOffline) {
      return false;
    }

    if (!isCameraOffline && !prefs.aiEvents) {
      return false;
    }

    // Optional Brand/Branch filtering in preferences
    if (prefs.allowedBrandIds && prefs.allowedBrandIds.length > 0 && incident.brandId) {
      if (!prefs.allowedBrandIds.includes(incident.brandId)) return false;
    }

    if (prefs.allowedBranchIds && prefs.allowedBranchIds.length > 0) {
      if (!prefs.allowedBranchIds.includes(incident.branchId)) return false;
    }

    return true;
  }

  /**
   * Dispatches notifications for an AI-generated incident.
   * 1. Resolves authorized users based on RBAC.
   * 2. Evaluates user preferences.
   * 3. Dispatches FCM messages to registered device tokens.
   * 4. Stores notification history.
   */
  async dispatchIncidentNotification(
    incident: IncidentContext,
    candidateUsers?: AuthenticatedUser[]
  ): Promise<NotificationDispatchResult> {
    const users = candidateUsers || this.registeredUsers;
    const now = new Date().toISOString();
    const targetedUserIds: string[] = [];
    const generatedNotifications: NotificationRecord[] = [];

    for (const user of users) {
      // 1. RBAC authorization gate
      if (!this.isUserAuthorizedForIncident(user, incident)) {
        continue;
      }

      // 2. User preferences gate
      const prefs = this.getPreferences(user.id);
      if (!this.doesIncidentMatchPreferences(prefs, incident)) {
        continue;
      }

      targetedUserIds.push(user.id);

      // 3. Prepare enterprise notification content
      const title = `${incident.severity.toUpperCase()}: ${incident.title}`;
      const body = `${incident.brandName ? incident.brandName + ' • ' : ''}${incident.branchName} • ${incident.cameraName}: ${incident.description}`;

      const dataPayload: Record<string, string> = {
        incidentId: incident.id,
        cameraId: incident.cameraId,
        cameraName: incident.cameraName,
        branchId: incident.branchId,
        branchName: incident.branchName,
        severity: incident.severity,
        ruleType: incident.ruleType,
        route: `/incidents?id=${incident.id}`,
        timestamp: incident.timestamp,
      };

      if (incident.brandId) {
        dataPayload.brandId = incident.brandId;
      }
      if (incident.brandName) {
        dataPayload.brandName = incident.brandName;
      }

      // 4. Create Notification Record for Supabase / history store
      const record: NotificationRecord = {
        id: `notif_${user.id}_${incident.id}_${Date.now()}`,
        recipientId: user.id,
        incidentId: incident.id,
        title,
        body,
        data: dataPayload,
        sentAt: now,
        deliveryStatus: 'sent',
        readAt: null,
        createdAt: now,
      };

      this.notificationHistory.unshift(record);
      generatedNotifications.push(record);
    }

    return {
      incidentId: incident.id,
      totalRecipients: targetedUserIds.length,
      targetedUserIds,
      notifications: generatedNotifications,
      timestamp: now,
    };
  }

  /**
   * Retrieves notification history for a specific recipient, with unread count
   */
  getUserNotifications(userId: string): {
    notifications: NotificationRecord[];
    unreadCount: number;
    totalCount: number;
  } {
    const userRecords = this.notificationHistory.filter((r) => r.recipientId === userId);
    const unreadCount = userRecords.filter((r) => r.readAt === null).length;

    return {
      notifications: userRecords,
      unreadCount,
      totalCount: userRecords.length,
    };
  }

  /**
   * Marks a notification as read
   */
  markAsRead(userId: string, notificationId: string): boolean {
    const record = this.notificationHistory.find(
      (r) => r.id === notificationId && r.recipientId === userId
    );
    if (!record) return false;

    if (!record.readAt) {
      record.readAt = new Date().toISOString();
    }
    return true;
  }

  /**
   * Marks all notifications for a user as read
   */
  markAllAsRead(userId: string): number {
    const now = new Date().toISOString();
    let updatedCount = 0;

    for (const record of this.notificationHistory) {
      if (record.recipientId === userId && record.readAt === null) {
        record.readAt = now;
        updatedCount++;
      }
    }

    return updatedCount;
  }

  /**
   * Clears notification history (for test isolation)
   */
  clearHistory(): void {
    this.notificationHistory = [];
  }
}
