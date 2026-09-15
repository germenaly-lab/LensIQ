import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/localization/app_locale_provider.dart';
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
    final colors = context.colors;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    // Filter navigation based on user role
    final visibleItems = navItems.where((item) => item.allowedRoles.contains(user.role)).toList();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(
          end: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Brand Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.security_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LensIQ',
                        style: AppTypography.h2Of(context).copyWith(
                          fontSize: 18,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI CCTV PLATFORM',
                        style: AppTypography.captionOf(context).copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),

          // 2. Active User Profile Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: AppTypography.bodyOf(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role, colors).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _getRoleColor(user.role, colors).withOpacity(0.3)),
                  ),
                  child: Text(
                    context.tr(user.role.displayName).toUpperCase(),
                    style: AppTypography.badge.copyWith(
                      color: _getRoleColor(user.role, colors),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 3),
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final isSelected = currentRoute == item.route;

                return Material(
                  color: isSelected ? colors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onNavigate(item.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: isSelected ? colors.primary : colors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr(item.title),
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? (colors.isDark ? colors.textPrimary : colors.primaryDark) : colors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 5,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Quick Role Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PopupMenuButton<UserRole>(
              tooltip: context.tr('Switch Demo Role'),
              onSelected: (role) => authProvider.switchDemoRole(role),
              color: colors.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.border),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('Switch Demo Role'),
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 18, color: colors.textSecondary),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: UserRole.superAdmin,
                  child: Text(
                    context.tr('Super Admin Demo'),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: UserRole.brandManager,
                  child: Text(
                    context.tr('Brand Manager Demo'),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ),
                PopupMenuItem(
                  value: UserRole.branchSecurity,
                  child: Text(
                    context.tr('Branch Security Demo'),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 5. Staff Mobile App Quick Download
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final uri = Uri.parse('/downloads/app-debug.apk');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.secondary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.android, size: 16, color: colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Staff Mobile APK',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.file_download_outlined, size: 16, color: colors.secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 6. Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: () => authProvider.logout(),
              icon: Icon(Icons.logout, size: 15, color: colors.error),
              label: Text(
                context.tr('Sign Out'),
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 34),
                side: BorderSide(color: colors.error.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),

          // 7. Developer Attribution: Developed by POM Agency
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () async {
                final uri = Uri.parse('https://pom-agency.online');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr('Developed by POM Agency'),
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 10, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role, AppSemanticColors colors) {
    switch (role) {
      case UserRole.superAdmin:
        return colors.secondary;
      case UserRole.brandManager:
        return colors.primary;
      case UserRole.branchSecurity:
        return colors.warning;
    }
  }
}
