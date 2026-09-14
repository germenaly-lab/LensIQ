import { EventEmitter } from 'events';
import { Camera, StreamProfile } from '../../../types/camera';
import { VideoSourceStatus, StreamInfo, SourceConnectionState } from '../types/streaming.types';

/**
 * Common Video Source Adapter Interface
 * Unifies all camera source implementations (RTSP, Hikvision P2P, Demo sources).
 * Decouples the Gateway and Flutter from hardware protocol nuances.
 */
export interface IVideoSourceAdapter extends EventEmitter {
  readonly cameraId: string;
  readonly sourceType: Camera['source_type'];
  readonly isDemo: boolean;

  /**
   * Connect to the camera hardware or cloud service
   */
  connect(): Promise<void>;

  /**
   * Disconnect and release network connections
   */
  disconnect(): Promise<void>;

  /**
   * Start video stream acquisition and pipeline processing
   */
  startStream(profile?: StreamProfile): Promise<StreamInfo>;

  /**
   * Stop video stream acquisition and pipeline processing
   */
  stopStream(): Promise<void>;

  /**
   * Retrieve current connection state, telemetry, and health metrics
   */
  getStatus(): Promise<VideoSourceStatus>;

  /**
   * Trigger an explicit reconnection cycle
   */
  reconnect(): Promise<void>;

  /**
   * Retrieve active stream information, or null if not streaming
   */
  getStreamInfo(): StreamInfo | null;
}
