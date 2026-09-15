import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_util.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'enterprise_sidebar.dart';
import 'notification_bell_widget.dart';
import 'foreground_notification_banner.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String title;
  final List<Widget>? actions;

  const ResponsiveScaffold({
    Key? key,
    required this.child,
    required this.currentRoute,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtil.isDesktop(context);
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            EnterpriseSidebar(
              currentRoute: currentRoute,
              onNavigate: (route) => context.go(route),
            ),
            Expanded(
              child: Column(
                children: [
                  // Top Desktop Header Bar
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: Row(
                      children: [
                        Text(title, style: AppTypography.h2),
                        const Spacer(),
                        ...?actions,
                        const NotificationBellWidget(),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'Toggle Theme',
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        child,
                        const ForegroundNotificationBanner(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet layout
    int currentIndex = 0;
    if (currentRoute == '/cameras') currentIndex = 1;
    if (currentRoute == '/incidents') currentIndex = 2;
    if (currentRoute == '/settings') currentIndex = 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.h3),
        actions: [
          ...?actions,
          const NotificationBellWidget(),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Stack(
        children: [
          child,
          const ForegroundNotificationBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/cameras');
              break;
            case 2:
              context.go('/incidents');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Cameras',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
