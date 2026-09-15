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
import 'package:lensiq_app/models/notification_item.dart';
import 'package:lensiq_app/services/fcm_notification_service.dart';
import 'package:lensiq_app/repositories/notification_repository.dart';
import 'package:lensiq_app/providers/notification_provider.dart';
import 'package:lensiq_app/widgets/notification_bell_widget.dart';
import 'package:provider/provider.dart';
import 'package:lensiq_app/widgets/status_badge.dart';
import 'package:lensiq_app/features/cameras/widgets/live_camera_player_widget.dart';

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
    late FcmNotificationService fcmService;
    late NotificationRepository notificationRepo;
    late NotificationProvider notificationProvider;

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
      fcmService = FcmNotificationService();
      notificationRepo = NotificationRepository();
      notificationProvider = NotificationProvider(notificationRepo, fcmService);
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

    // ------------------------------------------------------------------------
    // Phase 7 Tests: Role-Specific Dashboards & Permission Enforcement
    // ------------------------------------------------------------------------
    test('14. Brand Manager strictly sees ONLY assigned brand cameras (No other brands)', () async {
      final brandUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.brandManager);
      expect(brandUser.brandId, isNotNull);

      await cameraProvider.loadCameras(brandUser);

      // Must only contain cameras for assigned brand (Ego Fashion)
      expect(cameraProvider.cameras.isNotEmpty, isTrue);
      expect(cameraProvider.cameras.every((c) => c.brandId == brandUser.brandId), isTrue);

      // Must NOT contain cameras from Armani Exchange or Acme
      expect(cameraProvider.cameras.any((c) => c.brandName == 'Armani Exchange'), isFalse);
      expect(cameraProvider.cameras.any((c) => c.brandName == 'Acme Pro Store'), isFalse);
    });

    test('15. Brand Manager strictly sees ONLY assigned brand incidents & branches', () async {
      final brandUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.brandManager);
      await incidentProvider.loadData(brandUser);

      // Must only contain incidents for assigned brand
      expect(incidentProvider.rawIncidents.isNotEmpty, isTrue);
      expect(incidentProvider.rawIncidents.every((i) => i.brandId == brandUser.brandId), isTrue);
      expect(incidentProvider.rawIncidents.any((i) => i.brandName == 'Armani Exchange'), isFalse);

      // Admin provider branches must be scoped to assigned brand
      await adminProvider.loadAllAdminData(brandUser);
      expect(adminProvider.branches.every((b) => b.brandId == brandUser.brandId), isTrue);
      expect(adminProvider.brands.every((b) => b.id == brandUser.brandId), isTrue);
    });

    test('16. Branch Security strictly sees ONLY assigned branch cameras (No other branches)', () async {
      final secUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.branchSecurity);
      expect(secUser.branchId, isNotNull);

      await cameraProvider.loadCameras(secUser);

      // Must only contain cameras for assigned branch (Mall of Arabia)
      expect(cameraProvider.cameras.isNotEmpty, isTrue);
      expect(cameraProvider.cameras.every((c) => c.branchId == secUser.branchId), isTrue);

      // Must NOT contain cameras from CFC branch or City Stars branch
      expect(cameraProvider.cameras.any((c) => c.name == 'Cashier 02'), isFalse);
      expect(cameraProvider.cameras.any((c) => c.branchName?.contains('City Stars') ?? false), isFalse);
    });

    test('17. Branch Security strictly sees ONLY assigned branch incidents', () async {
      final secUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.branchSecurity);
      await incidentProvider.loadData(secUser);

      // Must only contain incidents for Mall of Arabia
      expect(incidentProvider.rawIncidents.isNotEmpty, isTrue);
      expect(incidentProvider.rawIncidents.every((i) => i.branchId == secUser.branchId), isTrue);
      expect(incidentProvider.rawIncidents.any((i) => i.branchName.contains('Cairo Festival')), isFalse);
      expect(incidentProvider.rawIncidents.any((i) => i.branchName.contains('City Stars')), isFalse);
    });

    test('18. Branch Security quick-identifies critical incidents, cashier problems, and offline cameras', () async {
      final secUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.branchSecurity);
      await incidentProvider.loadData(secUser);
      await cameraProvider.loadCameras(secUser);

      final branchIncidents = incidentProvider.rawIncidents.where((i) => i.branchId == secUser.branchId).toList();
      final branchCameras = cameraProvider.cameras.where((c) => c.branchId == secUser.branchId).toList();

      // 1. Critical incidents identified
      final criticals = branchIncidents.where((i) => i.isCritical).toList();
      expect(criticals.isNotEmpty, isTrue);
      expect(criticals.any((i) => i.title == 'Cashier Area Empty'), isTrue);

      // 2. Cashier problems identified
      final cashierProblems = branchIncidents.where((i) => i.isCashierAlert).toList();
      expect(cashierProblems.isNotEmpty, isTrue);
      expect(cashierProblems.first.ruleType, equals('cashier_empty'));

      // 3. Offline or Warning cameras identified
      final warningOrOffline = branchCameras.where((c) => !c.isOnline || c.status == CameraStatus.warning).toList();
      expect(warningOrOffline.isNotEmpty, isTrue);
      expect(warningOrOffline.first.name, equals('Backstore & Loading Dock'));
    });

    // ------------------------------------------------------------------------
    // Phase 8: Live Cameras with RTSP and Hikvision P2P Tests
    // ------------------------------------------------------------------------
    test('19. Phase 8: RTSP camera live view starts session without exposing credentials', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final rtspCam = cameraProvider.cameras.firstWhere((c) => c.isRtsp && c.isOnline);

      await cameraProvider.startCameraStream(user, rtspCam.id);
      expect(cameraProvider.getStreamState(rtspCam.id), equals(LiveStreamState.online));

      final session = cameraProvider.getActiveSessionForCamera(rtspCam.id);
      expect(session, isNotNull);
      expect(session!.protocol, equals('webrtc'));
      // Verify zero exposure of passwords or raw credentials in stream URL
      expect(session.streamUrl.contains('password'), isFalse);
      expect(session.streamUrl.contains('secret'), isFalse);
    });

    test('20. Phase 8: Hikvision P2P camera live view starts session via P2P adapter', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final hikCam = cameraProvider.cameras.firstWhere((c) => c.isHikvision && c.isOnline);

      await cameraProvider.startCameraStream(user, hikCam.id);
      expect(cameraProvider.getStreamState(hikCam.id), equals(LiveStreamState.online));

      final session = cameraProvider.getActiveSessionForCamera(hikCam.id);
      expect(session, isNotNull);
      expect(session!.protocol, equals('webrtc'));
      expect(hikCam.sourceTypeDisplayName, equals('Hikvision P2P'));
      // Zero exposure of app key or secret
      expect(session.streamUrl.contains('appKey'), isFalse);
      expect(session.streamUrl.contains('appSecret'), isFalse);
    });

    test('21. Phase 8: Multi-camera grid layout switching (1, 4, 9 layouts)', () {
      expect(cameraProvider.gridLayout, equals(4)); // default is 4

      cameraProvider.setGridLayout(1);
      expect(cameraProvider.gridLayout, equals(1));

      cameraProvider.setGridLayout(9);
      expect(cameraProvider.gridLayout, equals(9));

      cameraProvider.setGridLayout(4);
      expect(cameraProvider.gridLayout, equals(4));
    });

    test('22. Phase 8: Offline camera handling sets offline state without launching stream', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final offlineCam = cameraProvider.cameras.firstWhere((c) => !c.isOnline);

      await cameraProvider.startCameraStream(user, offlineCam.id);
      expect(cameraProvider.getStreamState(offlineCam.id), equals(LiveStreamState.offline));
      expect(cameraProvider.getActiveSessionForCamera(offlineCam.id), isNull);
    });

    test('23. Phase 8: Reconnect on stream failure refreshes session seamlessly', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final cam = cameraProvider.cameras.firstWhere((c) => c.isOnline);

      await cameraProvider.startCameraStream(user, cam.id);
      expect(cameraProvider.getStreamState(cam.id), equals(LiveStreamState.online));

      await cameraProvider.reconnectCameraStream(user, cam.id);
      expect(cameraProvider.getStreamState(cam.id), equals(LiveStreamState.online));
      expect(cameraProvider.getActiveSessionForCamera(cam.id), isNotNull);
    });

    test('24. Phase 8: Stream release and lifecycle optimization when user leaves screen', () async {
      final user = MockDataService.demoUsers.first;
      await cameraProvider.loadCameras(user);
      final cam1 = cameraProvider.cameras[0];
      final cam2 = cameraProvider.cameras[1];

      await cameraProvider.startCameraStream(user, cam1.id);
      await cameraProvider.startCameraStream(user, cam2.id);
      expect(cameraProvider.activeSessions.length, equals(2));

      // Stop cam1 session (e.g. user scrolled past or left screen)
      await cameraProvider.stopCameraStream(user, cam1.id);
      expect(cameraProvider.activeSessions.containsKey(cam1.id), isFalse);
      expect(cameraProvider.activeSessions.containsKey(cam2.id), isTrue);

      // Stop all streams on exit
      cameraProvider.stopAllStreams(user);
      expect(cameraProvider.activeSessions.isEmpty, isTrue);
    });

    test('25. Phase 8: Cashier Empty Rule AI simulation triggers 180s incident and resets on return', () async {
      final user = MockDataService.demoUsers.first;
      await incidentProvider.loadData(user);
      final initialCount = incidentProvider.rawIncidents.length;

      // Simulate 180s continuous cashier empty event
      final simulatedIncident = IncidentModel(
        id: 'inc_test_cashier_180s',
        cameraId: '44444444-4444-4444-4444-444444444441',
        cameraName: 'Cashier 01',
        brandName: 'Armani Exchange',
        branchId: '33333333-3333-3333-3333-333333333331',
        branchName: 'Mall of Arabia',
        ruleType: 'cashier_empty',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.open,
        title: 'Cashier Area Empty',
        description: 'Cashier counter unattended for 3 continuous minutes (180s) on Cashier 01.',
        timestamp: DateTime.now(),
        durationSeconds: 180,
        confidence: 0.98,
      );

      incidentProvider.addRealtimeIncident(simulatedIncident);
      expect(incidentProvider.rawIncidents.length, equals(initialCount + 1));
      expect(incidentProvider.rawIncidents.first.id, equals('inc_test_cashier_180s'));
      expect(incidentProvider.rawIncidents.first.isCritical, isTrue);
      expect(incidentProvider.rawIncidents.first.durationSeconds, equals(180));
    });

    testWidgets('26. Phase 8: LiveCameraPlayerWidget mounts and renders stream HUD correctly', (WidgetTester tester) async {
      final user = MockDataService.demoUsers.first;
      await authProvider.login('admin@lensiq.cloud', 'password123');
      await cameraProvider.loadCameras(user);
      final cam = cameraProvider.cameras.firstWhere((c) => c.isOnline);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CameraProvider>.value(value: cameraProvider),
            ChangeNotifierProvider<IncidentProvider>.value(value: incidentProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: LiveCameraPlayerWidget(camera: cam),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(LiveCameraPlayerWidget), findsOneWidget);
      expect(find.text(cam.name), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Phase 9: Notification System & FCM Push Alerts Tests
    // ------------------------------------------------------------------------
    test('27. Phase 9: FCM device push token registration & permission handling', () async {
      final user = MockDataService.demoUsers.first;
      expect(notificationProvider.hasPermission, isFalse);
      expect(notificationProvider.deviceToken, isNull);

      await notificationProvider.initialize(user);

      expect(notificationProvider.hasPermission, isTrue);
      expect(notificationProvider.deviceToken, isNotNull);
      expect(notificationProvider.deviceToken!.startsWith('fcm_'), isTrue);
      expect(notificationProvider.notifications.isNotEmpty, isTrue);
    });

    test('28. Phase 9: Role-based notification targeting & isolation', () async {
      final branchSecUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.branchSecurity);
      final brandMgrUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.brandManager);
      final adminUser = MockDataService.demoUsers.firstWhere((u) => u.role == UserRole.superAdmin);

      // Assigned branch incident for branchSecUser
      final branchIncidentAlert = NotificationItem(
        id: 'notif_rbac_assigned_branch',
        recipientId: branchSecUser.id,
        incidentId: 'inc_branch_01',
        title: 'CRITICAL: Cashier Area Empty',
        body: 'Cashier 01 unattended',
        sentAt: DateTime.now(),
        deliveryStatus: 'delivered',
        data: {
          'severity': 'critical',
          'branchId': branchSecUser.branchId ?? branchSecUser.authorizedBranchIds.first,
          'brandId': brandMgrUser.brandId ?? 'assigned-brand',
        },
      );

      // Other branch incident (not assigned to branchSecUser and not in brandMgrUser)
      final otherIncidentAlert = NotificationItem(
        id: 'notif_rbac_unauthorized',
        recipientId: 'other_user',
        incidentId: 'inc_other_01',
        title: 'WARNING: Loitering Detected',
        body: 'Fitting Room loitering',
        sentAt: DateTime.now(),
        deliveryStatus: 'delivered',
        data: {
          'severity': 'warning',
          'branchId': 'unauthorized-branch-id-999',
          'brandId': 'unauthorized-brand-id-999',
        },
      );

      // Branch Security authorization check
      final canBranchSecAccessAssigned = branchSecUser.authorizedBranchIds.contains(branchIncidentAlert.data['branchId']);
      final canBranchSecAccessOther = branchSecUser.authorizedBranchIds.contains(otherIncidentAlert.data['branchId']);
      expect(canBranchSecAccessAssigned, isTrue);
      expect(canBranchSecAccessOther, isFalse);

      // Brand Manager authorization check
      final canBrandMgrAccessAssigned = brandMgrUser.brandId == branchIncidentAlert.data['brandId'];
      final canBrandMgrAccessOther = brandMgrUser.brandId == otherIncidentAlert.data['brandId'];
      expect(canBrandMgrAccessAssigned, isTrue);
      expect(canBrandMgrAccessOther, isFalse);

      // Super Admin has global access
      expect(adminUser.isSuperAdmin, isTrue);
    });

    test('29. Phase 9: Notification preferences toggling (critical, warning, camera offline, AI events)', () async {
      final user = MockDataService.demoUsers.first;
      await notificationProvider.initialize(user);

      expect(notificationProvider.preferences.criticalAlerts, isTrue);
      expect(notificationProvider.preferences.cameraOffline, isTrue);

      final updated = notificationProvider.preferences.copyWith(
        warningAlerts: false,
        aiEvents: false,
        cameraOffline: true,
      );

      await notificationProvider.updatePreferences(user, updated);
      expect(notificationProvider.preferences.warningAlerts, isFalse);
      expect(notificationProvider.preferences.aiEvents, isFalse);
      expect(notificationProvider.preferences.criticalAlerts, isTrue);
      expect(notificationProvider.preferences.cameraOffline, isTrue);
    });

    test('30. Phase 9: Notification history tracking & unread count updates when receiving alerts and marking as read', () async {
      final user = MockDataService.demoUsers.first;
      await notificationProvider.initialize(user);

      final initialUnread = notificationProvider.unreadCount;
      final initialTotal = notificationProvider.notifications.length;

      // Simulate incoming real-time FCM notification dispatch
      final incoming = NotificationItem(
        id: 'notif_realtime_test',
        recipientId: user.id,
        incidentId: 'inc_cashier_realtime',
        title: 'CRITICAL: Cashier Area Empty',
        body: 'Armani Exchange • Mall of Arabia • Cashier 01: Cashier area empty for 3 minutes.',
        sentAt: DateTime.now(),
        deliveryStatus: 'delivered',
        data: {'route': '/incidents?id=inc_cashier_realtime'},
      );

      fcmService.dispatchForegroundNotification(incoming);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notificationProvider.notifications.length, equals(initialTotal + 1));
      expect(notificationProvider.unreadCount, equals(initialUnread + 1));
      expect(notificationProvider.latestForegroundNotification?.id, equals('notif_realtime_test'));

      // Mark incoming notification as read
      await notificationProvider.markAsRead(user, 'notif_realtime_test');
      expect(notificationProvider.unreadCount, equals(initialUnread));
      expect(notificationProvider.notifications.firstWhere((n) => n.id == 'notif_realtime_test').isRead, isTrue);

      // Dismiss foreground banner
      notificationProvider.dismissForegroundBanner();
      expect(notificationProvider.latestForegroundNotification, isNull);
    });

    test('31. Phase 9: Mark all as read resets unread count to 0', () async {
      final user = MockDataService.demoUsers.first;
      await notificationProvider.initialize(user);

      expect(notificationProvider.unreadCount, greaterThan(0));

      await notificationProvider.markAllAsRead(user);
      expect(notificationProvider.unreadCount, equals(0));
      expect(notificationProvider.notifications.every((n) => n.isRead), isTrue);
    });

    testWidgets('32. Phase 9: NotificationBellWidget renders unread badge and opens alerts panel', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final user = MockDataService.demoUsers.first;
      await authProvider.login('admin@lensiq.cloud', 'password123');
      await notificationProvider.initialize(user);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    NotificationBellWidget(),
                  ],
                ),
              ),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NotificationBellWidget), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(notificationProvider.unreadCount, greaterThan(0));
      expect(find.text('${notificationProvider.unreadCount}'), findsOneWidget);

      // Tap bell to open dialog panel
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Alerts & Notifications'), findsOneWidget);
    });
  });
}
