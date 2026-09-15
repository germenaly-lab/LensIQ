import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_preferences_dialog.dart';

class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({Key? key}) : super(key: key);

  void _showNotificationPanel(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          alignment: Alignment.topRight,
          insetPadding: const EdgeInsets.only(top: 60, right: 24, bottom: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        const Icon(Icons.notifications_active, color: AppColors.primaryLight, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Alerts & Notifications',
                                  style: AppTypography.h3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unread NEW',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Preferences Gear Button
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
                          tooltip: 'Notification Preferences',
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
                          icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Actions Bar: Mark All Read
                    if (items.isNotEmpty && unread > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => notifProv.markAllAsRead(user),
                          icon: const Icon(Icons.done_all, size: 14, color: AppColors.primaryLight),
                          label: const Text(
                            'Mark all as read',
                            style: TextStyle(fontSize: 11, color: AppColors.primaryLight),
                          ),
                        ),
                      ),

                    const Divider(height: 12),

                    // Notifications List
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications_none, size: 40, color: Colors.white24),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No security notifications',
                                    style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'All surveillance zones operating normally',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 8, color: Colors.white10),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _NotificationListTile(
                                  item: item,
                                  onTap: () {
                                    // 1. Mark as read
                                    notifProv.markAsRead(user, item.id);
                                    // 2. Dismiss panel
                                    Navigator.of(ctx).pop();
                                    // 3. Navigate to corresponding incident!
                                    context.go('/incidents');
                                  },
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
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 20),
          tooltip: 'Security Notifications ($unreadCount)',
          onPressed: () => _showNotificationPanel(context),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color iconColor = item.isCritical
        ? AppColors.error
        : (item.isWarning ? AppColors.warning : AppColors.info);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.transparent : AppColors.surfaceLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: item.isRead
              ? null
              : Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
                color: iconColor,
                size: 16,
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
                          item.title,
                          style: TextStyle(
                            color: item.isRead ? Colors.white70 : Colors.white,
                            fontSize: 12,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(item.sentAt),
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to inspect',
                        style: TextStyle(
                          color: AppColors.primaryLight.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
