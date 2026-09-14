import { Camera } from '../../types/camera';
import { VideoSource } from './video-source.interface';
import { RTSPSource } from './rtsp-source';
import { HikvisionP2PSource } from './hikvision-p2p-source';

export class VideoSourceFactory {
  /**
   * Factory method to instantiate the concrete VideoSource implementation
   * according to the camera's source_type.
   */
  static create(camera: Camera): VideoSource {
    switch (camera.source_type) {
      case 'rtsp':
        return new RTSPSource(camera);
      case 'hikvision_p2p':
        return new HikvisionP2PSource(camera);
      default: {
        const unknownType = (camera as { source_type: string }).source_type;
        throw new Error(`Unsupported video source type: '${unknownType}'`);
      }
    }
  }
}
