import { describe, it, expect, beforeEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { NotificationService } from '../src/backend/services/notification.service';
import { IncidentContext } from '../src/backend/types/notification.types';

describe('Phase 9 — Complete Notification System Test Suite', () => {
  let notificationService: NotificationService;
  let app: any;

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const egoBrandId = '22222222-2222-2222-2222-222222222222'; // Ego Fashion
  const armaniBrandId = '22222222-2222-2222-2222-222222222223'; // Armani Exchange
  const moaBranchId = '33333333-3333-3333-3333-333333333333'; // Mall of Arabia
  const cfcBranchId = '33333333-3333-3333-3333-333333333334'; // Cairo Festival City

  beforeEach(() => {
    notificationService = new NotificationService();
    notificationService.clearHistory();
    app = createApp(undefined, undefined, notificationService);
  });

  // --------------------------------------------------------------------------
  // 1. Device Token Registration (Android, iOS, Web)
  // --------------------------------------------------------------------------
  it('1. Registers and updates FCM device tokens across Android, iOS, and Web', async () => {
    // Android registration
    const resAndroid = await request(app)
      .post('/api/v1/notifications/tokens')
      .set('x-user-id', 'demo-branch-sec-01')
      .send({
        token: 'fcm_token_samsung_galaxy_tab',
        platform: 'android',
        deviceModel: 'Samsung Galaxy Tab Active 4 Pro',
      });
    expect(resAndroid.status).toBe(200);
    expect(resAndroid.body.success).toBe(true);
    expect(resAndroid.body.data.platform).toBe('android');

    // iOS registration
    const resIos = await request(app)
      .post('/api/v1/notifications/tokens')
      .set('x-user-id', 'demo-brand-manager-01')
      .send({
        token: 'fcm_token_iphone_15',
        platform: 'ios',
        deviceModel: 'iPhone 15 Pro',
      });
    expect(resIos.status).toBe(200);
    expect(resIos.body.data.platform).toBe('ios');

    // Web registration
    const resWeb = await request(app)
      .post('/api/v1/notifications/tokens')
      .set('x-user-id', 'demo-super-admin-01')
      .send({
        token: 'fcm_token_chrome_desktop',
        platform: 'web',
      });
    expect(resWeb.status).toBe(200);
    expect(resWeb.body.data.platform).toBe('web');

    // Verify tokens stored
    const secTokens = notificationService.getUserTokens('demo-branch-sec-01');
    expect(secTokens.some((t) => t.token === 'fcm_token_samsung_galaxy_tab')).toBe(true);
  });

  // --------------------------------------------------------------------------
  // 2. Role-Based Targeting: Branch Security (Assigned Branch Only)
  // --------------------------------------------------------------------------
  it('2. Branch Security strictly receives alerts for assigned branch and never for other branches', async () => {
    // Incident at Mall of Arabia
    const moaIncident: IncidentContext = {
      id: 'inc_moa_cashier_01',
      brandId: egoBrandId,
      brandName: 'Ego Fashion',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: 'cam_moa_01',
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Cashier Area Empty',
      description: 'Cashier counter unattended for 3 minutes.',
      timestamp: new Date().toISOString(),
    };

    const result = await notificationService.dispatchIncidentNotification(moaIncident);

    // Targeted users: Super Admin, Brand Manager (Ego), Branch Sec (MoA)
    expect(result.targetedUserIds).toContain('demo-super-admin-01');
    expect(result.targetedUserIds).toContain('demo-brand-manager-01');
    expect(result.targetedUserIds).toContain('demo-branch-sec-01'); // MoA Security

    // MUST NOT be targeted to Branch Sec of CFC!
    expect(result.targetedUserIds).not.toContain('demo-branch-sec-02');
  });

  // --------------------------------------------------------------------------
  // 3. Role-Based Targeting: Brand Manager (Assigned Brand Only)
  // --------------------------------------------------------------------------
  it('3. Brand Manager strictly receives alerts for assigned brand and never for other brands', async () => {
    // Incident at Armani Exchange (Brand Manager is assigned to Ego Fashion)
    const armaniIncident: IncidentContext = {
      id: 'inc_armani_cs_01',
      brandId: armaniBrandId,
      brandName: 'Armani Exchange',
      branchId: '33333333-3333-3333-3333-333333333335',
      branchName: 'City Stars Mall',
      cameraId: 'cam_armani_01',
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Cashier Area Empty',
      description: 'Cashier area empty for 3 minutes.',
      timestamp: new Date().toISOString(),
    };

    const result = await notificationService.dispatchIncidentNotification(armaniIncident);

    // Super admin receives global alerts
    expect(result.targetedUserIds).toContain('demo-super-admin-01');

    // Ego Brand Manager MUST NOT receive Armani alerts
    expect(result.targetedUserIds).not.toContain('demo-brand-manager-01');
    // MoA Security MUST NOT receive City Stars alerts
    expect(result.targetedUserIds).not.toContain('demo-branch-sec-01');
  });

  // --------------------------------------------------------------------------
  // 4. Notification Preferences Filtering
  // --------------------------------------------------------------------------
  it('4. Respects user notification preferences (e.g. disable warnings, keep critical)', async () => {
    // Turn off warning alerts for Super Admin
    await request(app)
      .put('/api/v1/notifications/preferences')
      .set('x-user-id', 'demo-super-admin-01')
      .send({
        warningAlerts: false,
        criticalAlerts: true,
      });

    // 1. Dispatch Warning incident
    const warningIncident: IncidentContext = {
      id: 'inc_warning_01',
      brandId: egoBrandId,
      brandName: 'Ego Fashion',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: 'cam_moa_02',
      cameraName: 'Fitting Room',
      ruleType: 'loitering',
      severity: 'warning',
      title: 'Loitering Detected',
      description: 'Suspicious loitering in fitting room corridor.',
      timestamp: new Date().toISOString(),
    };

    const warningResult = await notificationService.dispatchIncidentNotification(warningIncident);
    // Super admin turned off warnings -> must NOT receive warning alert
    expect(warningResult.targetedUserIds).not.toContain('demo-super-admin-01');
    // Branch Security who kept warnings enabled DOES receive it
    expect(warningResult.targetedUserIds).toContain('demo-branch-sec-01');

    // 2. Dispatch Critical incident
    const criticalIncident: IncidentContext = {
      ...warningIncident,
      id: 'inc_critical_02',
      severity: 'critical',
      title: 'Cashier Area Empty',
    };

    const criticalResult = await notificationService.dispatchIncidentNotification(criticalIncident);
    // Super admin kept critical enabled -> DOES receive critical alert
    expect(criticalResult.targetedUserIds).toContain('demo-super-admin-01');
  });

  // --------------------------------------------------------------------------
  // 5. Notification Content & Deep-Link Route Validation
  // --------------------------------------------------------------------------
  it('5. Enterprise notification payload contains structured summary and incident deep-link route', async () => {
    const incident: IncidentContext = {
      id: 'inc_deep_link_test_123',
      brandId: armaniBrandId,
      brandName: 'Armani',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: 'cam_cashier_01',
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Cashier Area Empty',
      description: 'Cashier area has been empty for 3 minutes.',
      timestamp: new Date().toISOString(),
    };

    const result = await notificationService.dispatchIncidentNotification(incident);
    const adminNotif = result.notifications.find((n) => n.recipientId === 'demo-super-admin-01');

    expect(adminNotif).toBeDefined();
    expect(adminNotif!.title).toBe('CRITICAL: Cashier Area Empty');
    expect(adminNotif!.body).toContain('Armani • Mall of Arabia • Cashier 01');
    expect(adminNotif!.body).toContain('Cashier area has been empty for 3 minutes.');
    expect(adminNotif!.data.route).toBe('/incidents?id=inc_deep_link_test_123');
    expect(adminNotif!.data.incidentId).toBe('inc_deep_link_test_123');
  });

  // --------------------------------------------------------------------------
  // 6. Notification History Tracking & Unread Count
  // --------------------------------------------------------------------------
  it('6. Accurately tracks unread counts and updates read status per user', async () => {
    const incident: IncidentContext = {
      id: 'inc_history_01',
      brandId: egoBrandId,
      brandName: 'Ego Fashion',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: 'cam_01',
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Cashier Area Empty',
      description: 'Cashier empty 3 minutes.',
      timestamp: new Date().toISOString(),
    };

    await notificationService.dispatchIncidentNotification(incident);

    // Fetch notifications for Branch Security
    const getRes = await request(app)
      .get('/api/v1/notifications')
      .set('x-user-id', 'demo-branch-sec-01');

    expect(getRes.status).toBe(200);
    expect(getRes.body.data.unreadCount).toBe(1);
    expect(getRes.body.data.notifications.length).toBe(1);

    const notifId = getRes.body.data.notifications[0].id;

    // Mark single notification as read
    const readRes = await request(app)
      .patch(`/api/v1/notifications/${notifId}/read`)
      .set('x-user-id', 'demo-branch-sec-01');
    expect(readRes.status).toBe(200);

    // Fetch again -> unread count should be 0
    const afterReadRes = await request(app)
      .get('/api/v1/notifications')
      .set('x-user-id', 'demo-branch-sec-01');
    expect(afterReadRes.body.data.unreadCount).toBe(0);
    expect(afterReadRes.body.data.notifications[0].readAt).not.toBeNull();
  });

  // --------------------------------------------------------------------------
  // 7. Mark All As Read API
  // --------------------------------------------------------------------------
  it('7. Mark all as read clears unread badges for all pending notifications', async () => {
    // Generate two incidents
    for (let i = 1; i <= 2; i++) {
      await notificationService.dispatchIncidentNotification({
        id: `inc_multi_${i}`,
        brandId: egoBrandId,
        brandName: 'Ego Fashion',
        branchId: moaBranchId,
        branchName: 'Mall of Arabia',
        cameraId: 'cam_01',
        cameraName: `Cashier 0${i}`,
        ruleType: 'cashier_empty',
        severity: 'critical',
        title: `Cashier Alert ${i}`,
        description: 'Unattended alert',
        timestamp: new Date().toISOString(),
      });
    }

    const before = notificationService.getUserNotifications('demo-branch-sec-01');
    expect(before.unreadCount).toBe(2);

    const markAllRes = await request(app)
      .post('/api/v1/notifications/read-all')
      .set('x-user-id', 'demo-branch-sec-01');

    expect(markAllRes.status).toBe(200);
    expect(markAllRes.body.data.updatedCount).toBe(2);

    const after = notificationService.getUserNotifications('demo-branch-sec-01');
    expect(after.unreadCount).toBe(0);
  });

  // --------------------------------------------------------------------------
  // 8. Cross-Tenant Security Isolation
  // --------------------------------------------------------------------------
  it('8. User cannot mark another user notification as read', async () => {
    await notificationService.dispatchIncidentNotification({
      id: 'inc_sec_isolate',
      brandId: egoBrandId,
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: 'cam_01',
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Alert',
      description: 'Alert',
      timestamp: new Date().toISOString(),
    });

    const secNotifs = notificationService.getUserNotifications('demo-branch-sec-01');
    const secNotifId = secNotifs.notifications[0].id;

    // Different user attempts to mark it as read
    const hackRes = await request(app)
      .patch(`/api/v1/notifications/${secNotifId}/read`)
      .set('x-user-id', 'unauthorized-user-999');

    expect(hackRes.status).toBe(404);
  });
});
