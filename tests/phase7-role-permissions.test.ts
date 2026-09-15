import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/backend/app';
import { CameraService } from '../src/backend/services/camera.service';
import { TenantAuthService } from '../src/core/security/tenant-auth';
import { Camera } from '../src/types/camera';

describe('Phase 7 — Role-Specific Backend & Permission Security Test Suite', () => {
  const cameraService = new CameraService();
  const app = createApp(cameraService);

  const egoCompanyId = '11111111-1111-1111-1111-111111111111';
  const egoFashionBrandId = '22222222-2222-2222-2222-222222222222';
  const armaniBrandId = '22222222-2222-2222-2222-222222222223';
  const acmeCompanyId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const acmeBrandId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  const egoMoaBranchId = '33333333-3333-3333-3333-333333333333';
  const egoCfcBranchId = '33333333-3333-3333-3333-333333333334';
  const armaniCityStarsBranchId = '33333333-3333-3333-3333-333333333335';
  const acmeDowntownBranchId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  const cashier01Id = '44444444-4444-4444-4444-444444444441'; // Ego Fashion, MOA
  const cashier02Id = '44444444-4444-4444-4444-444444444445'; // Ego Fashion, CFC
  const armaniShowcaseId = '44444444-4444-4444-4444-444444444447'; // Armani Exchange, City Stars
  const acmeSecretVaultId = '55555555-5555-5555-5555-555555555551'; // Acme, Downtown

  // ----------------------------------------------------------------------
  // 1. Super Admin: Full Access
  // ----------------------------------------------------------------------
  it('1. Super Admin can view all cameras across all companies and brands', async () => {
    const res = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-role', 'super_admin');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.count).toBeGreaterThanOrEqual(5);

    const cameraIds = res.body.data.map((c: any) => c.id);
    expect(cameraIds).toContain(cashier01Id);
    expect(cameraIds).toContain(cashier02Id);
    expect(cameraIds).toContain(armaniShowcaseId);
    expect(cameraIds).toContain(acmeSecretVaultId);
  });

  // ----------------------------------------------------------------------
  // 2. Brand Manager: Brand Isolation
  // ----------------------------------------------------------------------
  it('2. Brand Manager only sees cameras belonging to assigned brand', async () => {
    const res = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-role', 'brand_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    // Should only contain cameras for Ego Fashion
    for (const cam of res.body.data) {
      expect(cam.brand_id).toBe(egoFashionBrandId);
      expect(cam.brand_id).not.toBe(armaniBrandId);
      expect(cam.brand_id).not.toBe(acmeBrandId);
    }

    const cameraIds = res.body.data.map((c: any) => c.id);
    expect(cameraIds).toContain(cashier01Id);
    expect(cameraIds).toContain(cashier02Id);
    expect(cameraIds).not.toContain(armaniShowcaseId);
    expect(cameraIds).not.toContain(acmeSecretVaultId);
  });

  it('3. Brand Manager CANNOT access camera of another brand via direct ID (403 Forbidden)', async () => {
    // Attempt to access Armani camera with Ego Fashion Brand Manager credentials
    const res = await request(app)
      .get(`/api/v1/cameras/${armaniShowcaseId}`)
      .set('x-user-role', 'brand_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  it('4. Brand Manager CANNOT access camera of another company/tenant (403 Forbidden)', async () => {
    // Attempt to access Acme camera
    const res = await request(app)
      .get(`/api/v1/cameras/${acmeSecretVaultId}`)
      .set('x-user-role', 'brand_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('5. Brand Manager CANNOT create camera in another brand branch (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'brand_manager')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId)
      .send({
        name: 'Sneaky Camera in Armani',
        company_id: egoCompanyId,
        brand_id: armaniBrandId, // Not allowed!
        branch_id: armaniCityStarsBranchId,
        source_type: 'rtsp',
        rtsp_url: 'rtsp://stream.ego.demo/unauthorized',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  // ----------------------------------------------------------------------
  // 3. Branch Security: Branch Isolation & Privilege Limits
  // ----------------------------------------------------------------------
  it('6. Branch Security user only sees cameras belonging to their assigned branch', async () => {
    const res = await request(app)
      .get('/api/v1/cameras')
      .set('x-user-role', 'branch_security')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId)
      .set('x-branch-id', egoMoaBranchId)
      .set('x-authorized-branches', egoMoaBranchId);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    for (const cam of res.body.data) {
      expect(cam.branch_id).toBe(egoMoaBranchId);
    }

    const cameraIds = res.body.data.map((c: any) => c.id);
    expect(cameraIds).toContain(cashier01Id);
    expect(cameraIds).not.toContain(cashier02Id); // CFC branch
    expect(cameraIds).not.toContain(armaniShowcaseId);
    expect(cameraIds).not.toContain(acmeSecretVaultId);
  });

  it('7. Branch Security CANNOT access camera of another branch in same brand (403 Forbidden)', async () => {
    // Attempt to access Cashier 02 (CFC branch) from MOA branch security
    const res = await request(app)
      .get(`/api/v1/cameras/${cashier02Id}`)
      .set('x-user-role', 'branch_security')
      .set('x-company-id', egoCompanyId)
      .set('x-brand-id', egoFashionBrandId)
      .set('x-branch-id', egoMoaBranchId)
      .set('x-authorized-branches', egoMoaBranchId);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Unauthorized');
  });

  it('8. Branch Security staff CANNOT create cameras (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/v1/cameras')
      .set('x-user-role', 'branch_security')
      .set('x-company-id', egoCompanyId)
      .set('x-branch-id', egoMoaBranchId)
      .send({
        name: 'Guard Unauthorized Cam',
        company_id: egoCompanyId,
        brand_id: egoFashionBrandId,
        branch_id: egoMoaBranchId,
        source_type: 'rtsp',
        rtsp_url: 'rtsp://stream.ego.demo/guard',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Branch security staff cannot create cameras');
  });

  it('9. Branch Security staff CANNOT delete cameras (403 Forbidden)', async () => {
    const res = await request(app)
      .delete(`/api/v1/cameras/${cashier01Id}`)
      .set('x-user-role', 'branch_security')
      .set('x-company-id', egoCompanyId)
      .set('x-branch-id', egoMoaBranchId);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toContain('Branch security staff cannot delete cameras');
  });

  // ----------------------------------------------------------------------
  // 4. TenantAuthService Unit Checks
  // ----------------------------------------------------------------------
  it('10. TenantAuthService correctly evaluates role boundaries in memory', () => {
    const testCam: Camera = {
      id: 'test-cam-1',
      company_id: egoCompanyId,
      brand_id: egoFashionBrandId,
      branch_id: egoMoaBranchId,
      name: 'Test Cam',
      source_type: 'rtsp',
      enabled: true,
      status: 'online',
      rtsp_url: 'rtsp://test/live',
      stream_profile: 'main',
      credentials_reference: null,
      last_seen_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    // Super Admin: always allowed
    expect(TenantAuthService.canAccessCamera({ id: 'u1', role: 'super_admin', authorizedBranchIds: [] }, testCam)).toBe(true);

    // Brand Manager: match brand
    expect(TenantAuthService.canAccessCamera({ id: 'u2', role: 'brand_manager', brand_id: egoFashionBrandId, authorizedBranchIds: [] }, testCam)).toBe(true);
    expect(TenantAuthService.canAccessCamera({ id: 'u3', role: 'brand_manager', brand_id: armaniBrandId, authorizedBranchIds: [] }, testCam)).toBe(false);

    // Branch Security: match branch
    expect(TenantAuthService.canAccessCamera({ id: 'u4', role: 'branch_security', branch_id: egoMoaBranchId, authorizedBranchIds: [egoMoaBranchId] }, testCam)).toBe(true);
    expect(TenantAuthService.canAccessCamera({ id: 'u5', role: 'branch_security', branch_id: egoCfcBranchId, authorizedBranchIds: [egoCfcBranchId] }, testCam)).toBe(false);
  });
});
