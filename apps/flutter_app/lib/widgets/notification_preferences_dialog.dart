import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/notification_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationPreferencesDialog extends StatefulWidget {
  const NotificationPreferencesDialog({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesDialog> createState() => _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState extends State<NotificationPreferencesDialog> {
  late bool _criticalAlerts;
  late bool _warningAlerts;
  late bool _infoAlerts;
  late bool _cameraOffline;
  late bool _aiEvents;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<NotificationProvider>().preferences;
    _criticalAlerts = prefs.criticalAlerts;
    _warningAlerts = prefs.warningAlerts;
    _infoAlerts = prefs.infoAlerts;
    _cameraOffline = prefs.cameraOffline;
    _aiEvents = prefs.aiEvents;
  }

  void _savePreferences() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final updated = NotificationPreferencesModel(
        criticalAlerts: _criticalAlerts,
        warningAlerts: _warningAlerts,
        infoAlerts: _infoAlerts,
        cameraOffline: _cameraOffline,
        aiEvents: _aiEvents,
      );
      context.read<NotificationProvider>().updatePreferences(user, updated);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppColors.primaryLight, size: 22),
                const SizedBox(width: 10),
                Text('Notification Preferences', style: AppTypography.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Configure which security alerts trigger real-time push notifications to your devices.',
              style: AppTypography.caption,
            ),
            if (user != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'Role Scope: ${user.role.displayName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      user.brandName ?? user.branchName ?? 'Global',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),

            // Toggles
            _buildSwitchTile(
              title: 'Critical Alerts',
              subtitle: 'Cashier empty > 3 mins, perimeter breaches, critical safety events',
              value: _criticalAlerts,
              activeColor: AppColors.error,
              onChanged: (val) => setState(() => _criticalAlerts = val),
            ),
            _buildSwitchTile(
              title: 'High Severity (Warnings)',
              subtitle: 'Loitering, crowd spikes, unattended zones',
              value: _warningAlerts,
              activeColor: AppColors.warning,
              onChanged: (val) => setState(() => _warningAlerts = val),
            ),
            _buildSwitchTile(
              title: 'Informational Notices',
              subtitle: 'Routine shift updates and camera state notices',
              value: _infoAlerts,
              activeColor: AppColors.info,
              onChanged: (val) => setState(() => _infoAlerts = val),
            ),
            _buildSwitchTile(
              title: 'Camera Offline & Network Alerts',
              subtitle: 'Signal lost from RTSP or Hikvision P2P gateways',
              value: _cameraOffline,
              activeColor: AppColors.warning,
              onChanged: (val) => setState(() => _cameraOffline = val),
            ),
            _buildSwitchTile(
              title: 'AI Computer Vision Events',
              subtitle: 'YOLOv8 person detection and ROI rule triggers',
              value: _aiEvents,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _aiEvents = val),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _savePreferences,
                  child: const Text('Save Preferences'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: activeColor,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      value: value,
      onChanged: onChanged,
    );
  }
}
