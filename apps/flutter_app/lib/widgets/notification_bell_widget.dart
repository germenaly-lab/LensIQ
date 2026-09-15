import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/localization/app_locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_preferences_dialog.dart';

class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({Key? key}) : super(key: key);

  void _showNotificationPanel(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final colors = context.colors;
    final isAr = context.isArabic;
    if (user == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          alignment: isAr ? Alignment.topLeft : Alignment.topRight,
          insetPadding: EdgeInsets.only(
            top: 60,
            right: isAr ? 0 : 24,
            left: isAr ? 24 : 0,
            bottom: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 520),
            padding: const EdgeInsets.all(16),
            child: Consumer<NotificationProvider>(
              builder: (context, notifProv, child) {
                final items = notifProv.notifications;
                final unread = notifProv.unreadCount;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel Header
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.tr('Alerts & Notifications'),
                                  style: AppTypography.h3Of(context).copyWith(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unread ${context.tr("Active")}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Preferences Gear Button
                        IconButton(
                          icon: Icon(Icons.settings_outlined, size: 18, color: colors.textSecondary),
                          tooltip: context.tr('Configure Preferences'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              builder: (_) => const NotificationPreferencesDialog(),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        // Close
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: colors.textSecondary),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Actions Bar: Mark All Read
                    if (items.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${items.length} ${context.tr("Notifications")}',
                            style: TextStyle(fontSize: 11, color: colors.textMuted),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => notifProv.markAllAsRead(user),
                            child: Text(
                              context.tr('Mark all as read'),
                              style: TextStyle(fontSize: 11, color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                    Divider(height: 12, color: colors.borderSubtle),

                    // Notifications List
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_none, size: 36, color: colors.textMuted),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('No new notifications'),
                                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => Divider(height: 8, color: colors.borderSubtle),
                              itemBuilder: (context, index) {
                                final notif = items[index];
                                final isCrit = notif.isCritical;
                                final itemColor = isCrit ? colors.error : colors.warning;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    notifProv.markAsRead(user, notif.id);
                                    Navigator.of(ctx).pop();
                                    context.go('/incidents');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: notif.isRead ? Colors.transparent : colors.primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: itemColor.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCrit ? Icons.warning_amber_rounded : Icons.notifications,
                                            size: 14,
                                            color: itemColor,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notif.title,
                                                      style: TextStyle(
                                                        color: colors.textPrimary,
                                                        fontSize: 12,
                                                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (!notif.isRead)
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: colors.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                notif.body,
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                context.tr('Tap to inspect'),
                                                style: TextStyle(
                                                  color: colors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final unreadCount = notifProv.unreadCount;
    final colors = context.colors;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
            size: 20,
            color: unreadCount > 0 ? colors.warning : colors.textSecondary,
          ),
          tooltip: context.tr('Alerts & Notifications'),
          onPressed: () => _showNotificationPanel(context),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
