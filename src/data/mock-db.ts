import { Company, Brand, Branch, Camera } from '../types/camera';

export const SEED_COMPANIES: Company[] = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Ego',
    slug: 'ego',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Acme Retail Group',
    slug: 'acme-retail',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
];

export const SEED_BRANDS: Brand[] = [
  {
    id: '22222222-2222-2222-2222-222222222222',
    company_id: '11111111-1111-1111-1111-111111111111',
    name: 'Ego Fashion',
    slug: 'ego-fashion',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: '22222222-2222-2222-2222-222222222223',
    company_id: '11111111-1111-1111-1111-111111111111',
    name: 'Armani Exchange',
    slug: 'armani-exchange',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    company_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Acme Pro Store',
    slug: 'acme-pro',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
];

export const SEED_BRANCHES: Branch[] = [
  {
    id: '33333333-3333-3333-3333-333333333333',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222222',
    name: 'Ego Mall of Arabia Branch',
    code: 'EGO-MOA-01',
    address: 'Mall of Arabia, Gate 4, 6th of October',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: '33333333-3333-3333-3333-333333333334',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222222',
    name: 'Ego Cairo Festival City Branch',
    code: 'EGO-CFC-02',
    address: 'Cairo Festival City Mall, New Cairo',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: '33333333-3333-3333-3333-333333333335',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222223',
    name: 'Armani City Stars Branch',
    code: 'ARM-CS-01',
    address: 'City Stars Mall, Phase 2, Heliopolis',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    company_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    brand_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Acme Downtown Branch',
    code: 'ACME-DT-01',
    address: '100 Main St',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
];

export const SEED_CAMERAS: Camera[] = [
  {
    id: '44444444-4444-4444-4444-444444444441',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222222',
    branch_id: '33333333-3333-3333-3333-333333333333',
    name: 'Cashier 01',
    source_type: 'rtsp',
    enabled: true,
    status: 'online',
    location_description: 'Counter 1 - Main Checkout Area',
    rtsp_url: 'rtsp://stream.ego-store.demo/live/cashier01',
    credentials_reference: 'vault-rtsp-cashier01-demo',
    stream_profile: 'main',
    last_seen_at: new Date().toISOString(),
    created_at: '2026-01-01T10:00:00Z',
    updated_at: '2026-01-01T10:00:00Z',
  },
  {
    id: '44444444-4444-4444-4444-444444444442',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222222',
    branch_id: '33333333-3333-3333-3333-333333333333',
    name: 'Main Entrance',
    source_type: 'hikvision_p2p',
    enabled: true,
    status: 'online',
    location_description: 'Customer Entrance & Glass Gates',
    hik_device_id: 'HIK-DS-2CD2143G2-DEMO-01',
    hik_serial_number: 'D12345678FakeSerial',
    hik_channel: 1,
    hik_username: 'admin',
    credentials_reference: 'vault-hik-mainentrance-demo',
    stream_profile: 'main',
    last_seen_at: new Date().toISOString(),
    created_at: '2026-01-01T10:00:00Z',
    updated_at: '2026-01-01T10:00:00Z',
  },
  {
    id: '44444444-4444-4444-4444-444444444445',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222222',
    branch_id: '33333333-3333-3333-3333-333333333334',
    name: 'Cashier 02',
    source_type: 'rtsp',
    enabled: true,
    status: 'online',
    location_description: 'CFC Main Checkout Zone',
    rtsp_url: 'rtsp://stream.cfc.demo/live/cashier02',
    credentials_reference: 'vault-rtsp-cfc-02',
    stream_profile: 'main',
    last_seen_at: new Date().toISOString(),
    created_at: '2026-01-01T10:00:00Z',
    updated_at: '2026-01-01T10:00:00Z',
  },
  {
    id: '44444444-4444-4444-4444-444444444447',
    company_id: '11111111-1111-1111-1111-111111111111',
    brand_id: '22222222-2222-2222-2222-222222222223',
    branch_id: '33333333-3333-3333-3333-333333333335',
    name: 'Armani Showcase 01',
    source_type: 'rtsp',
    enabled: true,
    status: 'online',
    location_description: 'City Stars Front Display',
    rtsp_url: 'rtsp://stream.cs.demo/live/front',
    credentials_reference: 'vault-rtsp-armani-cs',
    stream_profile: 'main',
    last_seen_at: new Date().toISOString(),
    created_at: '2026-01-01T10:00:00Z',
    updated_at: '2026-01-01T10:00:00Z',
  },
  {
    id: '55555555-5555-5555-5555-555555555551',
    company_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    brand_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    branch_id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    name: 'Acme Secret Vault Camera',
    source_type: 'rtsp',
    enabled: true,
    status: 'online',
    location_description: 'Acme High Security Zone',
    rtsp_url: 'rtsp://stream.acme.demo/live/vault',
    credentials_reference: 'vault-rtsp-acme-sec',
    stream_profile: 'main',
    last_seen_at: new Date().toISOString(),
    created_at: '2026-01-01T10:00:00Z',
    updated_at: '2026-01-01T10:00:00Z',
  },
];

/**
 * Dashboard Query Simulator
 * Verifies that existing queries continue to function without errors.
 */
export class DashboardRepository {
  private cameras: Camera[] = [...SEED_CAMERAS];

  getCamerasByBranch(branchId: string): Camera[] {
    return this.cameras.filter((c) => c.branch_id === branchId);
  }

  getCamerasByCompany(companyId: string): Camera[] {
    return this.cameras.filter((c) => c.company_id === companyId);
  }

  getBranchCameraStats(branchId: string) {
    const branchCameras = this.getCamerasByBranch(branchId);
    return {
      total: branchCameras.length,
      online: branchCameras.filter((c) => c.status === 'online').length,
      offline: branchCameras.filter((c) => c.status === 'offline').length,
      bySource: {
        rtsp: branchCameras.filter((c) => c.source_type === 'rtsp').length,
        hikvision_p2p: branchCameras.filter((c) => c.source_type === 'hikvision_p2p').length,
      },
    };
  }

  addCamera(camera: Camera): Camera {
    this.cameras.push(camera);
    return camera;
  }

  getAllCameras(): Camera[] {
    return [...this.cameras];
  }
}
