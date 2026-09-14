import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/camera_repository.dart';
import 'repositories/incident_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local persistent storage
  final prefs = await SharedPreferences.getInstance();

  // 2. Initialize Supabase cloud connection (with resilient offline fallback)
  await SupabaseService.initialize();

  // 3. Instantiate core services and repositories
  final apiClient = ApiClient();
  final authService = AuthService(prefs);

  final authRepo = AuthRepository(authService);
  final cameraRepo = CameraRepository(apiClient: apiClient);
  final incidentRepo = IncidentRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => CameraProvider(cameraRepo)),
        ChangeNotifierProvider(create: (_) => IncidentProvider(incidentRepo)),
      ],
      child: const LensIQApp(),
    ),
  );
}

class LensIQApp extends StatelessWidget {
  const LensIQApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'LensIQ - Enterprise AI CCTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}
