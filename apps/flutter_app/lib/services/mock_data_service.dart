import '../models/user_profile.dart';
import '../models/camera.dart';
import '../models/incident.dart';
import '../models/stream_session.dart';
import '../models/dashboard_summary.dart';

class MockDataService {
  // Demo Users
  static final List<UserProfile> demoUsers = [
    const UserProfile(
      id: 'usr-super-admin-01',
      email: 'admin@lensiq.cloud',
      fullName: 'Alex Vance (Super Admin)',
      role: UserRole.superAdmin,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333333', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'],
    ),
    const UserProfile(
      id: 'usr-brand-mgr-01',
      email: 'brand@ego.demo',
      fullName: 'Sara Mansour (Brand Ops)',
      role: UserRole.brandManager,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333333'],
    ),
    const UserProfile(
      id: 'usr-branch-sec-01',
      email: 'security@ego-moa.demo',
      fullName: 'Tamer Galal (MOA Security)',
      role: UserRole.branchSecurity,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      authorizedBranchIds: ['33333333-3333-3333-3333-333333333333'],
    ),
  ];

  // Seed Cameras (from Phase 1 & 3 DB seed)
  static final List<CameraModel> demoCameras = [
    CameraModel(
      id: '44444444-4444-4444-4444-444444444441',
      name: 'Cashier 01',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.online,
      locationDescription: 'Counter 1 - Main Checkout Area',
      rtspUrl: 'rtsp://stream.ego-store.demo/live/cashier01',
      streamProfile: 'main',
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444442',
      name: 'Main Entrance',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      sourceType: CameraSourceType.hikvisionP2p,
      status: CameraStatus.online,
      locationDescription: 'Customer Entrance & Glass Gates',
      hikDeviceId: 'HIK-DS-2CD2143G2-DEMO-01',
      hikSerialNumber: 'D12345678FakeSerial',
      hikChannel: 1,
      streamProfile: 'main',
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 12)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444443',
      name: 'Fitting Rooms Corridor',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.online,
      locationDescription: 'Fitting Rooms Hallway & Staging Zone',
      rtspUrl: 'rtsp://stream.ego-store.demo/live/fitting-corridor',
      streamProfile: 'sub',
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444444',
      name: 'Backstore & Loading Dock',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      sourceType: CameraSourceType.hikvisionP2p,
      status: CameraStatus.degraded,
      locationDescription: 'Service Hallway and Emergency Exit',
      hikDeviceId: 'HIK-BAY-4491-IS',
      hikSerialNumber: 'SER-BAY-99182',
      hikChannel: 2,
      streamProfile: 'sub',
      lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  // Incidents (from Phase 2 AI detection rules: cashier empty, etc.)
  static final List<IncidentModel> demoIncidents = [
    IncidentModel(
      id: 'inc-01',
      cameraId: '44444444-4444-4444-4444-444444444441',
      cameraName: 'Cashier 01',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      ruleType: 'cashier_empty',
      severity: IncidentSeverity.warning,
      status: IncidentStatus.open,
      title: 'Unattended Cashier Counter',
      description: 'Cashier area has been unoccupied for 195 seconds (threshold: 180s). High customer queue forming.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      durationSeconds: 195,
      confidence: 0.94,
    ),
    IncidentModel(
      id: 'inc-02',
      cameraId: '44444444-4444-4444-4444-444444444444',
      cameraName: 'Backstore & Loading Dock',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      ruleType: 'perimeter_breach',
      severity: IncidentSeverity.critical,
      status: IncidentStatus.acknowledged,
      title: 'Restricted Backstore Entry After Hours',
      description: 'Unauthorized person detected inside emergency exit zone outside scheduled shift.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      durationSeconds: 45,
      confidence: 0.98,
    ),
    IncidentModel(
      id: 'inc-03',
      cameraId: '44444444-4444-4444-4444-444444444442',
      cameraName: 'Main Entrance',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia',
      ruleType: 'footfall_spike',
      severity: IncidentSeverity.info,
      status: IncidentStatus.resolved,
      title: 'Footfall Surge Detected',
      description: 'Peak customer inflow exceeding 45 persons/minute recorded at main entrance gate.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      durationSeconds: 300,
      confidence: 0.91,
    ),
  ];

  static DashboardSummary getSummaryForUser(UserProfile user) {
    final cams = getCamerasForUser(user);
    final incs = getIncidentsForUser(user);

    return DashboardSummary(
      totalCameras: cams.length,
      onlineCameras: cams.where((c) => c.isOnline).length,
      offlineCameras: cams.where((c) => !c.isOnline).length,
      activeIncidents: incs.where((i) => i.status == IncidentStatus.open).length,
      criticalAlerts: incs.where((i) => i.isCritical && i.status != IncidentStatus.resolved).length,
      totalBranches: user.isSuperAdmin ? 3 : 1,
      cashierAlerts: incs.where((i) => i.isCashierAlert && i.status == IncidentStatus.open).length,
      networkUptimePercentage: 99.7,
    );
  }

  static List<CameraModel> getCamerasForUser(UserProfile user) {
    if (user.isSuperAdmin) return demoCameras;
    if (user.isBrandManager) {
      return demoCameras.where((c) => c.brandId == user.brandId || user.canAccessBranch(c.branchId)).toList();
    }
    return demoCameras.where((c) => user.canAccessBranch(c.branchId)).toList();
  }

  static List<IncidentModel> getIncidentsForUser(UserProfile user) {
    if (user.isSuperAdmin) return demoIncidents;
    return demoIncidents.where((i) => user.canAccessBranch(i.branchId)).toList();
  }

  static StreamSessionModel createMockStreamSession(String cameraId, CameraSourceType sourceType) {
    final isHik = sourceType == CameraSourceType.hikvisionP2p;
    final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    return StreamSessionModel(
      sessionId: 'sess_${cameraId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}',
      cameraId: cameraId,
      sourceType: sourceType,
      streamUrl: isHik
          ? 'https://stream.lensiq.cloud/api/v1/streams/live/p2p/$cameraId/ch1?token=$token'
          : 'https://stream.lensiq.cloud/api/v1/streams/playback/$cameraId/demo?token=$token',
      token: token,
      protocol: 'webrtc',
      status: 'active',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      viewerCount: 1,
      demoMode: true,
      resolution: '1920x1080',
      fps: 30,
      codec: 'h264',
      latencyMs: isHik ? 85 : 42,
      connectionStatus: 'streaming',
    );
  }
}
