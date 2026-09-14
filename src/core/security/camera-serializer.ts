import { Camera, SafeCameraDTO } from '../../types/camera';

/**
 * Camera Response Serializer
 * Strips all internal credential references, vault keys, and raw authentication details.
 * Strictly guarantees Flutter and Web clients never receive credentials.
 */
export class CameraSerializer {
  /**
   * Serialize a single camera entity for frontend / Flutter mobile clients.
   */
  static serializeForClient(camera: Camera): SafeCameraDTO {
    return {
      id: camera.id,
      company_id: camera.company_id,
      brand_id: camera.brand_id,
      branch_id: camera.branch_id,
      name: camera.name,
      source_type: camera.source_type,
      enabled: camera.enabled,
      status: camera.status,
      location_description: camera.location_description,
      // For RTSP cameras, provide sanitized URL without embedded username/password
      rtsp_url: camera.source_type === 'rtsp' ? this.sanitizeRtspUrl(camera.rtsp_url) : null,
      // For Hikvision cameras, provide device identifier and channel (no secret keys or tokens)
      hik_device_id: camera.source_type === 'hikvision_p2p' ? camera.hik_device_id : null,
      hik_serial_number: camera.source_type === 'hikvision_p2p' ? camera.hik_serial_number : null,
      hik_channel: camera.source_type === 'hikvision_p2p' ? camera.hik_channel : null,
      stream_profile: camera.stream_profile,
      last_seen_at: camera.last_seen_at,
      created_at: camera.created_at,
      updated_at: camera.updated_at,
      // Notice: 'credentials_reference', 'hik_username', internal vault IDs are OMITTED entirely.
    };
  }

  /**
   * Serialize a list of cameras.
   */
  static serializeManyForClient(cameras: Camera[]): SafeCameraDTO[] {
    return cameras.map((c) => this.serializeForClient(c));
  }

  /**
   * Remove inline basic-auth credentials from RTSP URLs (e.g. rtsp://user:pass@host/path -> rtsp://host/path)
   */
  private static sanitizeRtspUrl(url?: string | null): string | null {
    if (!url) return null;
    try {
      const parsed = new URL(url);
      parsed.username = '';
      parsed.password = '';
      return parsed.toString();
    } catch {
      // Fallback regex if URL parser fails on custom rtsp:// schema
      return url.replace(/rtsp:\/\/[^@]+@/, 'rtsp://');
    }
  }
}
