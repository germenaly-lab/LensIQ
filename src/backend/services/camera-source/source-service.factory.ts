import { CameraSourceType } from '../../../types/camera';
import { ICameraSourceService } from './camera-source.interface';
import { RTSPSourceService } from './rtsp-source.service';
import { HikvisionP2PSourceService } from './hikvision-p2p-source.service';

export class SourceServiceFactory {
  private static rtspService = new RTSPSourceService();
  private static hikvisionService = new HikvisionP2PSourceService();

  /**
   * Returns the registered service adapter for the given source type.
   */
  static getService(sourceType: CameraSourceType): ICameraSourceService {
    switch (sourceType) {
      case 'rtsp':
        return this.rtspService;
      case 'hikvision_p2p':
        return this.hikvisionService;
      default:
        throw new Error(`Unsupported camera source type: '${sourceType}'`);
    }
  }
}
