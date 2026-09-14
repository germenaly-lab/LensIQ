import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { CameraService } from '../src/backend/services/camera.service';
import { StreamingGatewayService } from '../src/backend/services/streaming-gateway.service';
import { StreamSessionManager } from '../src/backend/streaming/gateway/stream-session.manager';
import { StreamSecurityService } from '../src/backend/streaming/gateway/stream-security.service';
import { RTSPSourceAdapter } from '../src/backend/streaming/adapters/rtsp-source.adapter';
import { HikvisionP2PSourceAdapter } from '../src/backend/streaming/adapters/hikvision-p2p-source.adapter';
import { Camera } from '../src/types/camera';

describe('Phase 4 — Multi-Source Streaming Gateway Test Suite', () => {
  let cameraService: CameraService;
  let sessionManager: StreamSessionManager;
  let securityService: StreamSecurityService;
  let gatewayService: StreamingGatewayService;
  let app: any;

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const egoBranchId = '33333333-3333-3333-3333-333333333333';
  const cashierCameraId = '44444444-4444-4444-4444-444444444441'; // RTSP
  const entranceCameraId = '44444444-4444-4444-4444-444444444442'; // Hikvision P2P

  beforeEach(() => {
    cameraService = new CameraService();
    securityService = new StreamSecurityService('test-secret-salt-gateway', 3600 * 1000);
    sessionManager = new StreamSessionManager(securityService, {
      gatewayBaseUrl: 'https://stream.lensiq.cloud',
      idleGracePeriodMs: 50, // Short timeout for rapid testing of resource cleanup
      sessionDurationMs: 3600 * 1000,
    });
    gatewayService = new StreamingGatewayService(cameraService, 'https://stream.lensiq.cloud', sessionManager);
    app = createApp(cameraService, gatewayService);
  });

  afterEach(async () => {
    await sessionManager.shutdownAll();
  });

  // --------------------------------------------------------------------------
  // TEST A: Demo RTSP -> Gateway -> WebRTC/HLS -> Flutter
  // --------------------------------------------------------------------------
  it('Test A: Demo RTSP camera connects, streams WebRTC/HLS, and provides safe playback for Flutter', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'branch_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-authorized-branches', egoBranchId)
      .send({
        streamProfile: 'main',
        protocol: 'webrtc',
        demoMode: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    const session = res.body.data;
    expect(session.camera_id).toBe(cashierCameraId);
    expect(session.source_type).toBe('rtsp');
    expect(session.protocol).toBe('webrtc');
    expect(session.token).toBeDefined();
    expect(session.stream_url).toContain('/api/v1/streams/playback/');
    expect(session.stream_url).toContain(`token=${session.token}`);
    expect(session.demo_mode).toBe(true);
    expect(session.viewer_count).toBe(1);

    // Monitoring stats
    expect(session.monitoring).toBeDefined();
    expect(session.monitoring.connection_status).toBe('streaming');
    expect(session.monitoring.latency_ms).toBeGreaterThan(0);
    expect(session.monitoring.last_successful_frame).toBeDefined();

    // Verify Flutter media player playback via token
    const playbackRes = await request(app).get(`/api/v1/streams/playback/${session.token}`);
    expect(playbackRes.status).toBe(200);
    expect(playbackRes.body.success).toBe(true);
    expect(playbackRes.body.data.session_id).toBe(session.session_id);

    // CRITICAL: Ensure zero RTSP credential leakage
    const stringified = JSON.stringify(session);
    expect(stringified).not.toContain('super_secret');
    expect(stringified).not.toContain('rtsp_admin');
    expect(stringified).not.toContain('vault-rtsp-cashier01-demo');
  });

  // --------------------------------------------------------------------------
  // TEST B: Demo Hikvision P2P Source -> Gateway -> WebRTC/HLS -> Flutter
  // --------------------------------------------------------------------------
  it('Test B: Demo Hikvision P2P camera connects, streams WebRTC/HLS, and isolates credentials', async () => {
    const res = await request(app)
      .post(`/api/v1/streams/${entranceCameraId}/session`)
      .set('x-user-role', 'branch_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-authorized-branches', egoBranchId)
      .send({
        streamProfile: 'sub',
        protocol: 'hls',
        demoMode: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);

    const session = res.body.data;
    expect(session.camera_id).toBe(entranceCameraId);
    expect(session.source_type).toBe('hikvision_p2p');
    expect(session.demo_mode).toBe(true);
    expect(session.token).toBeDefined();
    expect(session.viewer_count).toBe(1);

    // Safe unified playback URL for Flutter
    expect(session.stream_url).toContain('/api/v1/streams/live/p2p/');
    expect(session.stream_url).toContain(`token=${session.token}`);

    // Stream info validation
    expect(session.stream_info.profile).toBe('sub');
    expect(session.stream_info.codec).toBe('h264');

    // Verify Flutter media player playback
    const playbackRes = await request(app).get(`/api/v1/streams/playback/${session.token}`);
    expect(playbackRes.status).toBe(200);
    expect(playbackRes.body.success).toBe(true);
    expect(playbackRes.body.data.source_type).toBe('hikvision_p2p');

    // CRITICAL: Ensure zero Hikvision key or password leakage
    const stringified = JSON.stringify(session);
    expect(stringified).not.toContain('HIKVISION_APP_SECRET');
    expect(stringified).not.toContain('vault-hik-mainentrance-demo');
  });

  // --------------------------------------------------------------------------
  // TEST: Reconnect Flow & Telemetry Tracking
  // --------------------------------------------------------------------------
  it('handles explicit and automatic reconnect cycles, incrementing telemetry counters', async () => {
    // 1. Initiate session
    const sessionRes = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main' });
    expect(sessionRes.status).toBe(201);

    // 2. Trigger reconnect
    const reconnectRes = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/reconnect`)
      .set('x-user-role', 'super_admin');

    expect(reconnectRes.status).toBe(200);
    expect(reconnectRes.body.success).toBe(true);
    expect(reconnectRes.body.data.reconnect_count).toBeGreaterThanOrEqual(1);
    expect(reconnectRes.body.data.connection_status).toBe('streaming');

    // 3. Query status endpoint
    const statusRes = await request(app)
      .get(`/api/v1/streams/${cashierCameraId}/status`)
      .set('x-user-role', 'super_admin');

    expect(statusRes.status).toBe(200);
    expect(statusRes.body.data.reconnect_count).toBeGreaterThanOrEqual(1);
  });

  // --------------------------------------------------------------------------
  // TEST: Camera Offline State Handling
  // --------------------------------------------------------------------------
  it('handles offline camera state gracefully and reports descriptive error without crashing', async () => {
    // Register an offline camera
    const offlineCamRes = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Offline Rooftop Camera',
        company_id: egoCompanyId,
        brand_id: '22222222-2222-2222-2222-222222222222',
        branch_id: egoBranchId,
        source_type: 'rtsp',
        rtsp_url: 'rtsp://10.0.0.99/live',
        stream_profile: 'main',
      });
    const offlineCamId = offlineCamRes.body.data.id;

    // Manually mark it offline in raw storage for testing
    const rawCam = (cameraService as any).cameras.get(offlineCamId);
    rawCam.status = 'offline';

    const res = await request(app)
      .post(`/api/v1/streams/${offlineCamId}/session`)
      .set('x-user-role', 'super_admin')
      .send();

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('marked offline');
  });

  // --------------------------------------------------------------------------
  // TEST: Invalid Credentials / Configuration & Non-Simulated Real P2P
  // --------------------------------------------------------------------------
  it('rejects invalid source configurations and strictly refuses to fake real Hikvision P2P without credentials', async () => {
    // 1. Invalid channel (< 1)
    const invalidAdapter = new HikvisionP2PSourceAdapter({
      camera: {
        id: 'bad-cam-1',
        company_id: egoCompanyId,
        brand_id: 'brand-1',
        branch_id: egoBranchId,
        name: 'Bad Channel Camera',
        source_type: 'hikvision_p2p',
        enabled: true,
        status: 'online',
        hik_device_id: 'HIK-REAL-99',
        hik_channel: 0, // INVALID CHANNEL
        stream_profile: 'main',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      isDemo: false,
    });

    await expect(invalidAdapter.connect()).rejects.toThrow('channel must be a positive integer');

    // 2. Real mode with missing official credentials: MUST NOT fake a connection!
    const realMissingCredsAdapter = new HikvisionP2PSourceAdapter({
      camera: {
        id: 'real-hardware-cam',
        company_id: egoCompanyId,
        brand_id: 'brand-1',
        branch_id: egoBranchId,
        name: 'Real Branch NVR',
        source_type: 'hikvision_p2p',
        enabled: true,
        status: 'online',
        hik_device_id: 'DS-7716NI-I4-REAL',
        hik_serial_number: 'REAL998177218',
        hik_channel: 1,
        stream_profile: 'main',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      isDemo: false, // NOT DEMO
    });

    // Strictly throws 'unsupported' explaining missing Hik-Connect / HCNetSDK credentials
    await expect(realMissingCredsAdapter.connect()).rejects.toThrow(
      /Hik-Connect Open Platform credentials/
    );
  });

  // --------------------------------------------------------------------------
  // TEST: Unauthorized User & Tenant Isolation
  // --------------------------------------------------------------------------
  it('blocks unauthorized users across tenant and branch boundaries with 403', async () => {
    const acmeCompanyId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    const acmeBranchId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

    // Acme branch manager attempts to stream Ego Cashier camera
    const res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'branch_manager')
      .set('x-company-id', acmeCompanyId)
      .set('x-authorized-branches', acmeBranchId)
      .send();

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  // --------------------------------------------------------------------------
  // TEST: Stream Session Expiration
  // --------------------------------------------------------------------------
  it('rejects expired stream playback tokens', async () => {
    // Generate a token that expired 10 seconds ago
    const expiredTokenResult = securityService.generateSessionToken(
      'sess-expired-123',
      { id: cashierCameraId, company_id: egoCompanyId, branch_id: egoBranchId } as Camera,
      'webrtc',
      -10000 // Negative duration -> expired
    );

    const check = securityService.verifySessionToken(expiredTokenResult.token);
    expect(check.valid).toBe(false);
    expect(check.error).toContain('expired');

    // Calling the API endpoint with this token returns 401
    const playbackRes = await request(app).get(
      `/api/v1/streams/playback/${expiredTokenResult.token}`
    );
    expect(playbackRes.status).toBe(401);
    expect(playbackRes.body.success).toBe(false);
    expect(playbackRes.body.error).toContain('expired');
  });

  // --------------------------------------------------------------------------
  // TEST: Multiple Viewers Multiplexing & Single Ingest Pipeline (Process Lifecycle)
  // --------------------------------------------------------------------------
  it('deduplicates ingest pipelines: multiple viewers share 1 underlying camera stream without duplicate processes', async () => {
    // 1. Viewer 1 requests stream on Cashier Camera
    const viewer1Res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-id', 'viewer-user-01')
      .set('x-user-role', 'super_admin')
      .send();

    expect(viewer1Res.status).toBe(201);
    const session1 = viewer1Res.body.data;
    expect(session1.viewer_count).toBe(1);

    // Exactly 1 underlying ingest pipeline active
    expect(sessionManager.activePipelineCount).toBe(1);

    // 2. Viewer 2 requests stream on the SAME Cashier Camera
    const viewer2Res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-id', 'viewer-user-02')
      .set('x-user-role', 'super_admin')
      .send();

    expect(viewer2Res.status).toBe(201);
    const session2 = viewer2Res.body.data;
    expect(session2.viewer_count).toBe(2);

    // CRITICAL PERFORMANCE CHECK: Still only 1 pipeline! Zero duplicate FFmpeg processes spawned.
    expect(sessionManager.activePipelineCount).toBe(1);
    expect(session1.session_id).not.toBe(session2.session_id); // Unique viewer session tokens

    // 3. Viewer 1 leaves stream
    const stopRes1 = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/stop`)
      .set('x-user-role', 'super_admin')
      .send({ sessionId: session1.session_id });

    expect(stopRes1.status).toBe(200);
    expect(stopRes1.body.data.remainingViewers).toBe(1);
    expect(sessionManager.activePipelineCount).toBe(1); // Pipeline still active for Viewer 2!
  });

  // --------------------------------------------------------------------------
  // TEST: Multiple Cameras Concurrently across Branches
  // --------------------------------------------------------------------------
  it('streams multiple cameras concurrently across branches with independent lifecycle tracking', async () => {
    // Camera 1: RTSP Cashier
    const cam1Res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send();
    expect(cam1Res.status).toBe(201);

    // Camera 2: Hikvision Entrance
    const cam2Res = await request(app)
      .post(`/api/v1/streams/${entranceCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ demoMode: true });
    expect(cam2Res.status).toBe(201);

    // Two independent active pipelines
    expect(sessionManager.activePipelineCount).toBe(2);

    const pipeline1 = sessionManager.getPipeline(cashierCameraId);
    const pipeline2 = sessionManager.getPipeline(entranceCameraId);

    expect(pipeline1?.camera.source_type).toBe('rtsp');
    expect(pipeline2?.camera.source_type).toBe('hikvision_p2p');
  });

  // --------------------------------------------------------------------------
  // TEST: Resource Cleanup & Idle Reaper
  // --------------------------------------------------------------------------
  it('reaps and cleans up pipeline resources when all viewers disconnect', async () => {
    const sessionRes = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send();

    const sessionId = sessionRes.body.data.session_id;
    expect(sessionManager.activePipelineCount).toBe(1);

    // Sole viewer stops the session
    const stopRes = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/stop`)
      .set('x-user-role', 'super_admin')
      .send({ sessionId });

    expect(stopRes.status).toBe(200);
    expect(stopRes.body.data.remainingViewers).toBe(0);
    expect(stopRes.body.data.pipelineState).toBe('idle');

    // Wait for the idle timeout reaper (configured to 50ms in this test)
    await new Promise((resolve) => setTimeout(resolve, 80));

    // Pipeline should be completely reaped and removed, releasing memory and network
    expect(sessionManager.activePipelineCount).toBe(0);
  });
});
