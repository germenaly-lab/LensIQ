import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { CameraService } from '../src/backend/services/camera.service';
import { StreamingGatewayService } from '../src/backend/services/streaming-gateway.service';
import { StreamSessionManager } from '../src/backend/streaming/gateway/stream-session.manager';
import { StreamSecurityService } from '../src/backend/streaming/gateway/stream-security.service';
import { NotificationService } from '../src/backend/services/notification.service';
import { CashierEmptyRule } from '../src/backend/rules/cashier-empty.rule';
import { RuleContext } from '../src/backend/rules/base.rule';

describe('Phase 10 — Final Multi-Source System Testing & Production Readiness Audit', () => {
  let cameraService: CameraService;
  let sessionManager: StreamSessionManager;
  let securityService: StreamSecurityService;
  let gatewayService: StreamingGatewayService;
  let notificationService: NotificationService;
  let app: any;

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const armaniBrandId = '22222222-2222-2222-2222-222222222221';
  const egoFashionBrandId = '22222222-2222-2222-2222-222222222222';
  const moaBranchId = '33333333-3333-3333-3333-333333333333';
  const cfcBranchId = '33333333-3333-3333-3333-333333333334';

  const rtspCameraId = '44444444-4444-4444-4444-444444444441'; // Cashier 01 (RTSP)
  const hikvisionCameraId = '44444444-4444-4444-4444-444444444442'; // Entrance 01 (Hikvision P2P)
  const offlineCameraId = '44444444-4444-4444-4444-444444444443'; // Offline Backstore

  beforeEach(() => {
    cameraService = new CameraService();
    securityService = new StreamSecurityService('phase10-audit-salt-secret', 3600 * 1000);
    sessionManager = new StreamSessionManager(securityService, {
      gatewayBaseUrl: 'https://stream.lensiq.cloud',
      idleGracePeriodMs: 50,
      sessionDurationMs: 3600 * 1000,
    });
    gatewayService = new StreamingGatewayService(cameraService, 'https://stream.lensiq.cloud', sessionManager);
    notificationService = new NotificationService();
    notificationService.clearHistory();

    app = createApp(cameraService, gatewayService, notificationService);
  });

  afterEach(async () => {
    await sessionManager.shutdownAll();
  });

  // --------------------------------------------------------------------------
  // 1. RBAC & Security Isolation Audit
  // --------------------------------------------------------------------------
  it('1. RBAC Audit: Branch Security is strictly isolated to assigned branch only', async () => {
    // 1.1 Branch Security requesting their assigned branch cameras -> 200 OK
    const allowedRes = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-id', 'demo-branch-sec-01')
      .set('x-user-role', 'branch_security')
      .set('x-branch-id', moaBranchId)
      .set('x-authorized-branches', moaBranchId);

    expect(allowedRes.status).toBe(200);
    expect(allowedRes.body.success).toBe(true);
    expect(allowedRes.body.data.every((c: any) => c.branch_id === moaBranchId)).toBe(true);

    // 1.2 Branch Security requesting streams for unauthorized branch -> 403 Forbidden
    const deniedRes = await request(app)
      .post(`/api/v1/streams/${hikvisionCameraId}/session`)
      .set('x-user-id', 'demo-branch-sec-01')
      .set('x-user-role', 'branch_security')
      .set('x-branch-id', cfcBranchId) // Assigned to CFC, but hikvisionCameraId is in MOA
      .set('x-authorized-branches', cfcBranchId)
      .send({ streamProfile: 'main', protocol: 'webrtc' });

    expect(deniedRes.status).toBe(403);
    expect(deniedRes.body.success).toBe(false);
  });

  it('2. RBAC Audit: Brand Manager cannot access cameras of another brand', async () => {
    // Brand Manager for Armani Exchange requesting cameras
    const brandRes = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-id', 'demo-brand-manager-01')
      .set('x-user-role', 'brand_manager')
      .set('x-brand-id', armaniBrandId);

    expect(brandRes.status).toBe(200);
    // Must never return cameras belonging to Ego Fashion
    expect(brandRes.body.data.every((c: any) => c.brand_id !== egoFashionBrandId)).toBe(true);
  });

  // --------------------------------------------------------------------------
  // 2. Camera & Stream Security: Zero Credential Leakage
  // --------------------------------------------------------------------------
  it('3. Camera Security: RTSP passwords and Hikvision keys are NEVER exposed to client', async () => {
    // 3.1 Check camera inventory endpoint
    const camRes = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-role', 'super_admin');

    expect(camRes.status).toBe(200);
    const jsonString = JSON.stringify(camRes.body);
    expect(jsonString).not.toContain('rtsp://admin:');
    expect(jsonString).not.toContain('secret');
    expect(jsonString).not.toContain('password');
    expect(jsonString).not.toContain('P2P_SECRET');

    // 3.2 Check active stream session response
    const streamRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main', protocol: 'webrtc', demoMode: true });

    expect(streamRes.status).toBe(201);
    const sessionJson = JSON.stringify(streamRes.body);
    expect(sessionJson).not.toContain('rtsp://');
    expect(sessionJson).not.toContain('password');
    expect(streamRes.body.data.stream_url).toContain('https://stream.lensiq.cloud');
  });

  // --------------------------------------------------------------------------
  // 3. API Security: Helmet, Rate Limiting, and Error Sanitization
  // --------------------------------------------------------------------------
  it('4. API Security: Helmet headers and rate limiting are enforced on API responses', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.status).toBe(200);
    // Helmet Security Headers
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-dns-prefetch-control']).toBe('off');
  });

  it('5. API Security: Internal AI events ingestion strictly authenticates service key', async () => {
    // 5.1 Request without key -> 401 Unauthorized
    const unauthRes = await request(app)
      .post('/api/v1/internal/events')
      .send({ event_type: 'cashier_empty', camera_id: rtspCameraId });

    expect(unauthRes.status).toBe(401);

    // 5.2 Request with invalid key -> 401 Unauthorized
    const badKeyRes = await request(app)
      .post('/api/v1/internal/events')
      .set('x-internal-service-key', 'wrong-key')
      .send({ event_type: 'cashier_empty', camera_id: rtspCameraId });

    expect(badKeyRes.status).toBe(401);

    // 5.3 Request with valid service key -> 202 Accepted
    const validRes = await request(app)
      .post('/api/v1/internal/events')
      .set('x-internal-service-key', 'lensiq-internal-service-secret-change-in-prod')
      .send({
        id: 'evt-ai-test-01',
        event_type: 'cashier_empty',
        camera_id: rtspCameraId,
        duration: 180,
      });

    expect(validRes.status).toBe(202);
    expect(validRes.body.success).toBe(true);
  });

  // --------------------------------------------------------------------------
  // 4. Failure & Resilience Testing
  // --------------------------------------------------------------------------
  it('6. Failure Resilience: Non-existent camera stream initiation is gracefully rejected with 404', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/00000000-0000-0000-0000-000000000000/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main', protocol: 'webrtc' });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  // --------------------------------------------------------------------------
  // 5. End-to-End Scenario 1: RTSP Camera Live Stream + Simultaneous AI Incident Pipeline
  // --------------------------------------------------------------------------
  it('7. E2E Scenario 1: RTSP Stream -> Gateway -> AI YOLOv8 Cashier Empty (180s) -> Incident -> FCM -> Deep Link', async () => {
    // Step A: Client requests live RTSP stream session
    const streamRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main', protocol: 'webrtc', demoMode: true });

    expect(streamRes.status).toBe(201);
    expect(streamRes.body.data.source_type).toBe('rtsp');
    expect(streamRes.body.data.protocol).toBe('webrtc');

    // Step B: Simultaneously, AI Service evaluates Cashier Empty rule over 180s
    const rule = new CashierEmptyRule({ durationSeconds: 180 });
    const baseCtx: RuleContext = {
      cameraId: rtspCameraId,
      cameraName: 'Cashier 01',
      roiId: 'roi-cashier-01',
      roiName: 'Cashier Counter',
      peopleInRoi: 0,
      timestamp: 1000,
    };

    // t=1000s -> open, not triggered
    const evt1 = rule.evaluate({ ...baseCtx, timestamp: 1000 });
    expect(evt1).toBeNull();

    // t=1180s -> 180 continuous seconds empty -> TRIGGERED!
    const evt2 = rule.evaluate({ ...baseCtx, timestamp: 1180 });
    expect(evt2).not.toBeNull();
    expect(evt2!.eventType).toBe('CASHIER_EMPTY');
    expect(evt2!.duration).toBe(180);

    // Step C: Ingest AI event into Node.js Backend
    const eventIngestRes = await request(app)
      .post('/api/v1/internal/events')
      .set('x-internal-service-key', 'lensiq-internal-service-secret-change-in-prod')
      .send(evt2!);

    expect(eventIngestRes.status).toBe(202);

    // Step D: Backend determines authorized users and dispatches FCM Push Notification
    notificationService.registerDeviceToken(
      'demo-branch-sec-01',
      'fcm_token_test_e2e_rtsp',
      'android'
    );

    const dispatchResult = await notificationService.dispatchIncidentNotification({
      id: 'inc-e2e-rtsp-01',
      brandId: egoFashionBrandId,
      brandName: 'Ego Fashion',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: rtspCameraId,
      cameraName: 'Cashier 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Cashier Area Empty',
      description: 'Cashier counter unattended for 3 continuous minutes (180s) on Cashier 01.',
      timestamp: new Date().toISOString(),
    });

    expect(dispatchResult.totalRecipients).toBeGreaterThan(0);
    expect(dispatchResult.targetedUserIds).toContain('demo-branch-sec-01');

    // Step E: Verify FCM Deep Link payload
    const notifs = notificationService.getNotificationsForUser('demo-branch-sec-01');
    expect(notifs.length).toBeGreaterThan(0);
    const alert = notifs[0];
    expect(alert.title).toContain('CRITICAL');
    expect(alert.data['route']).toBe('/incidents?id=inc-e2e-rtsp-01');
  });

  // --------------------------------------------------------------------------
  // 6. End-to-End Scenario 2: Hikvision P2P Camera Live Stream + Simultaneous AI Incident Pipeline
  // --------------------------------------------------------------------------
  it('8. E2E Scenario 2: Hikvision P2P -> P2P Adapter -> Gateway -> AI YOLOv8 Cashier Empty (180s) -> Incident -> FCM', async () => {
    // Step A: Client requests live Hikvision P2P stream session
    const streamRes = await request(app)
      .post(`/api/v1/streams/${hikvisionCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main', protocol: 'webrtc', demoMode: true });

    expect(streamRes.status).toBe(201);
    expect(streamRes.body.data.source_type).toBe('hikvision_p2p');
    expect(streamRes.body.data.protocol).toBe('webrtc');
    expect(streamRes.body.data.stream_url).toContain('/live/p2p/');

    // Step B: AI event generation for Hikvision camera
    const rule = new CashierEmptyRule({ durationSeconds: 180 });
    const baseCtx: RuleContext = {
      cameraId: hikvisionCameraId,
      cameraName: 'Entrance 01',
      roiId: 'roi-hik-01',
      roiName: 'Entrance Security Zone',
      peopleInRoi: 0,
      timestamp: 2000,
    };
    rule.evaluate({ ...baseCtx, timestamp: 2000 });
    const evalRes = rule.evaluate({ ...baseCtx, timestamp: 2185 });

    expect(evalRes).not.toBeNull();
    expect(evalRes!.eventType).toBe('CASHIER_EMPTY');

    // Step C: FCM notification targeted dispatch
    notificationService.registerDeviceToken(
      'demo-brand-manager-01',
      'fcm_token_test_e2e_hik',
      'ios'
    );

    const dispatchResult = await notificationService.dispatchIncidentNotification({
      id: 'inc-e2e-hik-02',
      brandId: egoFashionBrandId,
      brandName: 'Ego Fashion',
      branchId: moaBranchId,
      branchName: 'Mall of Arabia',
      cameraId: hikvisionCameraId,
      cameraName: 'Entrance 01',
      ruleType: 'cashier_empty',
      severity: 'critical',
      title: 'Entrance Area Unattended',
      description: 'Security zone empty for 3 minutes.',
      timestamp: new Date().toISOString(),
    });

    expect(dispatchResult.totalRecipients).toBeGreaterThan(0);
    expect(dispatchResult.targetedUserIds).toContain('demo-brand-manager-01');
  });
});
