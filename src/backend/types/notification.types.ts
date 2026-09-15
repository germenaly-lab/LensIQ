export type DevicePlatform = 'android' | 'ios' | 'web';

export interface DeviceToken {
  token: string;
  platform: DevicePlatform;
  userId: string;
  deviceModel?: string;
  registeredAt: string;
  lastSeenAt: string;
}

export interface NotificationPreferences {
  userId: string;
  criticalAlerts: boolean;
  warningAlerts: boolean;
  infoAlerts: boolean;
  cameraOffline: boolean;
  aiEvents: boolean;
  allowedBrandIds?: string[];
  allowedBranchIds?: string[];
}

export interface NotificationRecord {
  id: string;
  recipientId: string;
  incidentId: string;
  title: string;
  body: string;
  data: Record<string, string>;
  sentAt: string;
  deliveryStatus: 'sent' | 'delivered' | 'failed';
  readAt: string | null;
  createdAt: string;
}

export interface NotificationPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface IncidentContext {
  id: string;
  companyId?: string;
  brandId?: string;
  brandName?: string;
  branchId: string;
  branchName: string;
  cameraId: string;
  cameraName: string;
  ruleType: string;
  severity: 'critical' | 'warning' | 'info';
  title: string;
  description: string;
  timestamp: string;
}

export interface NotificationDispatchResult {
  incidentId: string;
  totalRecipients: number;
  targetedUserIds: string[];
  notifications: NotificationRecord[];
  timestamp: string;
}
