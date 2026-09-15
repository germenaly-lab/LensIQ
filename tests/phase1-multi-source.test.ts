import { describe, it, expect } from 'vitest';
import { Camera, CameraSourceType } from '../src/types/camera';
import { VideoSourceFactory } from '../src/core/video-sources/video-source.factory';
import { RTSPSource } from '../src/core/video-sources/rtsp-source';
import { HikvisionP2PSource } from '../src/core/video-sources/hikvision-p2p-source';
import { StreamingGateway } from '../src/core/video-sources/streaming-gateway';
import { createCameraSchema } from '../src/core/validation/camera-schema';
import { CameraSerializer } from '../src/core/security/camera-serializer';
import { TenantAuthService, UserContext } from '../src/core/security/tenant-auth';
import { DashboardRepository, SEED_CAMERAS } from '../src/data/mock-db';

describe('Phase 1 — Multi-Source Camera Architecture Test Suite', () => {
  const dashboardRepo = new DashboardRepository();
  const gateway = new StreamingGateway('https://stream.lensiq.cloud');

  // -------------------------------------------------------------
  // Test 1: Existing RTSP cameras continue working
  // -------------------------------------------------------------
  it('1. Existing RTSP cameras continue working via the VideoSource abstraction', async () => {
    const cashierCamera = SEED_CAMERAS.find((c) => c.name === 'Cashier 01');
    expect(cashierCamera).toBeDefined();
    expect(cashierCamera?.source_type).toBe('rtsp');

    // Instantiation through factory
    const videoSource = VideoSourceFactory.create(cashierCamera!);
    expect(videoSource).toBeInstanceOf(RTSPSource);

    // Validation passes
    const validation = videoSource.validateConfiguration();
    expect(validation.isValid).toBe(true);
    expect(validation.errors).toHaveLength(0);

    // Stream descriptor for clients
    const descriptor = videoSource.getStreamDescriptor('https://stream.lensiq.cloud');
    expect(descriptor.sourceType).toBe('rtsp');
    expect(descriptor.playbackProtocol).toBe('webrtc');
    expect(descriptor.streamEndpoint).toContain(cashierCamera!.id);

    // Gateway initializes pipeline using the abstraction without error
    const session = await gateway.initializeStreamPipeline(videoSource);
    expect(session.status).toBe('active');
    expect(session.pipeline.connectionConfig.transportType).toBe('direct_tcp');
    expect(session.pipeline.connectionConfig.endpointUri).toBe(cashierCamera!.rtsp_url);
  });

  // -------------------------------------------------------------
  // Test 2: Hikvision P2P camera records can be created
  // -------------------------------------------------------------
  it('2. Hikvision P2P camera records can be created and processed', async () => {
    const mainEntranceCamera = SEED_CAMERAS.find((c) => c.name === 'Main Entrance');
    expect(mainEntranceCamera).toBeDefined();
    expect(mainEntranceCamera?.source_type).toBe('hikvision_p2p');
    expect(mainEntranceCamera?.hik_device_id).toBe('HIK-DS-2CD2143G2-DEMO-01');
    expect(mainEntranceCamera?.hik_channel).toBe(1);

    // Instantiate Hikvision P2P source
    const videoSource = VideoSourceFactory.create(mainEntranceCamera!);
    expect(videoSource).toBeInstanceOf(HikvisionP2PSource);

    // Validation passes
    const validation = videoSource.validateConfiguration();
    expect(validation.isValid).toBe(true);

    // Client descriptor has isP2P flag set to true
    const descriptor = videoSource.getStreamDescriptor('https://stream.lensiq.cloud');
    expect(descriptor.sourceType).toBe('hikvision_p2p');
    expect(descriptor.isP2P).toBe(true);
    expect(descriptor.metadata.rawTransport).toBe('Hik-Connect-Cloud-P2P');

    // Gateway starts cloud relay pipeline
    const session = await gateway.initializeStreamPipeline(videoSource);
    expect(session.status).toBe('active');
    expect(session.pipeline.connectionConfig.transportType).toBe('cloud_p2p_relay');
    expect(session.pipeline.connectionConfig.p2pParams?.deviceId).toBe(mainEntranceCamera?.hik_device_id);
    expect(session.pipeline.connectionConfig.p2pParams?.channel).toBe(1);
  });

  // -------------------------------------------------------------
  // Test 3: Camera source_type validation works
  // -------------------------------------------------------------
  it('3. Camera source_type validation works for valid inputs', () => {
    // Valid RTSP camera
    const validRTSP = createCameraSchema.safeParse({
      name: 'Storage Room RTSP',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'rtsp',
      rtsp_url: 'rtsp://192.168.1.100:554/stream1',
      stream_profile: 'main',
    });
    expect(validRTSP.success).toBe(true);

    // Valid Hikvision P2P camera
    const validHikvision = createCameraSchema.safeParse({
      name: 'Backdoor Hikvision P2P',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'hikvision_p2p',
      hik_device_id: 'HIK-DEV-998877',
      hik_serial_number: 'SER998877',
      hik_channel: 2,
      stream_profile: 'sub',
    });
    expect(validHikvision.success).toBe(true);
  });

  // -------------------------------------------------------------
  // Test 4: Invalid source configurations are rejected
  // -------------------------------------------------------------
  it('4. Invalid source configurations are rejected strictly', () => {
    // RTSP missing required rtsp_url
    const invalidRTSP = createCameraSchema.safeParse({
      name: 'Broken RTSP',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'rtsp',
      // rtsp_url missing!
    });
    expect(invalidRTSP.success).toBe(false);

    // RTSP with HTTP url instead of RTSP
    const invalidRTSPUrl = createCameraSchema.safeParse({
      name: 'HTTP not RTSP',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'rtsp',
      rtsp_url: 'http://example.com/video.mp4',
    });
    expect(invalidRTSPUrl.success).toBe(false);

    // Hikvision P2P missing device_id and invalid channel 0
    const invalidHik = createCameraSchema.safeParse({
      name: 'Broken Hikvision',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'hikvision_p2p',
      hik_channel: 0, // invalid (min: 1)
    });
    expect(invalidHik.success).toBe(false);

    // Unsupported source type
    const unsupportedSource = createCameraSchema.safeParse({
      name: 'Unknown Source',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      source_type: 'webrtc_custom' as unknown as CameraSourceType,
    });
    expect(unsupportedSource.success).toBe(false);
  });

  // -------------------------------------------------------------
  // Test 5: RLS prevents unauthorized camera access
  // -------------------------------------------------------------
  it('5. RLS prevents unauthorized camera access across tenants & branches', () => {
    const allCameras = dashboardRepo.getAllCameras();

    // User A: Manager only for Ego Mall of Arabia Branch
    const egoBranchManager: UserContext = {
      id: 'usr-ego-mgr-1',
      role: 'branch_manager',
      company_id: '11111111-1111-1111-1111-111111111111',
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333333'],
    };

    const egoAuthorizedCameras = TenantAuthService.filterAuthorizedCameras(egoBranchManager, allCameras);
    // Should see Cashier 01 and Main Entrance (both belonging to Ego MOA branch)
    expect(egoAuthorizedCameras).toHaveLength(2);
    expect(egoAuthorizedCameras.map((c) => c.name)).toContain('Cashier 01');
    expect(egoAuthorizedCameras.map((c) => c.name)).toContain('Main Entrance');
    // MUST NOT see Acme cameras
    expect(egoAuthorizedCameras.map((c) => c.name)).not.toContain('Acme Secret Vault Camera');

    // User B: Acme Manager
    const acmeManager: UserContext = {
      id: 'usr-acme-mgr-1',
      role: 'branch_manager',
      company_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      authorizedBranchIds: ['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'],
    };

    const acmeAuthorizedCameras = TenantAuthService.filterAuthorizedCameras(acmeManager, allCameras);
    expect(acmeAuthorizedCameras).toHaveLength(1);
    expect(acmeAuthorizedCameras[0].name).toBe('Acme Secret Vault Camera');
    // Acme manager cannot see any of Ego's cameras
    expect(acmeAuthorizedCameras.map((c) => c.name)).not.toContain('Cashier 01');
    expect(acmeAuthorizedCameras.map((c) => c.name)).not.toContain('Main Entrance');
  });

  // -------------------------------------------------------------
  // Test 6: Sensitive credentials are not returned to frontend/API responses
  // -------------------------------------------------------------
  it('6. Sensitive credentials are never returned to frontend or Flutter clients', () => {
    const cameraWithCredentials: Camera = {
      id: 'camera-with-secret-1',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      name: 'Secure Vault Cam',
      source_type: 'rtsp',
      enabled: true,
      status: 'online',
      location_description: 'Top Secret Zone',
      rtsp_url: 'rtsp://admin:super_secret_password_123@192.168.1.50:554/live',
      credentials_reference: 'vault-ref-secret-token-xyz',
      stream_profile: 'main',
      last_seen_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const safeDto = CameraSerializer.serializeForClient(cameraWithCredentials);

    // 1. credentials_reference must not exist on the client DTO
    expect((safeDto as any).credentials_reference).toBeUndefined();

    // 2. Inline passwords inside RTSP URLs must be stripped
    expect(safeDto.rtsp_url).not.toContain('super_secret_password_123');
    expect(safeDto.rtsp_url).not.toContain('admin:');
    expect(safeDto.rtsp_url).toBe('rtsp://192.168.1.50:554/live');

    // 3. For Hikvision P2P, test serialization
    const hikCameraWithSecret: Camera = {
      id: 'camera-hik-secret-2',
      company_id: '11111111-1111-1111-1111-111111111111',
      brand_id: '22222222-2222-2222-2222-222222222222',
      branch_id: '33333333-3333-3333-3333-333333333333',
      name: 'Hikvision Secure Cam',
      source_type: 'hikvision_p2p',
      enabled: true,
      status: 'online',
      hik_device_id: 'HIK-SECRET-DEVICE-01',
      hik_serial_number: 'SERIAL-9988',
      hik_channel: 1,
      hik_username: 'super_admin_user',
      credentials_reference: 'vault-ref-hik-secret-key-99',
      stream_profile: 'main',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const safeHikDto = CameraSerializer.serializeForClient(hikCameraWithSecret);
    expect((safeHikDto as any).credentials_reference).toBeUndefined();
    expect((safeHikDto as any).hik_username).toBeUndefined();
    expect(safeHikDto.hik_device_id).toBe('HIK-SECRET-DEVICE-01');
  });

  // -------------------------------------------------------------
  // Test 7: Existing dashboard queries continue working
  // -------------------------------------------------------------
  it('7. Existing dashboard queries continue working across both camera source types', () => {
    const egoBranchId = '33333333-3333-3333-3333-333333333333';

    // Query cameras by branch
    const branchCameras = dashboardRepo.getCamerasByBranch(egoBranchId);
    expect(branchCameras).toHaveLength(2);

    // Aggregate statistics query
    const stats = dashboardRepo.getBranchCameraStats(egoBranchId);
    expect(stats.total).toBe(2);
    expect(stats.online).toBe(2);
    expect(stats.offline).toBe(0);
    expect(stats.bySource.rtsp).toBe(1);
    expect(stats.bySource.hikvision_p2p).toBe(1);

    // Query cameras by company
    const egoCompanyCameras = dashboardRepo.getCamerasByCompany('11111111-1111-1111-1111-111111111111');
    expect(egoCompanyCameras.length).toBeGreaterThanOrEqual(2);
  });
});
