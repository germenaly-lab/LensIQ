import { Camera } from '../../types/camera';

export interface UserContext {
  id: string;
  role: 'super_admin' | 'company_admin' | 'brand_manager' | 'branch_manager' | 'branch_security' | 'viewer';
  company_id?: string;
  brand_id?: string;
  branch_id?: string;
  authorizedBranchIds: string[];
}

/**
 * Tenant Authorization & RLS Rule Evaluator
 * Mirrors the database RLS policies in the application layer.
 */
export class TenantAuthService {
  /**
   * Determine if a user is authorized to read/access a specific camera.
   */
  static canAccessCamera(user: UserContext, camera: Camera): boolean {
    // Super admins can access any camera across all tenants
    if (user.role === 'super_admin') {
      return true;
    }

    // Company admins can access all cameras within their assigned company
    if (user.role === 'company_admin') {
      return user.company_id === camera.company_id;
    }

    // Brand Managers can ONLY access cameras belonging to their assigned brand
    if (user.role === 'brand_manager') {
      if (!user.brand_id) return false;
      return user.brand_id === camera.brand_id;
    }

    // Branch Security users can ONLY access cameras within their assigned branch
    if (user.role === 'branch_security') {
      if (user.branch_id && user.branch_id === camera.branch_id) {
        return true;
      }
      return user.authorizedBranchIds.includes(camera.branch_id);
    }

    // Branch managers and viewers can only access cameras within branches explicitly assigned to them
    return user.authorizedBranchIds.includes(camera.branch_id);
  }

  /**
   * Filter a list of cameras according to the user's RLS boundaries.
   */
  static filterAuthorizedCameras(user: UserContext, cameras: Camera[]): Camera[] {
    return cameras.filter((camera) => this.canAccessCamera(user, camera));
  }
}
