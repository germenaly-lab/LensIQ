import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/incident.dart';

class SeverityBadge extends StatelessWidget {
  final IncidentSeverity severity;

  const SeverityBadge({Key? key, required this.severity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (severity) {
      case IncidentSeverity.critical:
        bg = AppColors.severityCritical.withOpacity(0.15);
        fg = AppColors.severityCritical;
        label = 'CRITICAL';
        icon = Icons.error_outline;
        break;
      case IncidentSeverity.warning:
        bg = AppColors.severityWarning.withOpacity(0.15);
        fg = AppColors.severityWarning;
        label = 'WARNING';
        icon = Icons.warning_amber_rounded;
        break;
      case IncidentSeverity.info:
        bg = AppColors.severityInfo.withOpacity(0.15);
        fg = AppColors.severityInfo;
        label = 'NOTICE';
        icon = Icons.info_outline;
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
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
