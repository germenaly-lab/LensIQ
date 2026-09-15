import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final List<UserRole> allowedRoles;

  const NavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.allowedRoles = const [
      UserRole.superAdmin,
      UserRole.brandManager,
      UserRole.branchSecurity,
    ],
  });
}

class EnterpriseSidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String route) onNavigate;

  const EnterpriseSidebar({
    Key? key,
    required this.currentRoute,
    required this.onNavigate,
  }) : super(key: key);

  static const List<NavItem> navItems = [
    NavItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/dashboard',
    ),
    NavItem(
      title: 'Companies',
      icon: Icons.corporate_fare_outlined,
      route: '/companies',
      allowedRoles: [UserRole.superAdmin],
    ),
    NavItem(
      title: 'Brands',
      icon: Icons.store_mall_directory_outlined,
      route: '/brands',
      allowedRoles: [UserRole.superAdmin],
    ),
    NavItem(
      title: 'Branches',
      icon: Icons.storefront_outlined,
      route: '/branches',
      allowedRoles: [UserRole.superAdmin, UserRole.brandManager],
    ),
    NavItem(
      title: 'Cameras',
      icon: Icons.videocam_outlined,
      route: '/cameras',
    ),
    NavItem(
      title: 'AI Rules',
      icon: Icons.tune_outlined,
      route: '/rules',
      allowedRoles: [UserRole.superAdmin, UserRole.brandManager],
    ),
    NavItem(
      title: 'Incidents',
      icon: Icons.notifications_active_outlined,
      route: '/incidents',
    ),
    NavItem(
      title: 'Users',
      icon: Icons.people_outline,
      route: '/users',
      allowedRoles: [UserRole.superAdmin],
    ),
    NavItem(
      title: 'Audit Logs',
      icon: Icons.history_edu_outlined,
      route: '/audit-logs',
      allowedRoles: [UserRole.superAdmin],
    ),
    NavItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    // Filter navigation based on user role
    final visibleItems = navItems.where((item) => item.allowedRoles.contains(user.role)).toList();

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Brand Logo Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LensIQ', style: AppTypography.h2),
                    Text(
                      'AI CCTV PLATFORM',
                      style: AppTypography.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // 2. Active User Profile Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: AppTypography.caption.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.displayName.toUpperCase(),
                    style: AppTypography.badge.copyWith(color: _getRoleColor(user.role), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // 3. Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final isSelected = currentRoute == item.route;

                return Material(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: Icon(
                      item.icon,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.title,
                      style: AppTypography.body.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () => onNavigate(item.route),
                  ),
                );
              },
            ),
          ),

          // 4. Quick Role Switcher (For Pair Programming / Demo Presentations)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: PopupMenuButton<UserRole>(
              tooltip: 'Switch Demo Role',
              onSelected: (role) => authProvider.switchDemoRole(role),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Switch Demo Role',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: UserRole.superAdmin,
                  child: Text('Super Admin (Full Tenant Access)'),
                ),
                const PopupMenuItem(
                  value: UserRole.brandManager,
                  child: Text('Brand Manager (Ego Fashion)'),
                ),
                const PopupMenuItem(
                  value: UserRole.branchSecurity,
                  child: Text('Branch Security (Mall of Arabia)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 5. Staff Mobile App Quick Download
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final uri = Uri.parse('/downloads/app-debug.apk');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.android, size: 16, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Staff Mobile APK',
                        style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.file_download_outlined, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 6. Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: OutlinedButton.icon(
              onPressed: () => authProvider.logout(),
              icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                side: BorderSide(color: AppColors.error.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.secondary;
      case UserRole.brandManager:
        return AppColors.primary;
      case UserRole.branchSecurity:
        return AppColors.warning;
    }
  }
}
