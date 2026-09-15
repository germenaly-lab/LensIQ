import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class ForegroundNotificationBanner extends StatelessWidget {
  const ForegroundNotificationBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final notification = notifProv.latestForegroundNotification;
    final user = context.watch<AuthProvider>().currentUser;
    final colors = context.colors;

    if (notification == null) return const SizedBox.shrink();

    final isCritical = notification.isCritical;
    final bannerColor = isCritical ? colors.error : colors.warning;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        color: colors.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bannerColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: bannerColor.withOpacity(0.2),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.notifications_active,
                  color: bannerColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr(notification.title),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bannerColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (user != null) {
                    notifProv.markAsRead(user, notification.id);
                  }
                  notifProv.dismissForegroundBanner();
                  context.go('/incidents');
                },
                child: Text(context.tr('Tap to inspect')),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(Icons.close, size: 16, color: colors.textMuted),
                onPressed: () => notifProv.dismissForegroundBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
