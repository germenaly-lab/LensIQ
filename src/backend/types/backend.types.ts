import { Camera, CameraSourceType, StreamProfile, SafeCameraDTO } from '../../types/camera';

/**
 * Detailed Connection Status for multi-source cameras
 */
export type ConnectionStatus = 
  | 'configured' 
  | 'connecting' 
  | 'online' 
  | 'offline' 
  | 'unsupported' 
  | 'error';

/**
 * Descriptor returned when a streaming session is initiated
 */
export interface StreamSessionDescriptor {
  sessionId: string;
  cameraId: string;
  sourceType: CameraSourceType;
  connectionStatus: ConnectionStatus;
  streamProfile: StreamProfile;
  playbackProtocol: 'webrtc' | 'hls' | 'mse';
  streamEndpoint: string;
  aiNormalizedStreamUrl: string; // Uniform stream URL consumed by Python AI microservice
  isP2P: boolean;
  createdAt: string;
  expiresAt: string;
  metadata: Record<string, unknown>;
}

export interface AuthenticatedUser {
  id: string;
  role: 'super_admin' | 'company_admin' | 'branch_manager' | 'viewer';
  companyId?: string;
  authorizedBranchIds: string[];
}
