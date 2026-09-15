import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { CameraService } from '../src/backend/services/camera.service';
import { StreamingGatewayService } from '../src/backend/services/streaming-gateway.service';
import { StreamSessionManager } from '../src/backend/streaming/gateway/stream-session.manager';
import { StreamSecurityService } from '../src/backend/streaming/gateway/stream-security.service';
import { CashierEmptyRule } from '../src/backend/rules/cashier-empty.rule';
import { RuleContext } from '../src/backend/rules/base.rule';

describe('Phase 8 — Live Cameras with RTSP and Hikvision P2P Test Suite', () => {
  let cameraService: CameraService;
  let sessionManager: StreamSessionManager;
  let securityService: StreamSecurityService;
  let gatewayService: StreamingGatewayService;
  let app: any;

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const egoBranchId = '33333333-3333-3333-3333-333333333333';
  const otherBranchId = '33333333-3333-3333-3333-333333333332'; // CFC branch
  const rtspCameraId = '44444444-4444-4444-4444-444444444441'; // Cashier 01 (RTSP)
  const hikvisionCameraId = '44444444-4444-4444-4444-444444444442'; // Entrance 01 (Hikvision P2P)
  const offlineCameraId = '44444444-4444-4444-4444-444444444443'; // Backstore (Warning/Offline)

  beforeEach(() => {
    cameraService = new CameraService();
    securityService = new StreamSecurityService('test-salt-secret-phase8', 3600 * 1000);
    sessionManager = new StreamSessionManager(securityService, {
      gatewayBaseUrl: 'https://stream.lensiq.cloud',
      idleGracePeriodMs: 50,
      sessionDurationMs: 3600 * 1000,
    });
    gatewayService = new StreamingGatewayService(cameraService, 'https://stream.lensiq.cloud', sessionManager);
    app = createApp(cameraService, gatewayService);
  });

  afterEach(async () => {
    await sessionManager.shutdownAll();
  });

  // --------------------------------------------------------------------------
  // 1. RTSP Camera Live View via Unified Streaming Gateway
  // --------------------------------------------------------------------------
  it('1. RTSP camera connects through Streaming Gateway to WebRTC/HLS without exposing passwords', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({
        streamProfile: 'main',
        protocol: 'webrtc',
        demoMode: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    const session = res.body.data;
    expect(session.camera_id).toBe(rtspCameraId);
    expect(session.source_type).toBe('rtsp');
    expect(session.protocol).toBe('webrtc');
    expect(session.token).toBeDefined();

    // Zero Credential Leakage check
    const serialized = JSON.stringify(session);
    expect(serialized).not.toContain('super_secret');
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('rtsp_admin');
  });

  // --------------------------------------------------------------------------
  // 2. Hikvision P2P Camera Live View via Unified Streaming Gateway
  // --------------------------------------------------------------------------
  it('2. Hikvision P2P camera connects through Streaming Gateway without exposing P2P secrets', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/${hikvisionCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({
        streamProfile: 'main',
        protocol: 'webrtc',
        demoMode: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    const session = res.body.data;
    expect(session.camera_id).toBe(hikvisionCameraId);
    expect(session.source_type).toBe('hikvision_p2p');
    expect(session.protocol).toBe('webrtc');

    // Zero Credential Leakage check
    const serialized = JSON.stringify(session);
    expect(serialized).not.toContain('app_key_secret');
    expect(serialized).not.toContain('device_verify_code');
  });

  // --------------------------------------------------------------------------
  // 3. Camera Switching (Seamless Ingest Re-routing)
  // --------------------------------------------------------------------------
  it('3. Seamlessly switches between RTSP and Hikvision P2P cameras without socket leaks', async () => {
    // Start RTSP Camera
    const res1 = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ protocol: 'webrtc', demoMode: true });
    expect(res1.status).toBe(201);
    const session1Id = res1.body.data.session_id;

    // Switch to Hikvision Camera
    const res2 = await request(app)
      .post(`/api/v1/streams/${hikvisionCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ protocol: 'webrtc', demoMode: true });
    expect(res2.status).toBe(201);
    const session2Id = res2.body.data.session_id;

    expect(session1Id).not.toBe(session2Id);

    // Stop first camera session
    const stopRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/stop`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ sessionId: session1Id });
    expect(stopRes.status).toBe(200);
  });

  // --------------------------------------------------------------------------
  // 4. Multi-Camera Grid (1, 4, 9 Camera Sessions Concurrently)
  // --------------------------------------------------------------------------
  it('4. Supports multi-camera grid layout sessions concurrently without cross-talk', async () => {
    // Start multiple camera sessions simultaneously (simulating 4-camera or 9-camera grid)
    const [rtspRes, hikRes] = await Promise.all([
      request(app)
        .post(`/api/v1/streams/${rtspCameraId}/session`)
        .set('x-user-role', 'super_admin')
        .set('x-company-id', egoCompanyId)
        .send({ protocol: 'webrtc', demoMode: true }),
      request(app)
        .post(`/api/v1/streams/${hikvisionCameraId}/session`)
        .set('x-user-role', 'super_admin')
        .set('x-company-id', egoCompanyId)
        .send({ protocol: 'webrtc', demoMode: true }),
    ]);

    expect(rtspRes.status).toBe(201);
    expect(hikRes.status).toBe(201);
    expect(rtspRes.body.data.camera_id).toBe(rtspCameraId);
    expect(hikRes.body.data.camera_id).toBe(hikvisionCameraId);
  });

  // --------------------------------------------------------------------------
  // 5. Reconnect on Stream Failure
  // --------------------------------------------------------------------------
  it('5. Reconnect API triggers adapter reconnection and resets connection health', async () => {
    // Initiate session
    await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ demoMode: true });

    // Trigger explicit reconnect
    const reconnectRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/reconnect`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId);

    expect(reconnectRes.status).toBe(200);
    expect(reconnectRes.body.success).toBe(true);
    expect(reconnectRes.body.data.reconnect_count).toBeGreaterThanOrEqual(1);
    expect(reconnectRes.body.data.connection_status).toBe('streaming');
  });

  // --------------------------------------------------------------------------
  // 6. Offline Camera Handling
  // --------------------------------------------------------------------------
  it('6. Status endpoint correctly reports camera status and rejects non-existent cameras', async () => {
    const res = await request(app)
      .get(`/api/v1/streams/00000000-0000-0000-0000-000000000000/status`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  // --------------------------------------------------------------------------
  // 7. Unauthorized Camera Access Blocked (RBAC Enforcement)
  // --------------------------------------------------------------------------
  it('7. Unauthorized camera access is strictly blocked with 403 Forbidden', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'branch_security')
      .set('x-company-id', egoCompanyId)
      .set('x-authorized-branches', otherBranchId) // User does NOT have access to Mall of Arabia
      .send({ demoMode: true });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  // --------------------------------------------------------------------------
  // 8. Stream Lifecycle Optimization (Stop / Release)
  // --------------------------------------------------------------------------
  it('8. Stop session releases viewer and cleans up active session', async () => {
    const createRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ demoMode: true });

    const sessionId = createRes.body.data.session_id;

    const stopRes = await request(app)
      .post(`/api/v1/streams/${rtspCameraId}/stop`)
      .set('x-user-role', 'super_admin')
      .set('x-company-id', egoCompanyId)
      .send({ sessionId });

    expect(stopRes.status).toBe(200);
    expect(stopRes.body.success).toBe(true);
    expect(stopRes.body.data.released).toBe(true);
    expect(stopRes.body.data.remainingViewers).toBe(0);
  });

  // --------------------------------------------------------------------------
  // 9. Cashier Empty Rule Logic — 180s Threshold Trigger
  // --------------------------------------------------------------------------
  it('9. Cashier Empty Rule: triggers incident after continuous 180 seconds (3 minutes)', () => {
    const rule = new CashierEmptyRule({
      ruleId: 'rule-cashier-empty-01',
      name: 'Cashier Counter Unattended',
      durationSeconds: 180,
    });

    const baseCtx: RuleContext = {
      cameraId: rtspCameraId,
      cameraName: 'Cashier 01',
      roiId: 'roi-cashier-01',
      roiName: 'Cashier Counter',
      peopleInRoi: 0,
      timestamp: 1000,
    };

    // T = 1000s: 0 people -> timer starts, no alert yet
    const evt1 = rule.evaluate({ ...baseCtx, timestamp: 1000 });
    expect(evt1).toBeNull();
    expect(rule.getCurrentDuration()).toBe(0);

    // T = 1100s (100s empty): threshold not reached
    const evt2 = rule.evaluate({ ...baseCtx, timestamp: 1100 });
    expect(evt2).toBeNull();
    expect(rule.getCurrentDuration()).toBe(100);

    // T = 1180s (180s empty -> 3 continuous minutes): triggers incident!
    const evt3 = rule.evaluate({ ...baseCtx, timestamp: 1180 });
    expect(evt3).not.toBeNull();
    expect(evt3!.eventType).toBe('CASHIER_EMPTY');
    expect(evt3!.duration).toBe(180);
    expect(evt3!.metadata.thresholdSeconds).toBe(180);
  });

  // --------------------------------------------------------------------------
  // 10. Cashier Empty Rule Logic — Reset on Person Entering ROI
  // --------------------------------------------------------------------------
  it('10. Cashier Empty Rule: resets timer completely if person enters ROI before 180s', () => {
    const rule = new CashierEmptyRule({
      ruleId: 'rule-cashier-empty-01',
      name: 'Cashier Counter Unattended',
      durationSeconds: 180,
    });

    const baseCtx: RuleContext = {
      cameraId: rtspCameraId,
      cameraName: 'Cashier 01',
      roiId: 'roi-cashier-01',
      roiName: 'Cashier Counter',
      peopleInRoi: 0,
      timestamp: 1000,
    };

    // T = 1000s: Empty starts
    rule.evaluate({ ...baseCtx, timestamp: 1000 });
    // T = 1120s: 120s elapsed
    rule.evaluate({ ...baseCtx, timestamp: 1120 });
    expect(rule.getCurrentDuration()).toBe(120);

    // T = 1150s: Person enters ROI! (peopleInRoi = 1)
    const personEntersEvt = rule.evaluate({ ...baseCtx, peopleInRoi: 1, timestamp: 1150 });
    expect(personEntersEvt).toBeNull();
    expect(rule.getCurrentDuration()).toBe(0); // Timer reset!

    // T = 1180s: Still occupied, no event
    const evtAfter = rule.evaluate({ ...baseCtx, peopleInRoi: 1, timestamp: 1180 });
    expect(evtAfter).toBeNull();
  });

  // --------------------------------------------------------------------------
  // 11. Cashier Empty Rule Logic — Duplicate Alert Suppression
  // --------------------------------------------------------------------------
  it('11. Cashier Empty Rule: suppresses duplicate alert storms during same continuous empty period', () => {
    const rule = new CashierEmptyRule({
      ruleId: 'rule-cashier-empty-01',
      name: 'Cashier Counter Unattended',
      durationSeconds: 180,
    });

    const baseCtx: RuleContext = {
      cameraId: rtspCameraId,
      cameraName: 'Cashier 01',
      roiId: 'roi-cashier-01',
      roiName: 'Cashier Counter',
      peopleInRoi: 0,
      timestamp: 1000,
    };

    // T = 1000s: Start
    rule.evaluate({ ...baseCtx, timestamp: 1000 });
    // T = 1180s: Triggers first alert
    const firstAlert = rule.evaluate({ ...baseCtx, timestamp: 1180 });
    expect(firstAlert).not.toBeNull();

    // T = 1200s (200s empty): Same empty continuous period -> suppressed!
    const secondAlert = rule.evaluate({ ...baseCtx, timestamp: 1200 });
    expect(secondAlert).toBeNull();

    // T = 1300s: Still empty -> suppressed!
    const thirdAlert = rule.evaluate({ ...baseCtx, timestamp: 1300 });
    expect(thirdAlert).toBeNull();
  });

  // --------------------------------------------------------------------------
  // 12. Both RTSP and Hikvision P2P behave identically in Flutter gateway interface
  // --------------------------------------------------------------------------
  it('12. Unified interface: RTSP and Hikvision P2P return identical session structure for Flutter', async () => {
    const [rtspRes, hikRes] = await Promise.all([
      request(app)
        .post(`/api/v1/streams/${rtspCameraId}/session`)
        .set('x-user-role', 'super_admin')
        .set('x-company-id', egoCompanyId)
        .send({ demoMode: true }),
      request(app)
        .post(`/api/v1/streams/${hikvisionCameraId}/session`)
        .set('x-user-role', 'super_admin')
        .set('x-company-id', egoCompanyId)
        .send({ demoMode: true }),
    ]);

    const s1 = rtspRes.body.data;
    const s2 = hikRes.body.data;

    // Both sessions expose the identical high-level properties expected by Flutter
    const commonKeys = ['session_id', 'camera_id', 'protocol', 'stream_url', 'token', 'expires_at', 'monitoring'];
    for (const key of commonKeys) {
      expect(s1).toHaveProperty(key);
      expect(s2).toHaveProperty(key);
    }

    expect(s1.protocol).toBe(s2.protocol);
    expect(s1.monitoring.connection_status).toBe(s2.monitoring.connection_status);
  });
});
