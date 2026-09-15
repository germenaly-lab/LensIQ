import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lensiq_app/models/user_profile.dart';
import 'package:lensiq_app/models/camera.dart';
import 'package:lensiq_app/models/incident.dart';
import 'package:lensiq_app/models/ai_rule.dart';
import 'package:lensiq_app/models/roi.dart';
import 'package:lensiq_app/services/auth_service.dart';
import 'package:lensiq_app/services/mock_data_service.dart';
import 'package:lensiq_app/repositories/auth_repository.dart';
import 'package:lensiq_app/repositories/camera_repository.dart';
import 'package:lensiq_app/repositories/incident_repository.dart';
import 'package:lensiq_app/providers/auth_provider.dart';
import 'package:lensiq_app/providers/camera_provider.dart';
import 'package:lensiq_app/providers/incident_provider.dart';
import 'package:lensiq_app/providers/admin_provider.dart';
import 'package:lensiq_app/providers/theme_provider.dart';
import 'package:lensiq_app/widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LensIQ Enterprise Monitoring Suite Tests', () {
    late SharedPreferences prefs;
    late AuthService authService;
    late AuthRepository authRepo;
    late AuthProvider authProvider;
    late CameraRepository cameraRepo;
    late CameraProvider cameraProvider;
    late IncidentRepository incidentRepo;
    late IncidentProvider incidentProvider;
    late AdminProvider adminProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      authService = AuthService(prefs);
      authRepo = AuthRepository(authService);
      authProvider = AuthProvider(authRepo);
      cameraRepo = CameraRepository();
      cameraProvider = CameraProvider(cameraRepo);
      incidentRepo = IncidentRepository();
      incidentProvider = IncidentProvider(incidentRepo);
      adminProvider = AdminProvider();
    });

    // ------------------------------------------------------------------------
    // Test 1: Authentication & RBAC
    // ------------------------------------------------------------------------
    test('1. Super Admin authentication resolves full permissions and persistence', () async {
      final success = await authProvider.login('admin@lensiq.cloud', 'password123');
      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.isSuperAdmin, isTrue);
      expect(authProvider.currentUser!.authorizedBranchIds.length, greaterThanOrEqualTo(2));
    });

    test('2. Role switching between Super Admin, Brand Manager, and Branch Security', () async {
      await authProvider.login('admin@lensiq.cloud', 'password123');
      expect(authProvider.currentUser!.role, equals(UserRole.superAdmin));

      await authProvider.switchDemoRole(UserRole.brandManager);
      expect(authProvider.currentUser!.role, equals(UserRole.brandManager));
      expect(authProvider.currentUser!.brandName, isNotNull);

      await authProvider.switchDemoRole(UserRole.branchSecurity);
      expect(authProvider.currentUser!.role, equals(UserRole.branchSecurity));
      expect(authProvider.currentUser!.branchName, isNotNull);
    });

    // ------------------------------------------------------------------------
    // Test 2: Camera Multi-Source Filtering
    // ------------------------------------------------------------------------
    test('3. Loads multi-source cameras and filters by RTSP and Hikvision P2P', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);

      expect(cameraProvider.totalCamerasCount, greaterThan(0));
      expect(cameraProvider.rtspCamerasCount, greaterThan(0));
      expect(cameraProvider.hikvisionCamerasCount, greaterThan(0));

      cameraProvider.setFilterSource(CameraSourceType.rtsp);
      expect(cameraProvider.cameras.every((c) => c.isRtsp), isTrue);

      cameraProvider.setFilterSource(CameraSourceType.hikvisionP2p);
      expect(cameraProvider.cameras.every((c) => c.isHikvision), isTrue);

      cameraProvider.setFilterSource(null);
      expect(cameraProvider.cameras.length, equals(cameraProvider.totalCamerasCount));
    });

    // ------------------------------------------------------------------------
    // Test 3: Stream Session Initiation
    // ------------------------------------------------------------------------
    test('4. Initiates live streaming session and receives sanitized descriptor', () async {
      final user = MockDataService.demoUsers.first;
      final cameraId = '44444444-4444-4444-4444-444444444441';

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
    // Test 5: StatusBadge & SourceTypeBadge Widgets
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

    // ------------------------------------------------------------------------
    // Test 6: Camera Provisioning (Add Camera)
    // ------------------------------------------------------------------------
    test('8. Provisions new camera and prepends it to the camera inventory', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final initialCount = cameraProvider.totalCamerasCount;

      final newCam = CameraModel(
        id: 'new-test-cam-999',
        name: 'Drive-Thru Test Cam',
        companyId: user.companyId ?? '11111111-1111-1111-1111-111111111111',
        brandId: user.brandId ?? '22222222-2222-2222-2222-222222222222',
        branchId: user.branchId ?? '33333333-3333-3333-3333-333333333333',
        sourceType: CameraSourceType.rtsp,
        status: CameraStatus.online,
        streamProfile: 'main',
        rtspUrl: 'rtsp://test.local/ch1',
      );

      await cameraProvider.addCamera(user, newCam);
      expect(cameraProvider.totalCamerasCount, equals(initialCount + 1));
      expect(cameraProvider.cameras.first.id, equals('new-test-cam-999'));
    });

    // ------------------------------------------------------------------------
    // Phase 6 Tests
    // ------------------------------------------------------------------------
    test('9. Super Admin acknowledges, resolves, and flags false positive incidents', () async {
      final user = MockDataService.demoUsers.first;
      await incidentProvider.loadData(user);

      expect(incidentProvider.incidents.isNotEmpty, isTrue);
      final target = incidentProvider.incidents.first;

      // Acknowledge
      incidentProvider.acknowledgeIncident(target.id);
      final acknowledged = incidentProvider.rawIncidents.firstWhere((i) => i.id == target.id);
      expect(acknowledged.status, equals(IncidentStatus.acknowledged));

      // Resolve
      incidentProvider.resolveIncident(target.id, 'Cashier returned to counter');
      final resolved = incidentProvider.rawIncidents.firstWhere((i) => i.id == target.id);
      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolutionNote, equals('Cashier returned to counter'));

      // False Positive
      incidentProvider.markFalsePositive(target.id);
      final falsePos = incidentProvider.rawIncidents.firstWhere((i) => i.id == target.id);
      expect(falsePos.status, equals(IncidentStatus.falsePositive));
    });

    test('10. Camera Health filtering by brand, branch, and status', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);

      expect(cameraProvider.onlineCount, greaterThan(0));
      expect(cameraProvider.availabilityPercentage, greaterThan(50.0));

      cameraProvider.setHealthStatusFilter(CameraStatus.online);
      expect(cameraProvider.healthFilteredCameras.every((c) => c.status == CameraStatus.online), isTrue);

      cameraProvider.clearHealthFilters();
      cameraProvider.setHealthBrandFilter('Armani');
      expect(cameraProvider.healthFilteredCameras.every((c) => c.brandName?.contains('Armani') ?? false), isTrue);

      cameraProvider.clearHealthFilters();
      expect(cameraProvider.healthFilteredCameras.length, equals(cameraProvider.totalCamerasCount));
    });

    test('11. AI Detection Rule management: create, update, and enable/disable toggle', () {
      final initialCount = adminProvider.totalRulesCount;

      final newRule = const AiRuleModel(
        id: 'test-rule-101',
        name: 'VIP Customer Service Rule',
        ruleType: 'occupancy_limit',
        durationSeconds: 120,
        minPeople: 3,
        severity: IncidentSeverity.info,
        cameraId: '44444444-4444-4444-4444-444444444441',
        cameraName: 'Cashier 01',
        branchId: '33333333-3333-3333-3333-333333333333',
        branchName: 'Ego Mall of Arabia Branch',
      );

      adminProvider.addRule(newRule);
      expect(adminProvider.totalRulesCount, equals(initialCount + 1));
      expect(adminProvider.rules.first.id, equals('test-rule-101'));

      // Toggle enable/disable
      final wasEnabled = adminProvider.rules.first.enabled;
      adminProvider.toggleRuleEnabled('test-rule-101');
      expect(adminProvider.rules.first.enabled, equals(!wasEnabled));
    });

    test('12. ROI Polygon Point normalization and coordinate conversion', () {
      const point = RoiPoint(x: 0.5, y: 0.5);
      const canvasSize = Size(800, 600);

      final offset = point.toOffset(canvasSize);
      expect(offset.dx, equals(400.0));
      expect(offset.dy, equals(300.0));

      final convertedBack = RoiPoint.fromOffset(offset, canvasSize);
      expect(convertedBack.x, equals(0.5));
      expect(convertedBack.y, equals(0.5));
    });

    test('13. Real-Time Incident addition updates live summary counts without page refresh', () async {
      final user = MockDataService.demoUsers.first;
      await incidentProvider.loadData(user);
      final activeBefore = incidentProvider.activeIncidentsCount;

      final realTimeIncident = IncidentModel(
        id: 'realtime-inc-${DateTime.now().millisecondsSinceEpoch}',
        cameraId: '44444444-4444-4444-4444-444444444441',
        cameraName: 'Cashier 01',
        brandName: 'Armani Exchange',
        branchId: '33333333-3333-3333-3333-333333333333',
        branchName: 'Ego Mall of Arabia Branch',
        ruleType: 'cashier_empty',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.open,
        title: 'Real-time Cashier Empty Alert',
        description: 'No operator detected at checkout counter.',
        timestamp: DateTime.now(),
        durationSeconds: 185,
        confidence: 0.99,
      );

      incidentProvider.addRealtimeIncident(realTimeIncident);
      expect(incidentProvider.activeIncidentsCount, equals(activeBefore + 1));
      expect(incidentProvider.incidents.first.id, equals(realTimeIncident.id));
    });
  });
}
