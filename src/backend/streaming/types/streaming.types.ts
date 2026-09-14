import { CameraSourceType, StreamProfile } from '../../../types/camera';

/**
 * Streaming Protocols exposed to Flutter and Web players.
 * Note: Flutter will NEVER connect directly to RTSP or Hikvision P2P.
 */
export type StreamProtocol = 'webrtc' | 'hls';

/**
 * Detailed Lifecycle State of a Video Source
 */
export type SourceConnectionState =
  | 'idle'
  | 'configured'
  | 'connecting'
  | 'online'
  | 'streaming'
  | 'reconnecting'
  | 'offline'
  | 'unsupported'
  | 'error';

/**
 * Source Telemetry & Status
 */
export interface VideoSourceStatus {
  sourceType: CameraSourceType;
  state: SourceConnectionState;
  latencyMs: number;
  reconnectCount: number;
  lastError: string | null;
  lastSuccessfulFrame: string | null;
  streamStartTime: string | null;
  uptimeSeconds: number;
  isDemo: boolean;
  metadata?: Record<string, unknown>;
}

/**
 * Technical Video Stream Metadata
 */
export interface StreamInfo {
  streamId: string;
  cameraId: string;
  sourceType: CameraSourceType;
  profile: StreamProfile;
  hlsEndpoint: string;
  webrtcEndpoint: string;
  resolution: {
    width: number;
    height: number;
  };
  fps: number;
  codec: string;
  bitrateKbps: number;
  isDemo: boolean;
}

/**
 * Live Monitoring Telemetry tracked by Streaming Gateway
 */
export interface StreamMonitoringStats {
  connection_status: SourceConnectionState;
  latency_ms: number;
  reconnect_count: number;
  last_error: string | null;
  last_successful_frame: string | null;
  stream_start_time: string | null;
  uptime_seconds: number;
  viewer_count: number;
}

/**
 * UNIFIED STREAM SESSION
 * Exposed to Flutter client and Admin UI.
 * Standardizes RTSP and Hikvision P2P into an identical playback structure.
 * Guaranteed zero exposure of raw credentials, RTSP passwords, or Hikvision keys.
 */
export interface UnifiedStreamSession {
  session_id: string;
  camera_id: string;
  source_type: CameraSourceType;
  stream_url: string; // Temporary authenticated playback URL (WebRTC or HLS)
  token: string;      // Cryptographically signed ephemeral session token
  protocol: StreamProtocol;
  status: 'active' | 'idle' | 'reconnecting' | 'terminating' | 'expired';
  created_at: string;
  expires_at: string;
  viewer_count: number;
  demo_mode: boolean;
  stream_info: {
    resolution: string;
    fps: number;
    codec: string;
    profile: StreamProfile;
  };
  monitoring: StreamMonitoringStats;
}

/**
 * Request payload when client initiates or joins a stream
 */
export interface StreamSessionRequest {
  streamProfile?: StreamProfile;
  protocol?: StreamProtocol;
  demoMode?: boolean;
}
