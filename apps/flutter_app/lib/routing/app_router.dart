import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/companies/companies_screen.dart';
import '../features/brands/brands_screen.dart';
import '../features/branches/branches_screen.dart';
import '../features/cameras/camera_list_screen.dart';
import '../features/cameras/camera_detail_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/incidents/incident_list_screen.dart';
import '../features/users/users_screen.dart';
import '../features/audit/audit_logs_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == AppRoutes.login;

        if (!isAuthenticated) {
          return isLoggingIn ? null : AppRoutes.login;
        }

        if (isLoggingIn) {
          return AppRoutes.dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.companies,
          builder: (context, state) => const CompaniesScreen(),
        ),
        GoRoute(
          path: AppRoutes.brands,
          builder: (context, state) => const BrandsScreen(),
        ),
        GoRoute(
          path: AppRoutes.branches,
          builder: (context, state) => const BranchesScreen(),
        ),
        GoRoute(
          path: AppRoutes.cameras,
          builder: (context, state) => const CameraListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return CameraDetailScreen(cameraId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.rules,
          builder: (context, state) => const RulesScreen(),
        ),
        GoRoute(
          path: AppRoutes.incidents,
          builder: (context, state) => const IncidentListScreen(),
        ),
        GoRoute(
          path: AppRoutes.users,
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: AppRoutes.auditLogs,
          builder: (context, state) => const AuditLogsScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.toString()}'),
        ),
      ),
    );
  }
}
