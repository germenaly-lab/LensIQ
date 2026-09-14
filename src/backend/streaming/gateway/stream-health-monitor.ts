import { SourceConnectionState, StreamMonitoringStats, VideoSourceStatus } from '../types/streaming.types';

/**
 * StreamHealthMonitor
 * Maintains telemetry and performance metrics for an active camera stream pipeline.
 */
export class StreamHealthMonitor {
  private cameraId: string;
  private status: SourceConnectionState = 'idle';
  private latencyMs: number = 0;
  private reconnectCount: number = 0;
  private lastError: string | null = null;
  private lastSuccessfulFrame: string | null = null;
  private streamStartTime: string | null = null;
  private viewerCount: number = 0;

  constructor(cameraId: string) {
    this.cameraId = cameraId;
  }

  updateFromAdapter(adapterStatus: VideoSourceStatus): void {
    this.status = adapterStatus.state;
    this.latencyMs = adapterStatus.latencyMs;
    this.reconnectCount = adapterStatus.reconnectCount;
    if (adapterStatus.lastError) {
      this.lastError = adapterStatus.lastError;
    }
    if (adapterStatus.lastSuccessfulFrame) {
      this.lastSuccessfulFrame = adapterStatus.lastSuccessfulFrame;
    }
    if (adapterStatus.streamStartTime && !this.streamStartTime) {
      this.streamStartTime = adapterStatus.streamStartTime;
    }
  }

  recordFrame(timestamp: string): void {
    this.lastSuccessfulFrame = timestamp;
  }

  recordError(error: string): void {
    this.lastError = error;
    this.status = 'error';
  }

  recordReconnect(attempt: number): void {
    this.reconnectCount = attempt;
    this.status = 'reconnecting';
  }

  setViewerCount(count: number): void {
    this.viewerCount = Math.max(0, count);
  }

  getSnapshot(): StreamMonitoringStats {
    const uptime = this.streamStartTime
      ? Math.max(0, Math.floor((Date.now() - new Date(this.streamStartTime).getTime()) / 1000))
      : 0;

    return {
      connection_status: this.status,
      latency_ms: this.latencyMs,
      reconnect_count: this.reconnectCount,
      last_error: this.lastError,
      last_successful_frame: this.lastSuccessfulFrame,
      stream_start_time: this.streamStartTime,
      uptime_seconds: uptime,
      viewer_count: this.viewerCount,
    };
  }
}
