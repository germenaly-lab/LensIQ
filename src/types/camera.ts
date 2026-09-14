/**
 * LensIQ Enterprise CCTV Platform - Phase 1 Types
 * Multi-Source Camera Architecture
 */

export type CameraSourceType = 'rtsp' | 'hikvision_p2p';
export type CameraStatus = 'online' | 'offline' | 'degraded' | 'provisioning';
export type StreamProfile = 'main' | 'sub';

export interface BaseEntity {
  id: string;
  created_at: string;
  updated_at: string;
}

export interface Company extends BaseEntity {
  name: string;
  slug: string;
}

export interface Brand extends BaseEntity {
  company_id: string;
  name: string;
  slug: string;
}

export interface Branch extends BaseEntity {
  company_id: string;
  brand_id: string;
  name: string;
  code: string;
  address?: string | null;
}

/**
 * Camera database entity
 * Contains configuration for all supported source types.
 * Sensitive passwords are NOT stored here, only credentials_reference.
 */
export interface Camera extends BaseEntity {
  company_id: string;
  brand_id: string;
  branch_id: string;
  name: string;
  source_type: CameraSourceType;
  enabled: boolean;
  status: CameraStatus;
  location_description?: string | null;

  // RTSP specific (nullable for non-RTSP sources)
  rtsp_url?: string | null;

  // Hikvision P2P specific (nullable for non-Hikvision sources)
  hik_device_id?: string | null;
  hik_serial_number?: string | null;
  hik_channel?: number | null;
  hik_username?: string | null;

  // Protected Secret Reference (Points to Vault)
  credentials_reference?: string | null;

  stream_profile: StreamProfile;
  last_seen_at?: string | null;
}

/**
 * Safe Camera DTO for Frontend and Flutter Clients
 * Guaranteed zero exposure of credentials_reference or internal secrets.
 */
export interface SafeCameraDTO {
  id: string;
  company_id: string;
  brand_id: string;
  branch_id: string;
  name: string;
  source_type: CameraSourceType;
  enabled: boolean;
  status: CameraStatus;
  location_description?: string | null;
  rtsp_url?: string | null;
  hik_device_id?: string | null;
  hik_serial_number?: string | null;
  hik_channel?: number | null;
  stream_profile: StreamProfile;
  last_seen_at?: string | null;
  created_at: string;
  updated_at: string;
}

/**
 * Vault Record definition
 */
export interface CameraCredentialVaultRecord {
  id: string;
  credentials_reference: string;
  secret_payload_encrypted: string;
  secret_type: 'rtsp_auth' | 'hikvision_token' | 'hikvision_p2p_appkey';
  created_at: string;
  updated_at: string;
}
