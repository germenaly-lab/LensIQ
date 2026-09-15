import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/user_profile.dart';
import '../../models/camera.dart';
import '../../models/incident.dart';
import '../../models/branch.dart';
import '../../models/audit_log.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/loading_view.dart';
import 'brand_manager_dashboard.dart';
import 'branch_security_dashboard.dart';
import 'widgets/metric_card.dart';
import 'widgets/dashboard_charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CameraProvider>().loadCameras(user);
        context.read<IncidentProvider>().loadData(user);
        context.read<AdminProvider>().loadAllAdminData(user);
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cameraProv = context.watch<CameraProvider>();
    final incidentProv = context.watch<IncidentProvider>();
    final adminProv = context.watch<AdminProvider>();

    if (user == null) return const Scaffold(body: LoadingView());

    final isDesktop = ResponsiveUtil.isDesktop(context);

    // 1. Role-specific Dashboard Routing
    if (user.isBrandManager) {
      return ResponsiveScaffold(
        currentRoute: '/dashboard',
        title: '${user.brandName ?? "Brand"} Operations Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Realtime Data',
            onPressed: () {
              cameraProv.loadCameras(user);
              incidentProv.loadData(user);
              adminProv.loadAllAdminData(user);
            },
          ),
        ],
        child: const BrandManagerDashboard(),
      );
    }

    if (user.isBranchSecurity) {
      if (!isDesktop) {
        // Mobile-first specialized layout for Security Staff
        return const BranchSecurityDashboard();
      }
      return ResponsiveScaffold(
        currentRoute: '/dashboard',
        title: '${user.branchName ?? "Branch"} Security Console',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Realtime Data',
            onPressed: () {
              cameraProv.loadCameras(user);
              incidentProv.loadData(user);
              adminProv.loadAllAdminData(user);
            },
          ),
        ],
        child: const BranchSecurityDashboard(),
      );
    }

    // 2. Super Admin Dashboard (Phase 6 Full Executive View)
    return ResponsiveScaffold(
      currentRoute: '/dashboard',
      title: 'Executive Monitoring Command Center',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Realtime Data',
          onPressed: () {
            cameraProv.loadCameras(user);
            incidentProv.loadData(user);
            adminProv.loadAllAdminData(user);
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await cameraProv.loadCameras(user);
          await incidentProv.loadData(user);
          await adminProv.loadAllAdminData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Top Bar (Page title, date/time, system status, user profile)
              _buildExecutiveTopBar(user),
              const SizedBox(height: 24),

              // 2. Executive Metrics Row (6 key metrics)
              _buildExecutiveMetrics(context, cameraProv, incidentProv, adminProv),
              const SizedBox(height: 28),

              // 3. Live Incident Feed
              _buildLiveIncidentFeed(context, incidentProv.rawIncidents),
              const SizedBox(height: 28),

              // 4. Real Database Charts Section
              const Text('Surveillance & Incident Intelligence', style: AppTypography.h2),
              const SizedBox(height: 4),
              Text(
                'Live aggregates computed across multi-brand holding database tables.',
                style: AppTypography.bodySecondary,
              ),
              const SizedBox(height: 16),
              DashboardCharts(
                incidentsByBrand: incidentProv.incidentsByBrand,
                incidentsByBranch: incidentProv.incidentsByBranch,
                incidentsOverTime: incidentProv.incidentsOverTime,
                incidentsBySeverity: incidentProv.incidentsBySeverity,
                cameraAvailability: cameraProv.availabilityPercentage,
                totalCameras: cameraProv.totalCamerasCount,
                onlineCameras: cameraProv.onlineCount,
              ),
              const SizedBox(height: 28),

              // 5. Camera Health Section (with brand, branch, status filters)
              _buildCameraHealthSection(context, cameraProv),
              const SizedBox(height: 28),

              // 6. Two-Column Row: Branch Overview & Recent Activity
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildBranchOverview(context, adminProv.branches)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildRecentActivity(context, adminProv.auditLogs)),
                  ],
                )
              else ...[
                _buildBranchOverview(context, adminProv.branches),
                const SizedBox(height: 24),
                _buildRecentActivity(context, adminProv.auditLogs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar
  Widget _buildExecutiveTopBar(UserProfile user) {
    final formattedTime = DateFormat('EEEE, MMM d, yyyy • HH:mm:ss').format(_currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title and Live Clock
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Super Admin Operations Portal', style: AppTypography.h2),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TENANT HQ',
                      style: AppTypography.badge.copyWith(color: AppColors.primaryLight, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(formattedTime, style: AppTypography.caption),
                ],
              ),
            ],
          ),

          // Status & User Profile Info
          Row(
            children: [
              // System Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'AI Vision Ingest Active',
                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // User Profile Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0] : 'A',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(user.fullName, style: AppTypography.bodyMedium),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.displayName.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Metrics Row
  Widget _buildExecutiveMetrics(
    BuildContext context,
    CameraProvider cameraProv,
    IncidentProvider incidentProv,
    AdminProvider adminProv,
  ) {
    final isDesktop = ResponsiveUtil.isDesktop(context);
    final columns = isDesktop ? 6 : (ResponsiveUtil.isTablet(context) ? 3 : 2);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.45 : 1.3,
      children: [
        MetricCard(
          title: 'Total Branches',
          value: '${adminProv.totalBranchesCount}',
          subtitle: 'Active Store Locations',
          icon: Icons.storefront_outlined,
          color: AppColors.primary,
          onTap: () => context.go('/branches'),
        ),
        MetricCard(
          title: 'Online Cameras',
          value: '${cameraProv.onlineCount}',
          subtitle: 'Streaming Real-Time',
          icon: Icons.videocam,
          color: AppColors.success,
          onTap: () => context.go('/cameras'),
        ),
        MetricCard(
          title: 'Offline Cameras',
          value: '${cameraProv.offlineCount + cameraProv.warningCount}',
          subtitle: '${cameraProv.warningCount} Degraded • ${cameraProv.offlineCount} Down',
          icon: Icons.videocam_off_outlined,
          color: (cameraProv.offlineCount + cameraProv.warningCount) > 0 ? AppColors.error : AppColors.textMuted,
          onTap: () => context.go('/cameras'),
        ),
        MetricCard(
          title: 'Active Incidents',
          value: '${incidentProv.activeIncidentsCount}',
          subtitle: 'Unresolved Alarms',
          icon: Icons.notifications_active_outlined,
          color: incidentProv.activeIncidentsCount > 0 ? AppColors.warning : AppColors.success,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'Critical Incidents',
          value: '${incidentProv.criticalIncidentsCount}',
          subtitle: 'Immediate NOC Attention',
          icon: Icons.warning_amber_rounded,
          color: incidentProv.criticalIncidentsCount > 0 ? AppColors.error : AppColors.textMuted,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'Incidents Today',
          value: '${incidentProv.incidentsTodayCount}',
          subtitle: 'Cumulative 24h Detections',
          icon: Icons.today_outlined,
          color: AppColors.accent,
          onTap: () => context.go('/incidents'),
        ),
      ],
    );
  }

  // 3. Live Incident Feed
  Widget _buildLiveIncidentFeed(BuildContext context, List<IncidentModel> incidents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.flash_on, color: AppColors.error, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Live Incident Feed', style: AppTypography.h2),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${incidents.where((i) => i.status == IncidentStatus.open).length} ACTIVE',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/incidents'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Manage All Incidents'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (incidents.isEmpty)
              const Center(child: Text('No active security incidents detected.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incidents.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inc = incidents[index];
                  return _IncidentFeedCard(
                    incident: inc,
                    onTap: () => context.go('/incidents'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 5. Camera Health Section
  Widget _buildCameraHealthSection(BuildContext context, CameraProvider cameraProv) {
    final filteredCameras = cameraProv.healthFilteredCameras;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camera Health & Telemetry', style: AppTypography.h2),
                    Text(
                      'Live status, frame rates, and latency for multi-source camera fleet.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => context.go('/cameras'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View All Cameras'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Status Chips (Online, Offline, Warning, Unknown)
                  _HealthChip(
                    label: 'All (${cameraProv.totalCamerasCount})',
                    isSelected: cameraProv.healthStatusFilter == null,
                    onTap: () => cameraProv.setHealthStatusFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _HealthChip(
                    label: 'Online (${cameraProv.onlineCount})',
                    isSelected: cameraProv.healthStatusFilter == CameraStatus.online,
                    color: AppColors.success,
                    onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.online),
                  ),
                  const SizedBox(width: 8),
                  _HealthChip(
                    label: 'Warning (${cameraProv.warningCount})',
                    isSelected: cameraProv.healthStatusFilter == CameraStatus.warning,
                    color: AppColors.warning,
                    onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.warning),
                  ),
                  const SizedBox(width: 8),
                  _HealthChip(
                    label: 'Offline (${cameraProv.offlineCount})',
                    isSelected: cameraProv.healthStatusFilter == CameraStatus.offline,
                    color: AppColors.error,
                    onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.offline),
                  ),
                  const SizedBox(width: 8),
                  _HealthChip(
                    label: 'Unknown (${cameraProv.unknownCount})',
                    isSelected: cameraProv.healthStatusFilter == CameraStatus.unknown,
                    color: AppColors.textMuted,
                    onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.unknown),
                  ),
                  const Spacer(),

                  // Brand & Branch Filter Dropdowns
                  DropdownButton<String?>(
                    value: cameraProv.healthBrandFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    hint: const Text('Filter Brand', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Brands')),
                      DropdownMenuItem(value: 'Ego', child: Text('Ego Fashion')),
                      DropdownMenuItem(value: 'Armani', child: Text('Armani Exchange')),
                    ],
                    onChanged: (val) => cameraProv.setHealthBrandFilter(val),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: cameraProv.healthBranchFilter,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    hint: const Text('Filter Branch', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Branches')),
                      DropdownMenuItem(value: 'Mall of Arabia', child: Text('Mall of Arabia')),
                      DropdownMenuItem(value: 'Festival City', child: Text('Cairo Festival City')),
                      DropdownMenuItem(value: 'City Stars', child: Text('City Stars')),
                    ],
                    onChanged: (val) => cameraProv.setHealthBranchFilter(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Camera Health Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredCameras.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
              ),
              itemBuilder: (context, index) {
                final cam = filteredCameras[index];
                return _CameraHealthCard(camera: cam);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 6. Branch Overview
  Widget _buildBranchOverview(BuildContext context, List<BranchModel> branches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Branch Operational Overview', style: AppTypography.h3),
                TextButton.icon(
                  onPressed: () => context.go('/branches'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: branches.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final b = branches[index];
                Color badgeColor = b.status == 'operational'
                    ? AppColors.success
                    : (b.status == 'alert' ? AppColors.warning : AppColors.error);

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: AppTypography.bodyMedium),
                          Text(
                            '${b.onlineCameraCount}/${b.cameraCount} Online • ${b.activeIncidentCount} Active Alert(s)',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 7. Recent Activity (Audit Log)
  Widget _buildRecentActivity(BuildContext context, List<AuditLogModel> logs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent System & Security Activity', style: AppTypography.h3),
                TextButton.icon(
                  onPressed: () => context.go('/audit-logs'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Audit Log'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.take(5).length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            'By ${log.actorName} • ${DateFormat("HH:mm:ss").format(log.timestamp)}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentFeedCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const _IncidentFeedCard({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateFormat('HH:mm:ss').format(incident.timestamp);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: incident.isCritical ? AppColors.error.withOpacity(0.5) : AppColors.border,
            width: incident.isCritical ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SeverityBadge(severity: incident.severity),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“${incident.title}”', style: AppTypography.h3.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    '${incident.brandName ?? "Ego Fashion"}  •  ${incident.branchName}  •  Camera: ${incident.cameraName}',
                    style: AppTypography.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  if (incident.durationSeconds != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '“Empty for ${(incident.durationSeconds! / 60).toStringAsFixed(0)} minutes (${incident.durationSeconds}s)”',
                      style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeAgo, style: AppTypography.code.copyWith(fontSize: 11)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    incident.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: incident.status == IncidentStatus.open ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _HealthChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? c : AppColors.border, width: isSelected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CameraHealthCard extends StatelessWidget {
  final CameraModel camera;

  const _CameraHealthCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          StatusBadge(status: camera.status),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  camera.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${camera.fps} FPS • ${camera.latencyMs}ms • ${camera.sourceType == CameraSourceType.rtsp ? "RTSP" : "P2P"}',
                  style: AppTypography.code.copyWith(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
