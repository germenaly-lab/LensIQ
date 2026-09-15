import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/camera.dart';

class StatusBadge extends StatelessWidget {
  final CameraStatus status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case CameraStatus.online:
        bg = AppColors.success.withOpacity(0.15);
        fg = AppColors.success;
        label = 'ONLINE';
        break;
      case CameraStatus.offline:
        bg = AppColors.error.withOpacity(0.15);
        fg = AppColors.error;
        label = 'OFFLINE';
        break;
      case CameraStatus.warning:
        bg = AppColors.warning.withOpacity(0.15);
        fg = AppColors.warning;
        label = 'WARNING';
        break;
      case CameraStatus.unknown:
        bg = AppColors.info.withOpacity(0.15);
        fg = AppColors.info;
        label = 'UNKNOWN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class SourceTypeBadge extends StatelessWidget {
  final CameraSourceType sourceType;

  const SourceTypeBadge({Key? key, required this.sourceType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHik = sourceType == CameraSourceType.hikvisionP2p;
    final color = isHik ? AppColors.hikvisionBadge : AppColors.rtspBadge;
    final label = isHik ? 'HIKVISION P2P' : 'RTSP';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
