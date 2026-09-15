import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/camera.dart';
import '../models/incident.dart';
import '../models/stream_session.dart';
import '../models/dashboard_summary.dart';
import '../models/company.dart';
import '../models/brand.dart';
import '../models/branch.dart';
import '../models/ai_rule.dart';
import '../models/audit_log.dart';
import '../models/roi.dart';

class MockDataService {
  // 1. Companies
  static final List<CompanyModel> demoCompanies = [
    CompanyModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Ego Retail Holding',
      slug: 'ego-holding',
      brandCount: 2,
      branchCount: 3,
      cameraCount: 6,
      createdAt: DateTime(2026, 1, 1),
    ),
    CompanyModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Acme Retail Group',
      slug: 'acme-retail',
      brandCount: 1,
      branchCount: 1,
      cameraCount: 2,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  // 2. Brands
  static final List<BrandModel> demoBrands = [
    const BrandModel(
      id: '22222222-2222-2222-2222-222222222222',
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      name: 'Ego Fashion',
      slug: 'ego-fashion',
      branchCount: 3,
      cameraCount: 5,
      activeIncidents: 3,
    ),
    const BrandModel(
      id: '22222222-2222-2222-2222-222222222223',
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      name: 'Armani Exchange',
      slug: 'armani-exchange',
      branchCount: 2,
      cameraCount: 2,
      activeIncidents: 1,
    ),
    const BrandModel(
      id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      companyId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      companyName: 'Acme Retail Group',
      name: 'Acme Pro Store',
      slug: 'acme-pro',
      branchCount: 1,
      cameraCount: 1,
      activeIncidents: 0,
    ),
  ];

  // 3. Branches
  static final List<BranchModel> demoBranches = [
    const BranchModel(
      id: '33333333-3333-3333-3333-333333333333',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      name: 'Ego Mall of Arabia Branch',
      code: 'EGO-MOA-01',
      address: 'Mall of Arabia, Gate 4, 6th of October',
      cameraCount: 4,
      onlineCameraCount: 3,
      activeIncidentCount: 2,
      status: 'alert',
    ),
    const BranchModel(
      id: '33333333-3333-3333-3333-333333333334',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      name: 'Ego Cairo Festival City Branch',
      code: 'EGO-CFC-02',
      address: 'Cairo Festival City Mall, Level 1, New Cairo',
      cameraCount: 2,
      onlineCameraCount: 2,
      activeIncidentCount: 1,
      status: 'operational',
    ),
    const BranchModel(
      id: '33333333-3333-3333-3333-333333333335',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222223',
      name: 'Armani City Stars Branch',
      code: 'ARM-CS-01',
      address: 'City Stars Mall, Phase 2, Heliopolis',
      cameraCount: 1,
      onlineCameraCount: 0,
      activeIncidentCount: 1,
      status: 'degraded',
    ),
    const BranchModel(
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      companyId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      brandId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      name: 'Acme Downtown Branch',
      code: 'ACME-DT-01',
      address: '100 Downtown Boulevard, Central District',
      cameraCount: 1,
      onlineCameraCount: 1,
      activeIncidentCount: 0,
      status: 'operational',
    ),
  ];

