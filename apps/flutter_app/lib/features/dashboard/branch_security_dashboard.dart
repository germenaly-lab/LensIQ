import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/user_profile.dart';
import '../../models/camera.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/severity_badge.dart';

enum SecurityTriageCategory {
  all,
  critical,
  offlineCameras,
  cashierProblems,
  unusualActivity,
}

class BranchSecurityDashboard extends StatefulWidget {
  const BranchSecurityDashboard({Key? key}) : super(key: key);

  @override
  State<BranchSecurityDashboard> createState() => _BranchSecurityDashboardState();
}

class _BranchSecurityDashboardState extends State<BranchSecurityDashboard> {
  SecurityTriageCategory _activeTriage = SecurityTriageCategory.all;
  int _mobileNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user != null) {
      context.read<IncidentProvider>().loadData(user);
      context.read<CameraProvider>().loadCameras(user);
      context.read<AdminProvider>().loadAllAdminData(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final incidentProvider = context.watch<IncidentProvider>();
    final cameraProvider = context.watch<CameraProvider>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Branch Security: STRICTLY assigned branch ONLY
    final branchCameras = cameraProvider.cameras.where((c) => c.branchId == user.branchId).toList();
    final branchIncidents = incidentProvider.rawIncidents.where((i) => i.branchId == user.branchId).toList();

    // 4 Key Identification Categories
    final criticalIncidents = branchIncidents.where((i) => i.isCritical && i.status != IncidentStatus.resolved).toList();
    final offlineCameras = branchCameras.where((c) => !c.isOnline || c.status == CameraStatus.warning).toList();
    final cashierIncidents = branchIncidents.where((i) => i.isCashierAlert && i.status != IncidentStatus.resolved).toList();
    final unusualActivityIncidents = branchIncidents.where((i) {
      final t = i.ruleType.toLowerCase();
      return (t.contains('breach') || t.contains('loitering') || t.contains('intrusion') || t.contains('unusual')) &&
          i.status != IncidentStatus.resolved;
    }).toList();

    // Filtered list based on active triage chip
    List<IncidentModel> displayedIncidents;
    switch (_activeTriage) {
      case SecurityTriageCategory.critical:
        displayedIncidents = criticalIncidents;
        break;
      case SecurityTriageCategory.cashierProblems:
        displayedIncidents = cashierIncidents;
        break;
      case SecurityTriageCategory.unusualActivity:
        displayedIncidents = unusualActivityIncidents;
        break;
      case SecurityTriageCategory.offlineCameras:
      case SecurityTriageCategory.all:
        displayedIncidents = branchIncidents.where((i) => i.status != IncidentStatus.resolved).toList();
        break;
    }

    final recentIncidents = branchIncidents.where((i) => i.status == IncidentStatus.resolved).toList();
    final isMobile = ResponsiveUtil.isMobile(context);

    Widget content;
    if (isMobile && _mobileNavIndex == 1) {
      // Mobile Tab 1: Live Cameras
      content = _buildLiveCamerasView(branchCameras);
    } else if (isMobile && _mobileNavIndex == 2) {
      // Mobile Tab 2: Incidents Queue
      content = _buildIncidentsQueueView(displayedIncidents, incidentProvider);
    } else if (isMobile && _mobileNavIndex == 3) {
      // Mobile Tab 3: Camera Health & Security Details
      content = _buildCameraHealthView(branchCameras);
    } else {
      // Default: Dashboard / Guard Feed
      content = _buildMainDashboardFeed(
        user: user,
        branchCameras: branchCameras,
        branchIncidents: branchIncidents,
        criticalIncidents: criticalIncidents,
        offlineCameras: offlineCameras,
        cashierIncidents: cashierIncidents,
        unusualIncidents: unusualActivityIncidents,
        displayedIncidents: displayedIncidents,
        recentIncidents: recentIncidents,
        incidentProvider: incidentProvider,
        isMobile: isMobile,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: content,
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _mobileNavIndex,
              onTap: (idx) => setState(() => _mobileNavIndex = idx),
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.security),
                  label: 'Guard Feed',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: Text('${branchCameras.length}'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.videocam_outlined),
                  ),
                  label: 'Live Cams',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: criticalIncidents.isNotEmpty,
                    label: Text('${criticalIncidents.length}'),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.notifications_active_outlined),
                  ),
                  label: 'Action Queue',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.health_and_safety_outlined),
                  label: 'Health',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildMainDashboardFeed({
    required UserProfile user,
    required List<CameraModel> branchCameras,
    required List<IncidentModel> branchIncidents,
    required List<IncidentModel> criticalIncidents,
    required List<CameraModel> offlineCameras,
    required List<IncidentModel> cashierIncidents,
    required List<IncidentModel> unusualIncidents,
    required List<IncidentModel> displayedIncidents,
    required List<IncidentModel> recentIncidents,
    required IncidentProvider incidentProvider,
    required bool isMobile,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Critical Alert Pulse Banner (Top Priority)
          if (criticalIncidents.isNotEmpty)
            _buildEmergencyCriticalBanner(criticalIncidents.first, incidentProvider),

          const SizedBox(height: 16),

          // 2. Branch Status Header
          _buildBranchStatusHeader(user, branchCameras, isMobile),
          const SizedBox(height: 16),

          // 3. Quick Identification Triage Bar (4 Category Filters)
          _buildQuickTriageBar(
            criticalCount: criticalIncidents.length,
            offlineCount: offlineCameras.length,
            cashierCount: cashierIncidents.length,
            unusualCount: unusualIncidents.length,
          ),
          const SizedBox(height: 20),

          // 4. Live Cameras Quick Strip / Grid
          _buildLiveCamerasSection(branchCameras, isMobile),
          const SizedBox(height: 24),

          // 5. Active Incidents Action Queue (Large Mobile Buttons)
          _buildActionQueueSection(displayedIncidents, incidentProvider),
          const SizedBox(height: 24),

          // 6. Recent Branch Incidents
          _buildRecentIncidentsSection(recentIncidents),
        ],
      ),
    );
  }

  Widget _buildEmergencyCriticalBanner(IncidentModel topCritical, IncidentProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CRITICAL ALERT IN PROGRESS',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(3)),
                      child: Text(topCritical.cameraName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(topCritical.title, style: AppTypography.h3.copyWith(color: Colors.white)),
                Text(topCritical.description, style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => provider.acknowledgeIncident(topCritical.id),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('ACKNOWLEDGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchStatusHeader(UserProfile user, List<CameraModel> cameras, bool isMobile) {
    final onlineCount = cameras.where((c) => c.isOnline).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.branchName ?? 'Branch Security Console', style: isMobile ? AppTypography.h3 : AppTypography.h2),
                const SizedBox(height: 2),
                Text(
                  'Officer: ${user.fullName} • Shift: Active Monitoring • $onlineCount/${cameras.length} Cameras Active',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: const [
                Icon(Icons.fiber_manual_record, color: AppColors.success, size: 10),
                SizedBox(width: 6),
                Text('ON DUTY', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTriageBar({
    required int criticalCount,
    required int offlineCount,
    required int cashierCount,
    required int unusualCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.warning, size: 18),
            const SizedBox(width: 6),
            const Text('Fast Triage (Quick Identification)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const Spacer(),
            if (_activeTriage != SecurityTriageCategory.all)
              GestureDetector(
                onTap: () => setState(() => _activeTriage = SecurityTriageCategory.all),
                child: const Text('Show All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTriageChip(
                category: SecurityTriageCategory.critical,
                label: 'Critical Incidents',
                count: criticalCount,
                color: AppColors.error,
                icon: Icons.error_outline,
              ),
              const SizedBox(width: 8),
              _buildTriageChip(
                category: SecurityTriageCategory.cashierProblems,
                label: 'Cashier Problems',
                count: cashierCount,
                color: Colors.amber,
                icon: Icons.point_of_sale,
              ),
              const SizedBox(width: 8),
              _buildTriageChip(
                category: SecurityTriageCategory.unusualActivity,
                label: 'Unusual Activity',
                count: unusualCount,
                color: Colors.purpleAccent,
                icon: Icons.visibility,
              ),
              const SizedBox(width: 8),
              _buildTriageChip(
                category: SecurityTriageCategory.offlineCameras,
                label: 'Offline Cameras',
                count: offlineCount,
                color: Colors.orange,
                icon: Icons.videocam_off_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTriageChip({
    required SecurityTriageCategory category,
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _activeTriage == category;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTriage = isSelected ? SecurityTriageCategory.all : category;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: Colors.white)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCamerasSection(List<CameraModel> cameras, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Branch Live Feeds (${cameras.length})', style: AppTypography.h3),
            const Spacer(),
            Text('${cameras.where((c) => c.isOnline).length} Active', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 12),
        isMobile
            ? SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cameras.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 240,
                    child: _buildCameraCard(cameras[index]),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cameras.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) => _buildCameraCard(cameras[index]),
              ),
      ],
    );
  }

  Widget _buildCameraCard(CameraModel cam) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cam.isOnline ? AppColors.border : AppColors.warning.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Stream Preview Mock
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.videocam,
                      size: 32,
                      color: cam.isOnline ? Colors.white24 : Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: StatusBadge(status: cam.status),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cam.sourceTypeDisplayName,
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => _openLiveStreamDialog(cam),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cam.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(cam.locationDescription ?? 'Station area', style: AppTypography.caption.copyWith(fontSize: 10), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(cam.isOnline ? '${cam.fps} FPS' : 'N/A', style: AppTypography.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLiveStreamDialog(CameraModel cam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.videocam, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(cam.name),
            const Spacer(),
            StatusBadge(status: cam.status),
          ],
        ),
        content: Container(
          width: 500,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('Live Stream Connected (WebRTC / HLS)', style: AppTypography.bodySmall),
                    Text('Latency: ${cam.latencyMs}ms • Source: ${cam.sourceTypeDisplayName}', style: AppTypography.caption),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                left: 12,
                child: Text('LIVE • AI VISION ANALYSIS ACTIVE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close Stream')),
        ],
      ),
    );
  }

  Widget _buildActionQueueSection(List<IncidentModel> incidents, IncidentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text('Action Queue — Active Incidents (${incidents.length})', style: AppTypography.h3),
          ],
        ),
        const SizedBox(height: 12),
        if (incidents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text('All clear in current triage filter. No open alerts.', style: AppTypography.bodySmall),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final inc = incidents[index];
              return _buildSecurityIncidentCard(inc, provider);
            },
          ),
      ],
    );
  }

  Widget _buildSecurityIncidentCard(IncidentModel inc, IncidentProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: inc.isCritical ? AppColors.error : AppColors.border,
          width: inc.isCritical ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeverityBadge(severity: inc.severity),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inc.title,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${inc.timestamp.hour.toString().padLeft(2, '0')}:${inc.timestamp.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(inc.description, style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.videocam, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(inc.cameraName, style: AppTypography.caption),
              const Spacer(),
              Text('Confidence: ${(((inc.confidence ?? 0.95) * 100)).toStringAsFixed(0)}%', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 14),
          // Large Mobile-Friendly Buttons
          Row(
            children: [
              if (inc.status == IncidentStatus.open)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.acknowledgeIncident(inc.id),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('ACKNOWLEDGE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQuickResolveSheet(inc, provider),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('RESOLVE'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.success),
                    foregroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => provider.markFalsePositive(inc.id),
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                tooltip: 'False Positive',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickResolveSheet(IncidentModel inc, IncidentProvider provider) {
    final noteController = TextEditingController(text: 'Checked and cleared by security patrol.');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resolve: ${inc.title}', style: AppTypography.h3),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Officer Resolution Notes'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.resolveIncident(inc.id, noteController.text);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.success,
              ),
              child: const Text('Confirm Resolved', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIncidentsSection(List<IncidentModel> recent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Branch History', style: AppTypography.h3),
          const Divider(height: 20),
          if (recent.isEmpty)
            const Text('No resolved branch history today.', style: AppTypography.caption)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = recent[index];
                return Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.title, style: AppTypography.bodySmall)),
                    Text('RESOLVED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Views for Mobile Bottom Tabs
  Widget _buildLiveCamerasView(List<CameraModel> cameras) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cameras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => SizedBox(
        height: 170,
        child: _buildCameraCard(cameras[index]),
      ),
    );
  }

  Widget _buildIncidentsQueueView(List<IncidentModel> incidents, IncidentProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: incidents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildSecurityIncidentCard(incidents[index], provider),
    );
  }

  Widget _buildCameraHealthView(List<CameraModel> cameras) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cameras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cam = cameras[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              StatusBadge(status: cam.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cam.name, style: AppTypography.bodyMedium),
                    Text('${cam.sourceTypeDisplayName} • ${cam.locationDescription}', style: AppTypography.caption),
                  ],
                ),
              ),
              Text(cam.isOnline ? '${cam.latencyMs}ms' : 'OFFLINE', style: AppTypography.caption),
            ],
          ),
        );
      },
    );
  }
}
