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
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final localeProvider = context.watch<AppLocaleProvider>();
    final user = authProvider.currentUser;

    Widget scaffoldContent;

    if (isDesktop) {
      scaffoldContent = Scaffold(
        backgroundColor: colors.background,
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
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        bottom: BorderSide(color: colors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Title and Live Pulse Badge
                        Row(
                          children: [
                            Text(
                              context.tr(title),
                              style: AppTypography.h2Of(context).copyWith(fontSize: 18),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.success.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('System Operational'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: colors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Optional custom action buttons
                        ...?actions,

                        const SizedBox(width: 8),

                        // Language Toggle
                        const LanguageToggleButton(),

                        const SizedBox(width: 8),

                        // Notification Bell
                        const NotificationBellWidget(),

                        const SizedBox(width: 4),

                        // Dark/Light Theme Toggle
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                          tooltip: context.tr('Toggle Theme'),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),

                        const SizedBox(width: 8),

                        // User Profile Pill in Header
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: colors.primaryContainer,
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Main Content Viewport
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

      final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

      scaffoldContent = Scaffold(
        key: scaffoldKey,
        backgroundColor: colors.background,
        drawer: Drawer(
          backgroundColor: colors.surface,
          child: SafeArea(
            child: EnterpriseSidebar(
              currentRoute: currentRoute,
              onNavigate: (route) {
                Navigator.of(context).pop(); // Close drawer
                context.go(route);
              },
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            context.tr(title),
            style: AppTypography.h3Of(context).copyWith(fontSize: 16),
          ),
          actions: [
            ...?actions,
            const LanguageToggleButton(),
            const SizedBox(width: 4),
            const NotificationBellWidget(),
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
              tooltip: context.tr('Toggle Theme'),
              onPressed: () => themeProvider.toggleTheme(),
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
          backgroundColor: colors.surface,
          indicatorColor: colors.primaryContainer,
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
              icon: Icon(Icons.dashboard_outlined, color: colors.textSecondary),
              selectedIcon: Icon(Icons.dashboard, color: colors.primary),
              label: context.tr('Overview'),
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam_outlined, color: colors.textSecondary),
              selectedIcon: Icon(Icons.videocam, color: colors.primary),
              label: context.tr('Cameras'),
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_active_outlined, color: colors.textSecondary),
              selectedIcon: Icon(Icons.notifications_active, color: colors.primary),
              label: context.tr('Incidents'),
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
              selectedIcon: Icon(Icons.settings, color: colors.primary),
              label: context.tr('Settings'),
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
