import { CameraSourceType, StreamProfile } from '../../../../types/camera';
import { StreamInfo } from '../../types/streaming.types';

export interface DemoSourceOptions {
  cameraId: string;
  sourceType: CameraSourceType;
  channel?: number;
  profile?: StreamProfile;
  customLabel?: string;
  simulatedLatencyMs?: number;
}

/**
 * DemoMediaProvider
 * Supplies simulated, deterministic video stream feeds for RTSP and Hikvision P2P.
 * Enables full end-to-end Gateway testing and Flutter integration without needing physical CCTV hardware.
 * Clearly labeled internally as demo mode.
 */
export class DemoMediaProvider {
  private options: DemoSourceOptions;
  private isSimulating: boolean = false;
  private frameTimer: NodeJS.Timeout | null = null;
  private frameCount: number = 0;
  private lastFrameTimestamp: string | null = null;

  constructor(options: DemoSourceOptions) {
    this.options = {
      profile: 'main',
      simulatedLatencyMs: options.sourceType === 'rtsp' ? 45 : 85, // Hikvision cloud P2P typically adds relay latency
      ...options,
    };
  }

  get isRunning(): boolean {
    return this.isSimulating;
  }

  get simulatedLatency(): number {
    return this.options.simulatedLatencyMs || 50;
  }

  get lastFrame(): string | null {
    return this.lastFrameTimestamp;
  }

  get totalFrames(): number {
    return this.frameCount;
  }

  /**
   * Start generating simulated frames and telemetry
   */
  start(onFrame?: (frameSeq: number, timestamp: string) => void, requestedProfile?: StreamProfile): StreamInfo {
    this.isSimulating = true;
    this.frameCount = 0;
    this.lastFrameTimestamp = new Date().toISOString();

    if (requestedProfile) {
      this.options.profile = requestedProfile;
    }

    const isSub = this.options.profile === 'sub';
    const width = isSub ? 640 : 1920;
    const height = isSub ? 360 : 1080;
    const fps = isSub ? 15 : 30;
    const bitrate = isSub ? 512 : 2500;

    // Simulate frame generation interval
    const intervalMs = Math.round(1000 / fps);
    this.frameTimer = setInterval(() => {
      if (!this.isSimulating) return;
      this.frameCount++;
      this.lastFrameTimestamp = new Date().toISOString();
      if (onFrame) {
        onFrame(this.frameCount, this.lastFrameTimestamp);
      }
    }, intervalMs);

    // Provide mock HLS & WebRTC endpoints representing the simulated feed
    const slug = `${this.options.sourceType}-demo-${this.options.cameraId.slice(0, 8)}`;
    return {
      streamId: `stream-${slug}-${Date.now()}`,
      cameraId: this.options.cameraId,
      sourceType: this.options.sourceType,
      profile: this.options.profile || 'main',
      hlsEndpoint: `https://stream.lensiq.cloud/hls/${slug}/playlist.m3u8`,
      webrtcEndpoint: `webrtc://stream.lensiq.cloud/webrtc/${slug}`,
      resolution: { width, height },
      fps,
      codec: 'h264',
      bitrateKbps: bitrate,
      isDemo: true,
    };
  }

  /**
   * Stop frame simulation
   */
  stop(): void {
    this.isSimulating = false;
    if (this.frameTimer) {
      clearInterval(this.frameTimer);
      this.frameTimer = null;
    }
  }
}
