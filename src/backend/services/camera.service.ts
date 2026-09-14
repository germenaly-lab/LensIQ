import { Camera, SafeCameraDTO, CameraSourceType } from '../../types/camera';
import { AuthenticatedUser } from '../types/backend.types';
import { SEED_CAMERAS } from '../../data/mock-db';
import { SourceServiceFactory } from './camera-source/source-service.factory';
import { CameraSerializer } from '../../core/security/camera-serializer';
import { CredentialsVaultService } from '../../core/security/credentials-vault';

export class CameraService {
  private cameras: Map<string, Camera> = new Map();
  private vaultService: CredentialsVaultService;

  constructor(vaultService?: CredentialsVaultService) {
    this.vaultService = vaultService || new CredentialsVaultService();
    // Seed initial cameras
    for (const cam of SEED_CAMERAS) {
      this.cameras.set(cam.id, { ...cam });
    }
  }

  /**
   * Check if a user has access to a specific branch
   */
  hasBranchAccess(user: AuthenticatedUser, branchId: string, companyId: string): boolean {
    if (user.role === 'super_admin') return true;
    if (user.role === 'company_admin') return user.companyId === companyId;
    return user.authorizedBranchIds.includes(branchId);
  }

  /**
   * List cameras with multi-tenant filtering
   */
  async listCameras(
    user: AuthenticatedUser,
    filters?: { companyId?: string; branchId?: string; sourceType?: CameraSourceType }
  ): Promise<SafeCameraDTO[]> {
    let result = Array.from(this.cameras.values());

    // Apply authorization boundaries
    result = result.filter((cam) => this.hasBranchAccess(user, cam.branch_id, cam.company_id));

    // Optional query filters
    if (filters?.companyId) {
      result = result.filter((cam) => cam.company_id === filters.companyId);
    }
    if (filters?.branchId) {
      result = result.filter((cam) => cam.branch_id === filters.branchId);
    }
    if (filters?.sourceType) {
      result = result.filter((cam) => cam.source_type === filters.sourceType);
    }

    return CameraSerializer.serializeManyForClient(result);
  }

  /**
   * Get single camera by ID
   */
  async getCameraById(user: AuthenticatedUser, id: string): Promise<SafeCameraDTO> {
    const camera = this.cameras.get(id);
    if (!camera) {
      throw new Error(`Camera not found with ID '${id}'`);
    }

    if (!this.hasBranchAccess(user, camera.branch_id, camera.company_id)) {
      throw new Error('Unauthorized: You do not have permission to access this camera.');
    }

    return CameraSerializer.serializeForClient(camera);
  }

  /**
   * Get raw camera internal entity (for internal services like Streaming Gateway)
   */
  async getRawCamera(user: AuthenticatedUser, id: string): Promise<Camera> {
    const camera = this.cameras.get(id);
    if (!camera) {
      throw new Error(`Camera not found with ID '${id}'`);
    }

    if (!this.hasBranchAccess(user, camera.branch_id, camera.company_id)) {
      throw new Error('Unauthorized: You do not have permission to access this camera.');
    }

    return { ...camera };
  }

  /**
   * Create a new camera
   */
  async createCamera(
    user: AuthenticatedUser,
    data: {
      name: string;
      company_id: string;
      brand_id: string;
      branch_id: string;
      source_type: CameraSourceType;
      location_description?: string;
      rtsp_url?: string;
      hik_device_id?: string;
      hik_serial_number?: string;
      hik_channel?: number;
      hik_username?: string;
      credentials_payload?: Record<string, string>;
      stream_profile?: 'main' | 'sub';
    }
  ): Promise<SafeCameraDTO> {
    if (!this.hasBranchAccess(user, data.branch_id, data.company_id)) {
      throw new Error('Unauthorized: You cannot create cameras in this branch.');
    }

    // 1. Store credentials in vault if provided
    let credentialsReference: string | null = null;
    if (data.credentials_payload) {
      const secretType = data.source_type === 'rtsp' ? 'rtsp_auth' : 'hikvision_p2p_appkey';
      credentialsReference = await this.vaultService.storeSecret(data.credentials_payload, secretType);
    }

    // 2. Build camera entity
    const newCamera: Camera = {
      id: `cam_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
      name: data.name,
      company_id: data.company_id,
      brand_id: data.brand_id,
      branch_id: data.branch_id,
      source_type: data.source_type,
      enabled: true,
      status: 'online',
      location_description: data.location_description || null,
      rtsp_url: data.source_type === 'rtsp' ? data.rtsp_url || null : null,
      hik_device_id: data.source_type === 'hikvision_p2p' ? data.hik_device_id || null : null,
      hik_serial_number: data.source_type === 'hikvision_p2p' ? data.hik_serial_number || null : null,
      hik_channel: data.source_type === 'hikvision_p2p' ? data.hik_channel ?? 1 : null,
      hik_username: data.source_type === 'hikvision_p2p' ? data.hik_username || null : null,
      credentials_reference: credentialsReference,
      stream_profile: data.stream_profile || 'main',
      last_seen_at: new Date().toISOString(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    // 3. Validate configuration against source adapter
    const adapter = SourceServiceFactory.getService(data.source_type);
    const validation = adapter.validateConfiguration(newCamera);
    if (!validation.isValid) {
      throw new Error(`Validation Error for ${data.source_type}: ${validation.errors.join('; ')}`);
    }

    this.cameras.set(newCamera.id, newCamera);
    return CameraSerializer.serializeForClient(newCamera);
  }

  /**
   * Delete camera
   */
  async deleteCamera(user: AuthenticatedUser, id: string): Promise<boolean> {
    const camera = this.cameras.get(id);
    if (!camera) {
      throw new Error(`Camera not found with ID '${id}'`);
    }

    if (!this.hasBranchAccess(user, camera.branch_id, camera.company_id)) {
      throw new Error('Unauthorized: You do not have permission to delete this camera.');
    }

    return this.cameras.delete(id);
  }
}