  // 4. Demo Users
  static final List<UserProfile> demoUsers = [
    const UserProfile(
      id: 'usr-super-admin-01',
      email: 'admin@lensiq.cloud',
      fullName: 'Alex Vance',
      role: UserRole.superAdmin,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      authorizedBranchIds: [
        '33333333-3333-3333-3333-333333333333',
        '33333333-3333-3333-3333-333333333334',
        '33333333-3333-3333-3333-333333333335',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
      ],
    ),
    const UserProfile(
      id: 'usr-brand-mgr-01',
      email: 'brand@ego.demo',
      fullName: 'Sara Mansour',
      role: UserRole.brandManager,
      companyId: '11111111-1111-1111-1111-111111111111',
      companyName: 'Ego Retail Holding',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      authorizedBranchIds: [
        '33333333-3333-3333-3333-333333333333',
        '33333333-3333-3333-3333-333333333334',
      ],
    ),
    const UserProfile(
      id: 'usr-branch-sec-01',
      email: 'security@ego-moa.demo',
      fullName: 'Tamer Galal',
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

  // 5. Cameras
  static final List<CameraModel> demoCameras = [
    CameraModel(
      id: '44444444-4444-4444-4444-444444444441',
      name: 'Cashier 01',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.online,
      locationDescription: 'Counter 1 - Main Checkout Area',
      rtspUrl: 'rtsp://stream.ego-store.demo/live/cashier01',
      streamProfile: 'main',
      fps: 30,
      latencyMs: 38,
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 4)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444442',
      name: 'Main Entrance',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: CameraSourceType.hikvisionP2p,
      status: CameraStatus.online,
      locationDescription: 'Customer Entrance & Glass Gates',
      hikDeviceId: 'HIK-DS-2CD2143G2-DEMO-01',
      hikSerialNumber: 'D12345678FakeSerial',
      hikChannel: 1,
      streamProfile: 'main',
      fps: 25,
      latencyMs: 82,
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 8)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444443',
      name: 'Fitting Rooms Corridor',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.online,
      locationDescription: 'Fitting Rooms Hallway & Staging Zone',
      rtspUrl: 'rtsp://stream.ego-store.demo/live/fitting-corridor',
      streamProfile: 'sub',
      fps: 20,
      latencyMs: 44,
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 15)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444444',
      name: 'Backstore & Loading Dock',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: CameraSourceType.hikvisionP2p,
      status: CameraStatus.warning,
      locationDescription: 'Service Hallway and Emergency Exit',
      hikDeviceId: 'HIK-BAY-4491-IS',
      hikSerialNumber: 'SER-BAY-99182',
      hikChannel: 2,
      streamProfile: 'sub',
      fps: 15,
      latencyMs: 145,
      lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444445',
      name: 'Cashier 02',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333334',
      branchName: 'Ego Cairo Festival City Branch',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.online,
      locationDescription: 'CFC Main Checkout Zone',
      rtspUrl: 'rtsp://stream.cfc.demo/live/cashier02',
      streamProfile: 'main',
      fps: 30,
      latencyMs: 40,
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 6)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444446',
      name: 'Luxury Showcase 01',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222223',
      brandName: 'Armani Exchange',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: CameraSourceType.hikvisionP2p,
      status: CameraStatus.online,
      locationDescription: 'Armani Section Display Cabinets',
      hikDeviceId: 'HIK-ARM-01',
      hikSerialNumber: 'SER-ARM-88219',
      hikChannel: 1,
      streamProfile: 'main',
      fps: 30,
      latencyMs: 76,
      lastSeenAt: DateTime.now().subtract(const Duration(seconds: 10)),
    ),
    CameraModel(
      id: '44444444-4444-4444-4444-444444444447',
      name: 'Storefront Display',
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222223',
      brandName: 'Armani Exchange',
      branchId: '33333333-3333-3333-3333-333333333335',
      branchName: 'Armani City Stars Branch',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.offline,
      locationDescription: 'City Stars Front Display',
      rtspUrl: 'rtsp://stream.cs.demo/live/front',
      streamProfile: 'main',
      fps: 0,
      latencyMs: 0,
      lastSeenAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    CameraModel(
      id: '55555555-5555-5555-5555-555555555551',
      name: 'Safe Vault Surveillance',
      companyId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      brandId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      brandName: 'Acme Pro Store',
      branchId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      branchName: 'Acme Downtown Branch',
      sourceType: CameraSourceType.rtsp,
      status: CameraStatus.unknown,
      locationDescription: 'Acme High Security Zone',
      rtspUrl: 'rtsp://stream.acme.demo/live/vault',
      streamProfile: 'main',
      fps: 0,
      latencyMs: 0,
      lastSeenAt: null,
    ),
  ];

  // 6. Incidents
  static final List<IncidentModel> demoIncidents = [
    IncidentModel(
      id: 'inc-01',
      cameraId: '44444444-4444-4444-4444-444444444441',
      cameraName: 'Cashier 01',
      brandId: '22222222-2222-2222-2222-222222222223',
      brandName: 'Armani Exchange',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      ruleType: 'cashier_empty',
      severity: IncidentSeverity.critical,
      status: IncidentStatus.open,
      title: 'Cashier Area Empty',
      description: 'Cashier area has been unoccupied for 3 minutes (195s elapsed). Queue forming.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      durationSeconds: 195,
      confidence: 0.96,
    ),
    IncidentModel(
      id: 'inc-02',
      cameraId: '44444444-4444-4444-4444-444444444444',
      cameraName: 'Backstore & Loading Dock',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
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
      cameraId: '44444444-4444-4444-4444-444444444445',
      cameraName: 'Cashier 02',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333334',
      branchName: 'Ego Cairo Festival City Branch',
      ruleType: 'queue_overflow',
      severity: IncidentSeverity.warning,
      status: IncidentStatus.open,
      title: 'Queue Limit Overflow (>5 Customers)',
      description: 'Customer wait line exceeds 6 people. Additional cashier activation recommended.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      durationSeconds: 120,
      confidence: 0.89,
    ),
    IncidentModel(
      id: 'inc-04',
      cameraId: '44444444-4444-4444-4444-444444444443',
      cameraName: 'Fitting Rooms Corridor',
      brandId: '22222222-2222-2222-2222-222222222222',
      brandName: 'Ego Fashion',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      ruleType: 'loitering',
      severity: IncidentSeverity.warning,
      status: IncidentStatus.open,
      title: 'Suspicious Loitering in Fitting Room Area',
      description: 'Individual observed lingering in fitting room threshold zone for over 4 minutes.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
      durationSeconds: 240,
      confidence: 0.92,
    ),
    IncidentModel(
      id: 'inc-05',
      cameraId: '44444444-4444-4444-4444-444444444442',
      cameraName: 'Main Entrance',
      brandId: '22222222-2222-2222-2222-222222222223',
      brandName: 'Armani Exchange',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      ruleType: 'footfall_spike',
      severity: IncidentSeverity.info,
      status: IncidentStatus.resolved,
      title: 'Footfall Surge Detected (45 people/min)',
      description: 'Peak customer inflow exceeding 45 persons/minute recorded at main entrance gate.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      durationSeconds: 300,
      confidence: 0.91,
      resolutionNote: 'Handled by floor greeters.',
    ),
  ];

  // 7. AI Rules
  static final List<AiRuleModel> demoRules = [
    const AiRuleModel(
      id: 'rule-01',
      name: 'Cashier Empty Counter Alert',
      ruleType: 'cashier_empty',
      enabled: true,
      durationSeconds: 180,
      minPeople: 0,
      severity: IncidentSeverity.critical,
      cameraId: '44444444-4444-4444-4444-444444444441',
      cameraName: 'Cashier 01',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      roiId: 'roi-cashier-01',
      roiName: 'Cashier Desk Zone',
    ),
    const AiRuleModel(
      id: 'rule-02',
      name: 'Backstore After-Hours Breach',
      ruleType: 'perimeter_breach',
      enabled: true,
      durationSeconds: 5,
      minPeople: 1,
      severity: IncidentSeverity.critical,
      cameraId: '44444444-4444-4444-4444-444444444444',
      cameraName: 'Backstore & Loading Dock',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      roiId: 'roi-backstore-01',
      roiName: 'Loading Dock Perimeter',
    ),
    const AiRuleModel(
      id: 'rule-03',
      name: 'Fitting Room Loitering Detection',
      ruleType: 'loitering',
      enabled: true,
      durationSeconds: 240,
      minPeople: 1,
      severity: IncidentSeverity.warning,
      cameraId: '44444444-4444-4444-4444-444444444443',
      cameraName: 'Fitting Rooms Corridor',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      roiId: 'roi-fitting-01',
      roiName: 'Corridor Staging Zone',
    ),
    const AiRuleModel(
      id: 'rule-04',
      name: 'Checkout Line Capacity Threshold',
      ruleType: 'occupancy_limit',
      enabled: true,
      durationSeconds: 90,
      minPeople: 5,
      severity: IncidentSeverity.warning,
      cameraId: '44444444-4444-4444-4444-444444444445',
      cameraName: 'Cashier 02',
      branchId: '33333333-3333-3333-3333-333333333334',
      branchName: 'Ego Cairo Festival City Branch',
      roiId: 'roi-cashier-02',
      roiName: 'Queue Area Polygon',
    ),
  ];

  // 8. ROI Polygons
  static final List<RoiPolygon> demoRois = [
    const RoiPolygon(
      id: 'roi-cashier-01',
      name: 'Cashier 01 Active Counter ROI',
      zoneType: 'cashier_desk',
      color: Color(0xFF00E5FF),
      points: [
        RoiPoint(x: 0.15, y: 0.25),
        RoiPoint(x: 0.65, y: 0.25),
        RoiPoint(x: 0.65, y: 0.85),
        RoiPoint(x: 0.15, y: 0.85),
      ],
    ),
    const RoiPolygon(
      id: 'roi-backstore-01',
      name: 'Restricted Backstore Emergency Zone',
      zoneType: 'backstore_perimeter',
      color: Color(0xFFFF5252),
      points: [
        RoiPoint(x: 0.20, y: 0.30),
        RoiPoint(x: 0.80, y: 0.30),
        RoiPoint(x: 0.85, y: 0.75),
        RoiPoint(x: 0.15, y: 0.75),
      ],
    ),
    const RoiPolygon(
      id: 'roi-fitting-01',
      name: 'Fitting Room Corridor Staging Area',
      zoneType: 'fitting_room',
      color: Color(0xFFFFAB00),
      points: [
        RoiPoint(x: 0.25, y: 0.20),
        RoiPoint(x: 0.75, y: 0.20),
        RoiPoint(x: 0.70, y: 0.80),
        RoiPoint(x: 0.30, y: 0.80),
      ],
    ),
  ];

  // 9. Audit Logs
  static final List<AuditLogModel> demoAuditLogs = [
    AuditLogModel(
      id: 'aud-01',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      action: 'Camera Cashier 01 updated',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Stream profile verified and Vault secret reference confirmed.',
      category: 'camera',
      ipAddress: '192.168.1.102',
    ),
    AuditLogModel(
      id: 'aud-02',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      action: 'ROI Cashier Area modified',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Polygon adjusted (4 vertices) to capture customer queuing perimeter.',
      category: 'roi',
      ipAddress: '192.168.1.102',
    ),
    AuditLogModel(
      id: 'aud-03',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      action: 'Incident acknowledged',
      actorName: 'Tamer Galal (Branch Security)',
      actorRole: 'branch_security',
      details: 'Incident #inc-02 acknowledged for Backstore & Loading Dock.',
      category: 'incident',
      ipAddress: '10.0.4.15',
    ),
    AuditLogModel(
      id: 'aud-04',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      action: 'New critical incident detected',
      actorName: 'LensIQ AI Vision Worker',
      actorRole: 'system',
      details: 'Unattended Cashier Counter triggered on Camera Cashier 01.',
      category: 'incident',
    ),
    AuditLogModel(
      id: 'aud-05',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      action: 'Hikvision P2P source reconnected',
      actorName: 'Streaming Gateway Adapter',
      actorRole: 'system',
      details: 'Heartbeat ping re-established for device HIK-DS-2CD2143G2-DEMO-01.',
      category: 'camera',
    ),
    AuditLogModel(
      id: 'aud-06',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      action: 'AI Rule created',
      actorName: 'Alex Vance (Super Admin)',
      actorRole: 'super_admin',
      details: 'Created rule "Checkout Line Capacity Threshold" for CFC branch.',
      category: 'rule',
      ipAddress: '192.168.1.102',
    ),
  ];

  static DashboardSummary getSummaryForUser(UserProfile user) {
    final cams = getCamerasForUser(user);
    final incs = getIncidentsForUser(user);
    final activeIncs = incs.where((i) => i.status == IncidentStatus.open).toList();

    return DashboardSummary(
      totalCameras: cams.length,
      onlineCameras: cams.where((c) => c.isOnline).length,
      offlineCameras: cams.where((c) => !c.isOnline).length,
      activeIncidents: activeIncs.length,
      criticalAlerts: incs.where((i) => i.isCritical && i.status != IncidentStatus.resolved).length,
      totalBranches: user.isSuperAdmin ? demoBranches.length : user.authorizedBranchIds.length,
      incidentsToday: incs.length + 7, // seed total today
      cashierAlerts: activeIncs.where((i) => i.isCashierAlert).length,
      networkUptimePercentage: 99.8,
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
      latencyMs: isHik ? 82 : 38,
      connectionStatus: 'streaming',
    );
  }
}
