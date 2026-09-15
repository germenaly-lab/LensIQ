import { Request, Response, NextFunction } from 'express';
import { AuthenticatedUser } from '../types/backend.types';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  // Allow header-based context injection for testing and service-to-service calls
  const userId = (req.headers['x-user-id'] as string) || 'demo-super-admin-01';
  const role = (req.headers['x-user-role'] as AuthenticatedUser['role']) || 'super_admin';
  const companyId = req.headers['x-company-id'] as string | undefined;
  const brandId = req.headers['x-brand-id'] as string | undefined;
  const branchId = req.headers['x-branch-id'] as string | undefined;
  const branchesHeader = req.headers['x-authorized-branches'] as string | undefined;

  const authorizedBranchIds = branchesHeader
    ? branchesHeader.split(',').map((b) => b.trim())
    : branchId
    ? [branchId]
    : ['33333333-3333-3333-3333-333333333333']; // Defaults to Ego MOA branch

  req.user = {
    id: userId,
    role,
    companyId,
    brandId,
    branchId,
    authorizedBranchIds,
  };

  next();
}
