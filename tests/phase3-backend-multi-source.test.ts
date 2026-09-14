import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { CameraService } from '../src/backend/services/camera.service';
import { SourceServiceFactory } from '../src/backend/services/camera-source/source-service.factory';
import { RTSPSourceService } from '../src/backend/services/camera-source/rtsp-source.service';
import { HikvisionP2PSourceService } from '../src/backend/services/camera-source/hikvision-p2p-source.service';

describe('Phase 3 — Multi-Source Camera Backend Test Suite', () => {
  const cameraService = new CameraService();
  const app = createApp(cameraService);

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const egoBrandId = '22222222-2222-2222-2222-222222222222';
  const egoBranchId = '33333333-3333-3333-3333-333333333333';

  // ----------------------------------------------------------------------
  // Test 1: RTSP Camera Creation
  // ----------------------------------------------------------------------
  it('1. RTSP camera creation succeeds with valid RTSP configuration', async () => {
    const res = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Drive-Thru Lane 1',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'rtsp',
        rtsp_url: 'rtsp://stream.ego.demo/drive-thru/main',
        stream_profile: 'main',
        credentials_payload: {
          username: 'rtsp_admin',
          password: 'super_secret_rtsp_password',
        },
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Drive-Thru Lane 1');
    expect(res.body.data.source_type).toBe('rtsp');
    expect(res.body.data.rtsp_url).toBe('rtsp://stream.ego.demo/drive-thru/main');
  });

  // ----------------------------------------------------------------------
  // Test 2: Hikvision P2P Camera Creation
  // ----------------------------------------------------------------------
  it('2. Hikvision P2P camera creation succeeds with valid P2P configuration', async () => {
    const res = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Warehouse Loading Bay',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'hikvision_p2p',
        hik_device_id: 'HIK-BAY-4491-IS',
        hik_serial_number: 'SER-BAY-99182',
        hik_channel: 2,
        stream_profile: 'sub',
        credentials_payload: {
          app_key: 'hik_app_key_secret_123',
          app_secret: 'hik_app_secret_xyz',
        },
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Warehouse Loading Bay');
    expect(res.body.data.source_type).toBe('hikvision_p2p');
    expect(res.body.data.hik_device_id).toBe('HIK-BAY-4491-IS');
    expect(res.body.data.hik_channel).toBe(2);
    // RTSP url should be null for P2P camera
    expect(res.body.data.rtsp_url).toBeNull();
  });

  // ----------------------------------------------------------------------
  // Test 3: Invalid RTSP Configuration Rejected
  // ----------------------------------------------------------------------
  it('3. Invalid RTSP configuration is strictly rejected', async () => {
    // Missing rtsp_url
    const resMissingUrl = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Broken RTSP Cam',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'rtsp',
        // rtsp_url missing!
      });

    expect(resMissingUrl.status).toBe(400);
    expect(resMissingUrl.body.success).toBe(false);
    expect(resMissingUrl.body.error).toContain('RTSP URL is required');

    // Invalid protocol scheme (http instead of rtsp)
    const resInvalidProtocol = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'HTTP not RTSP',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'rtsp',
        rtsp_url: 'http://my-camera.local/stream.mjpg',
      });

    expect(resInvalidProtocol.status).toBe(400);
    expect(resInvalidProtocol.body.success).toBe(false);
    expect(resInvalidProtocol.body.error).toContain('rtsp:// or rtsps://');
  });

  // ----------------------------------------------------------------------
  // Test 4: Invalid P2P Configuration Rejected
  // ----------------------------------------------------------------------
  it('4. Invalid Hikvision P2P configuration is strictly rejected', async () => {
    // Missing device_id
    const resMissingDeviceId = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Broken Hikvision Cam',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'hikvision_p2p',
        hik_channel: 1,
      });

    expect(resMissingDeviceId.status).toBe(400);
    expect(resMissingDeviceId.body.success).toBe(false);
    expect(resMissingDeviceId.body.error).toContain('Device Identifier');

    // Invalid channel (< 1)
    const resInvalidChannel = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'Bad Channel Cam',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'hikvision_p2p',
        hik_device_id: 'HIK-9921',
        hik_channel: 0,
      });

    expect(resInvalidChannel.status).toBe(400);
    expect(resInvalidChannel.body.success).toBe(false);
    expect(resInvalidChannel.body.error).toContain('Channel must be between 1 and 128');
  });

  // ----------------------------------------------------------------------
  // Test 5: Camera Authorization (Multi-Tenant Isolation)
  // ----------------------------------------------------------------------
  it('5. Camera authorization prevents unauthorized tenant/branch access', async () => {
    // Acme branch ID from mock seed
    const acmeBranchId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    const acmeCompanyId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    // User assigned ONLY to Acme branch tries to fetch Ego cameras
    const unauthorizedUser = {
      'x-user-id': 'acme-user-1',
      'x-user-role': 'branch_manager',
      'x-company-id': acmeCompanyId,
      'x-authorized-branches': acmeBranchId,
    };

    // Attempting to access Cashier 01 (which belongs to Ego)
    const res = await request(app)
      .get('/api/v1/cameras/44444444-4444-4444-4444-444444444441')
      .set(unauthorizedUser);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  // ----------------------------------------------------------------------
  // Test 6: Stream Session Authorization
  // ----------------------------------------------------------------------
  it('6. Stream session authorization prevents unauthorized stream initiation', async () => {
    const acmeBranchId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    const acmeCompanyId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    const unauthorizedUser = {
      'x-user-id': 'acme-user-1',
      'x-user-role': 'branch_manager',
      'x-company-id': acmeCompanyId,
      'x-authorized-branches': acmeBranchId,
    };

    // Attempting to initiate streaming session for Ego Main Entrance camera
    const res = await request(app)
      .post('/api/v1/streams/44444444-4444-4444-4444-444444444442/session')
      .set(unauthorizedUser)
      .send({ streamProfile: 'main' });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  // ----------------------------------------------------------------------
  // Test 7: Sensitive Credential Protection (Zero Secret Exposure)
  // ----------------------------------------------------------------------
  it('7. Sensitive credentials and secret keys are never returned to API responses', async () => {
    // 1. Create camera with secret passwords
    const createRes = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'super_admin')
      .send({
        name: 'High Security Cam',
        company_id: egoCompanyId,
        brand_id: egoBrandId,
        branch_id: egoBranchId,
        source_type: 'rtsp',
        rtsp_url: 'rtsp://admin:super_secret_plain_pass@10.0.0.50:554/stream',
        credentials_payload: {
          secret_key: 'confidential_token_xyz',
          password: 'do_not_leak_to_flutter',
        },
      });

    expect(createRes.status).toBe(201);
    const cameraDto = createRes.body.data;

    // Zero credential exposure guarantees:
    expect(cameraDto.credentials_reference).toBeUndefined();
    expect(cameraDto.credentials_payload).toBeUndefined();
    expect(cameraDto.password).toBeUndefined();
    expect(cameraDto.secret_key).toBeUndefined();
    // Inline password stripped from RTSP url
    expect(cameraDto.rtsp_url).not.toContain('super_secret_plain_pass');
    expect(cameraDto.rtsp_url).toBe('rtsp://10.0.0.50:554/stream');

    // 2. Fetch list of cameras and verify secrets remain stripped
    const listRes = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-role', 'super_admin');

    for (const cam of listRes.body.data) {
      expect(cam.credentials_reference).toBeUndefined();
      expect(cam.password).toBeUndefined();
    }
  });

  // ----------------------------------------------------------------------
  // Test 8: Source Adapter Selection (RTSP vs Hikvision P2P)
  // ----------------------------------------------------------------------
  it('8. Source adapter selection delegates correctly based on source_type', async () => {
    const rtspAdapter = SourceServiceFactory.getService('rtsp');
    expect(rtspAdapter).toBeInstanceOf(RTSPSourceService);
    expect(rtspAdapter.sourceType).toBe('rtsp');

    const hikvisionAdapter = SourceServiceFactory.getService('hikvision_p2p');
    expect(hikvisionAdapter).toBeInstanceOf(HikvisionP2PSourceService);
    expect(hikvisionAdapter.sourceType).toBe('hikvision_p2p');

    // POST /streams/:cameraId/session on Hikvision camera uses P2P adapter
    const resHik = await request(app)
      .post('/api/v1/streams/44444444-4444-4444-4444-444444444442/session')
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main' });

    expect(resHik.status).toBe(201);
    expect(resHik.body.data.sourceType).toBe('hikvision_p2p');
    expect(resHik.body.data.isP2P).toBe(true);
    expect(resHik.body.data.streamEndpoint).toContain('/live/p2p/');
    // Normalized stream interface for Python AI service
    expect(resHik.body.data.aiNormalizedStreamUrl).toBeDefined();
    expect(resHik.body.data.aiNormalizedStreamUrl).toContain('/internal/raw-feed/');
  });

  // ----------------------------------------------------------------------
  // Test 9: Existing RTSP Functionality Remains Intact
  // ----------------------------------------------------------------------
  it('9. Existing RTSP camera streaming session functionality remains intact', async () => {
    // Seed camera: Cashier 01
    const cashierCameraId = '44444444-4444-4444-4444-444444444441';

    const res = await request(app)
      .post(`/api/v1/streams/${cashierCameraId}/session`)
      .set('x-user-role', 'super_admin')
      .send({ streamProfile: 'main' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.sourceType).toBe('rtsp');
    expect(res.body.data.connectionStatus).toBe('online');
    expect(res.body.data.playbackProtocol).toBe('webrtc');
    expect(res.body.data.streamEndpoint).toContain(cashierCameraId);
    expect(res.body.data.aiNormalizedStreamUrl).toBeDefined();
  });
});
