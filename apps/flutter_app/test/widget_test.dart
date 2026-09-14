import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lensiq_app/models/user_profile.dart';
import 'package:lensiq_app/models/camera.dart';
import 'package:lensiq_app/services/auth_service.dart';
import 'package:lensiq_app/services/mock_data_service.dart';
import 'package:lensiq_app/repositories/auth_repository.dart';
import 'package:lensiq_app/repositories/camera_repository.dart';
import 'package:lensiq_app/providers/auth_provider.dart';
import 'package:lensiq_app/providers/camera_provider.dart';
import 'package:lensiq_app/providers/theme_provider.dart';
import 'package:lensiq_app/widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 — Flutter App Unit & Widget Tests', () {
    late SharedPreferences prefs;
    late AuthService authService;
    late AuthRepository authRepo;
    late AuthProvider authProvider;
    late CameraRepository cameraRepo;
    late CameraProvider cameraProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authService = AuthService(prefs);
      authRepo = AuthRepository(authService);
      authProvider = AuthProvider(authRepo);
      cameraRepo = CameraRepository();
      cameraProvider = CameraProvider(cameraRepo);
    });

    // ------------------------------------------------------------------------
    // Test 1: Authentication & Role Resolution
    // ------------------------------------------------------------------------
    test('1. Super Admin authentication resolves full permissions and persistence', () async {
      expect(authProvider.isAuthenticated, isFalse);

      final success = await authProvider.login('admin@lensiq.cloud', 'password123');
      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.role, equals(UserRole.superAdmin));
      expect(authProvider.currentUser?.isSuperAdmin, isTrue);

      // Verify persistence in SharedPreferences
      final restored = authService.getPersistedUser();
      expect(restored, isNotNull);
      expect(restored?.email, equals('admin@lensiq.cloud'));
    });

    test('2. Role switching between Super Admin, Brand Manager, and Branch Security', () async {
      // Switch to Brand Manager
      await authProvider.switchDemoRole(UserRole.brandManager);
      expect(authProvider.currentUser?.role, equals(UserRole.brandManager));
      expect(authProvider.currentUser?.isBrandManager, isTrue);
      expect(authProvider.currentUser?.brandName, equals('Ego Fashion'));

      // Switch to Branch Security
      await authProvider.switchDemoRole(UserRole.branchSecurity);
      expect(authProvider.currentUser?.role, equals(UserRole.branchSecurity));
      expect(authProvider.currentUser?.isBranchSecurity, isTrue);
      expect(authProvider.currentUser?.branchName, contains('Mall of Arabia'));

      // Logout clears session
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    // ------------------------------------------------------------------------
    // Test 2: Multi-Source Camera Inventory & Filtering
    // ------------------------------------------------------------------------
    test('3. Loads multi-source cameras and filters by RTSP and Hikvision P2P', () async {
      final user = MockDataService.demoUsers.first; // Super Admin
      await cameraProvider.loadCameras(user);

      expect(cameraProvider.cameras.isNotEmpty, isTrue);
      expect(cameraProvider.totalCamerasCount, greaterThanOrEqualTo(2));
      expect(cameraProvider.rtspCamerasCount, greaterThanOrEqualTo(1));
      expect(cameraProvider.hikvisionCamerasCount, greaterThanOrEqualTo(1));

      // Filter by RTSP only
      cameraProvider.setFilterSource(CameraSourceType.rtsp);
      expect(cameraProvider.cameras.every((c) => c.isRtsp), isTrue);

      // Filter by Hikvision P2P only
      cameraProvider.setFilterSource(CameraSourceType.hikvisionP2p);
      expect(cameraProvider.cameras.every((c) => c.isHikvision), isTrue);

      // Clear filter
      cameraProvider.setFilterSource(null);
      expect(cameraProvider.cameras.length, equals(cameraProvider.totalCamerasCount));
    });

    // ------------------------------------------------------------------------
    // Test 3: Stream Session Initiation via Gateway
    // ------------------------------------------------------------------------
    test('4. Initiates live streaming session and receives sanitized descriptor', () async {
      final user = MockDataService.demoUsers.first;
      final cameraId = '44444444-4444-4444-4444-444444444441'; // Cashier 01

      await cameraProvider.startStream(user, cameraId);
      expect(cameraProvider.activeSession, isNotNull);

      final session = cameraProvider.activeSession!;
      expect(session.cameraId, equals(cameraId));
      expect(session.token, isNotEmpty);
      expect(session.streamUrl, contains(cameraId));
      expect(session.connectionStatus, equals('streaming'));
    });

    // ------------------------------------------------------------------------
    // Test 4: Theme Provider Toggle
    // ------------------------------------------------------------------------
    test('5. ThemeProvider toggles between dark enterprise theme and light mode', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(themeProvider.isDarkMode, isTrue);

      themeProvider.toggleTheme();
      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(themeProvider.isDarkMode, isFalse);

      themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, isTrue);
    });

    // ------------------------------------------------------------------------
    // Test 5: StatusBadge & SourceTypeBadge Widget Tests
    // ------------------------------------------------------------------------
    testWidgets('6. StatusBadge renders ONLINE indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: CameraStatus.online),
          ),
        ),
      );

      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('7. SourceTypeBadge renders HIKVISION P2P badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SourceTypeBadge(sourceType: CameraSourceType.hikvisionP2p),
          ),
        ),
      );

      expect(find.text('HIKVISION P2P'), findsOneWidget);
    });
  });
}
