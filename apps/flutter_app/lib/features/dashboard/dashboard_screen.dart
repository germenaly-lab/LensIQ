import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../core/localization/app_locale_provider.dart';
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
    final colors = context.colors;

    if (user == null) return const Scaffold(body: LoadingView());

    final isDesktop = ResponsiveUtil.isDesktop(context);

    // 1. Role-specific Dashboard Routing
    if (user.isBrandManager) {
      return ResponsiveScaffold(
        currentRoute: '/dashboard',
        title: '${user.brandName ?? "Brand"} ${context.tr("Operations Center")}',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: context.tr('Refresh Realtime Data'),
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
        return const BranchSecurityDashboard();
      }
      return ResponsiveScaffold(
        currentRoute: '/dashboard',
        title: '${user.branchName ?? "Branch"} ${context.tr("Operations Center")}',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: context.tr('Refresh Realtime Data'),
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

    // 2. Super Admin Dashboard (Executive Monitoring Command Center)
    return ResponsiveScaffold(
      currentRoute: '/dashboard',
      title: 'Operations Center',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: context.tr('Refresh Realtime Data'),
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
              // 1. Executive Top Bar
              _buildExecutiveTopBar(context, user, colors),
              const SizedBox(height: 24),

              // 2. Executive Metrics Row (6 key metrics with flexible layout)
              _buildExecutiveMetrics(context, cameraProv, incidentProv, adminProv, isDesktop),
              const SizedBox(height: 28),

              // 3. Live Incident Feed
              _buildLiveIncidentFeed(context, incidentProv.rawIncidents, colors),
              const SizedBox(height: 28),

              // 4. Intelligence Charts Section
              Text(
                context.tr('Surveillance & Incident Intelligence'),
                style: AppTypography.h2Of(context).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Live aggregates computed across multi-brand holding database tables.'),
                style: AppTypography.captionOf(context),
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

              // 5. Camera Health Section
              _buildCameraHealthSection(context, cameraProv, adminProv, colors),
              const SizedBox(height: 28),

              // 6. Two-Column Row: Branch Overview & Recent Activity
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildBranchOverview(context, adminProv.branches, colors)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildRecentActivity(context, adminProv.auditLogs, colors)),
                  ],
                )
              else ...[
                _buildBranchOverview(context, adminProv.branches, colors),
                const SizedBox(height: 24),
                _buildRecentActivity(context, adminProv.auditLogs, colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Bar
  Widget _buildExecutiveTopBar(BuildContext context, UserProfile user, AppSemanticColors colors) {
    final formattedTime = DateFormat('EEEE, MMM d, yyyy • HH:mm:ss').format(_currentTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
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
                  Text(
                    context.tr('Operations Center'),
                    style: AppTypography.h2Of(context).copyWith(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.tr('Global Access'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: colors.textMuted),
                  const SizedBox(width: 6),
                  Text(formattedTime, style: AppTypography.captionOf(context)),
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
                  color: colors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: colors.success),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('System Operational'),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // User Profile Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'A',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.fullName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.tr(user.role.displayName).toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.secondary),
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
    bool isDesktop,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = isDesktop ? 6 : (ResponsiveUtil.isTablet(context) ? 3 : 2);
    final ratio = isDesktop ? (screenWidth > 1400 ? 1.65 : 1.45) : (ResponsiveUtil.isTablet(context) ? 1.4 : 1.35);
    final colors = context.colors;

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: ratio,
      children: [
        MetricCard(
          title: 'Total Branches',
          value: '${adminProv.totalBranchesCount}',
          subtitle: 'Active Store Locations',
          icon: Icons.storefront_outlined,
          color: colors.primary,
          trend: '+2 this month',
          isPositiveTrend: true,
          onTap: () => context.go('/branches'),
        ),
        MetricCard(
          title: 'Online Cameras',
          value: '${cameraProv.onlineCount}',
          subtitle: 'Streaming Real-Time',
          icon: Icons.videocam,
          color: colors.success,
          trend: '${cameraProv.availabilityPercentage.toStringAsFixed(0)}% uptime',
          isPositiveTrend: true,
          onTap: () => context.go('/cameras'),
        ),
        MetricCard(
          title: 'Offline Cameras',
          value: '${cameraProv.offlineCount + cameraProv.warningCount}',
          subtitle: '${cameraProv.warningCount} Degraded • ${cameraProv.offlineCount} Down',
          icon: Icons.videocam_off_outlined,
          color: (cameraProv.offlineCount + cameraProv.warningCount) > 0 ? colors.error : colors.textMuted,
          onTap: () => context.go('/cameras'),
        ),
        MetricCard(
          title: 'Active Incidents',
          value: '${incidentProv.activeIncidentsCount}',
          subtitle: 'Unresolved Alarms',
          icon: Icons.notifications_active_outlined,
          color: incidentProv.activeIncidentsCount > 0 ? colors.warning : colors.success,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'Critical Incidents',
          value: '${incidentProv.criticalIncidentsCount}',
          subtitle: 'Immediate NOC Attention',
          icon: Icons.warning_amber_rounded,
          color: incidentProv.criticalIncidentsCount > 0 ? colors.error : colors.textMuted,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'Incidents Today',
          value: '${incidentProv.incidentsTodayCount}',
          subtitle: 'Cumulative 24h Detections',
          icon: Icons.today_outlined,
          color: colors.accent,
          onTap: () => context.go('/incidents'),
        ),
      ],
    );
  }

  // 3. Live Incident Feed
  Widget _buildLiveIncidentFeed(
    BuildContext context,
    List<IncidentModel> incidents,
    AppSemanticColors colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
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
                      color: colors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.flash_on, color: colors.error, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('Live Incident Feed'),
                    style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${incidents.where((i) => i.status == IncidentStatus.open).length} ${context.tr("Active")}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/incidents'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(context.tr('Incidents')),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  context.tr('No incidents found'),
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inc = incidents[index];
                return _IncidentFeedCard(
                  incident: inc,
                  colors: colors,
                  onTap: () => context.go('/incidents'),
                );
              },
            ),
        ],
      ),
    );
  }

  // 5. Camera Health Section
  Widget _buildCameraHealthSection(
    BuildContext context,
    CameraProvider cameraProv,
    AdminProvider adminProv,
    AppSemanticColors colors,
  ) {
    final filteredCameras = cameraProv.healthFilteredCameras;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
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
                  Text(
                    context.tr('Camera Health'),
                    style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                  ),
                  Text(
                    context.tr('Stream Health'),
                    style: AppTypography.captionOf(context),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/cameras'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(context.tr('Cameras')),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                _HealthChip(
                  label: '${context.tr("All Sources")} (${cameraProv.totalCamerasCount})',
                  isSelected: cameraProv.healthStatusFilter == null,
                  colors: colors,
                  onTap: () => cameraProv.setHealthStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _HealthChip(
                  label: '${context.tr("Online")} (${cameraProv.onlineCount})',
                  isSelected: cameraProv.healthStatusFilter == CameraStatus.online,
                  color: colors.success,
                  colors: colors,
                  onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.online),
                ),
                const SizedBox(width: 8),
                _HealthChip(
                  label: '${context.tr("Warning")} (${cameraProv.warningCount})',
                  isSelected: cameraProv.healthStatusFilter == CameraStatus.warning,
                  color: colors.warning,
                  colors: colors,
                  onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.warning),
                ),
                const SizedBox(width: 8),
                _HealthChip(
                  label: '${context.tr("Offline")} (${cameraProv.offlineCount})',
                  isSelected: cameraProv.healthStatusFilter == CameraStatus.offline,
                  color: colors.error,
                  colors: colors,
                  onTap: () => cameraProv.setHealthStatusFilter(CameraStatus.offline),
                ),
                const Spacer(),

                // Dynamic Brand Dropdown Filter
                DropdownButton<String?>(
                  value: cameraProv.healthBrandFilter,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.surfaceElevated,
                  style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  hint: Text(context.tr('Filter by Brand'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.tr('All Brands'))),
                    ...adminProv.brands.map(
                      (b) => DropdownMenuItem(value: b.name, child: Text(b.name)),
                    ),
                  ],
                  onChanged: (val) => cameraProv.setHealthBrandFilter(val),
                ),
                const SizedBox(width: 12),

                // Dynamic Branch Dropdown Filter
                DropdownButton<String?>(
                  value: cameraProv.healthBranchFilter,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.surfaceElevated,
                  style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  hint: Text(context.tr('Filter by Branch'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.tr('All Branches'))),
                    ...adminProv.branches.map(
                      (br) => DropdownMenuItem(value: br.name, child: Text(br.name)),
                    ),
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
              return _CameraHealthCard(camera: cam, colors: colors);
            },
          ),
        ],
      ),
    );
  }

  // 6. Branch Overview
  Widget _buildBranchOverview(BuildContext context, List<BranchModel> branches, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('Branches'), style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
              TextButton.icon(
                onPressed: () => context.go('/branches'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(context.tr('View')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, __) => Divider(height: 16, color: colors.borderSubtle),
            itemBuilder: (context, index) {
              final b = branches[index];
              Color badgeColor = b.status == 'operational'
                  ? colors.success
                  : (b.status == 'alert' ? colors.warning : colors.error);

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.storefront, color: colors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                        Text(
                          '${b.onlineCameraCount}/${b.cameraCount} ${context.tr("Online")} • ${b.activeIncidentCount} ${context.tr("Active")}',
                          style: AppTypography.captionOf(context).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
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
    );
  }

  // 7. Recent Activity (Audit Log)
  Widget _buildRecentActivity(BuildContext context, List<AuditLogModel> logs, AppSemanticColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('Audit Logs'), style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
              TextButton.icon(
                onPressed: () => context.go('/audit-logs'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: Text(context.tr('View')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.take(5).length,
            separatorBuilder: (_, __) => Divider(height: 16, color: colors.borderSubtle),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.action,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${log.actorName} • ${DateFormat("HH:mm:ss").format(log.timestamp)}',
                          style: AppTypography.captionOf(context).copyWith(fontSize: 11),
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
    );
  }
}

class _IncidentFeedCard extends StatelessWidget {
  final IncidentModel incident;
  final AppSemanticColors colors;
  final VoidCallback onTap;

  const _IncidentFeedCard({
    required this.incident,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeAgo = DateFormat('HH:mm:ss').format(incident.timestamp);
    final accentColor = incident.isCritical ? colors.error : (incident.isWarning ? colors.warning : colors.info);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: BorderDirectional(
            start: BorderSide(color: accentColor, width: 4),
            top: BorderSide(color: colors.borderSubtle),
            bottom: BorderSide(color: colors.borderSubtle),
            end: BorderSide(color: colors.borderSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SeverityBadge(severity: incident.severity),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(incident.title),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${incident.brandName ?? "Ego Fashion"} • ${incident.branchName} • ${incident.cameraName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (incident.durationSeconds != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${context.tr("Empty for")} ${(incident.durationSeconds! / 60).toStringAsFixed(0)} ${context.tr("minutes")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeAgo, style: AppTypography.code.copyWith(fontSize: 11, color: colors.textMuted)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    context.tr(incident.status.displayName).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: incident.status == IncidentStatus.open ? colors.error : colors.success,
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
  final AppSemanticColors colors;
  final VoidCallback onTap;

  const _HealthChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.15) : colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? c : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? c : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CameraHealthCard extends StatelessWidget {
  final CameraModel camera;
  final AppSemanticColors colors;

  const _CameraHealthCard({required this.camera, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${camera.fps} FPS • ${camera.latencyMs}ms • ${camera.sourceType == CameraSourceType.rtsp ? "RTSP" : "P2P"}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
