import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_util.dart';
import '../core/localization/app_locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'enterprise_sidebar.dart';
import 'notification_bell_widget.dart';
import 'foreground_notification_banner.dart';
import 'language_toggle_button.dart';

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
    final localeProvider = context.watch<AppLocaleProvider>();

    Widget scaffoldContent;

    if (isDesktop) {
      scaffoldContent = Scaffold(
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
                        Text(localeProvider.tr(title), style: AppTypography.h2),
                        const Spacer(),
                        ...?actions,
                        const LanguageToggleButton(),
                        const SizedBox(width: 10),
                        const NotificationBellWidget(),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: localeProvider.tr('Toggle Theme'),
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
    } else {
      // Mobile / Tablet layout
      int currentIndex = 0;
      if (currentRoute == '/cameras') currentIndex = 1;
      if (currentRoute == '/incidents') currentIndex = 2;
      if (currentRoute == '/settings') currentIndex = 3;

      scaffoldContent = Scaffold(
        appBar: AppBar(
          title: Text(localeProvider.tr(title), style: AppTypography.h3),
          actions: [
            ...?actions,
            const LanguageToggleButton(),
            const SizedBox(width: 6),
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
              tooltip: localeProvider.tr('Sign Out'),
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: localeProvider.tr('Overview'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.videocam_outlined),
              selectedIcon: const Icon(Icons.videocam),
              label: localeProvider.tr('Cameras'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_active_outlined),
              selectedIcon: const Icon(Icons.notifications_active),
              label: localeProvider.tr('Incidents'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: localeProvider.tr('Settings'),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: localeProvider.textDirection,
      child: scaffoldContent,
    );
  }
}

