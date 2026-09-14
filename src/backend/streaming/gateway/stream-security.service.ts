import crypto from 'crypto';
import { AuthenticatedUser } from '../../types/backend.types';
import { Camera } from '../../../types/camera';

export interface TokenPayload {
  sessionId: string;
  cameraId: string;
  companyId: string;
  branchId: string;
  protocol: 'webrtc' | 'hls';
  expiresAt: number; // Unix timestamp ms
}

/**
 * StreamSecurityService
 * Handles cryptographic session token generation, session expiration validation,
 * tenant/branch authorization, and ensures zero raw credential leakage to clients.
 */
export class StreamSecurityService {
  private secretKey: string;
  private defaultSessionDurationMs: number;

  constructor(
    secretKey: string = process.env.STREAM_SECRET_KEY || 'lensiq-stream-gateway-secret-salt-2026',
    defaultSessionDurationMs: number = 3600 * 1000 // 1 hour
  ) {
    this.secretKey = secretKey;
    this.defaultSessionDurationMs = defaultSessionDurationMs;
  }

  /**
   * Authorize a user against a camera's tenant and branch boundaries
   */
  authorizeUserForCamera(user: AuthenticatedUser, camera: Camera): void {
    if (user.role === 'super_admin') {
      return;
    }

    if (user.role === 'company_admin') {
      if (user.companyId !== camera.company_id) {
        throw new Error('Unauthorized: Camera belongs to a different enterprise company.');
      }
      return;
    }

    // Branch manager or Viewer
    if (user.companyId && user.companyId !== camera.company_id) {
      throw new Error('Unauthorized: User is not part of this enterprise tenant.');
    }

    if (!user.authorizedBranchIds.includes(camera.branch_id)) {
      throw new Error('Unauthorized: User does not have access to this branch.');
    }
  }

  /**
   * Generate an ephemeral signed token for a streaming session
   */
  generateSessionToken(
    sessionId: string,
    camera: Camera,
    protocol: 'webrtc' | 'hls',
    durationMs?: number
  ): { token: string; expiresAt: string } {
    const ttl = durationMs || this.defaultSessionDurationMs;
    const expiresAtMs = Date.now() + ttl;

    const payload: TokenPayload = {
      sessionId,
      cameraId: camera.id,
      companyId: camera.company_id,
      branchId: camera.branch_id,
      protocol,
      expiresAt: expiresAtMs,
    };

    const serialized = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = crypto
      .createHmac('sha256', this.secretKey)
      .update(serialized)
      .digest('base64url');

    const token = `${serialized}.${signature}`;
    return {
      token,
      expiresAt: new Date(expiresAtMs).toISOString(),
    };
  }

  /**
   * Verify an ephemeral stream token
   */
  verifySessionToken(token: string): { valid: boolean; payload?: TokenPayload; error?: string } {
    if (!token || typeof token !== 'string') {
      return { valid: false, error: 'Token missing or malformed' };
    }

    const parts = token.split('.');
    if (parts.length !== 2) {
      return { valid: false, error: 'Invalid token format' };
    }

    const [serialized, signature] = parts;

    // Verify HMAC
    const expectedSig = crypto
      .createHmac('sha256', this.secretKey)
      .update(serialized)
      .digest('base64url');

    if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSig))) {
      return { valid: false, error: 'Invalid token signature' };
    }

    // Parse payload
    try {
      const payload: TokenPayload = JSON.parse(Buffer.from(serialized, 'base64url').toString('utf-8'));

      // Expiration check
      if (Date.now() > payload.expiresAt) {
        return { valid: false, error: 'Stream session token has expired', payload };
      }

      return { valid: true, payload };
    } catch {
      return { valid: false, error: 'Failed to decode token payload' };
    }
  }

  /**
   * Sanitize an internal stream URL to ensure no credentials or internal IPs are leaked
   */
  buildSafePlaybackUrl(
    gatewayBaseUrl: string,
    cameraId: string,
    sessionId: string,
    protocol: 'webrtc' | 'hls',
    token: string
  ): string {
    const base = gatewayBaseUrl.replace(/\/$/, '');
    if (protocol === 'webrtc') {
      return `${base}/api/v1/streams/playback/${cameraId}/${sessionId}/webrtc?token=${token}`;
    }
    return `${base}/api/v1/streams/playback/${cameraId}/${sessionId}/manifest.m3u8?token=${token}`;
  }
}
