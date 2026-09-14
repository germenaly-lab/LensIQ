import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/user_profile.dart';
import '../../models/camera.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/severity_badge.dart';
import '../../widgets/loading_view.dart';
import 'widgets/metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CameraProvider>().loadCameras(user);
        context.read<IncidentProvider>().loadData(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final cameraProv = context.watch<CameraProvider>();
    final incidentProv = context.watch<IncidentProvider>();

    if (user == null) return const Scaffold(body: LoadingView());

    final isDesktop = ResponsiveUtil.isDesktop(context);
    final summary = incidentProv.summary;

    return ResponsiveScaffold(
      currentRoute: '/dashboard',
      title: 'Operations Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Data',
          onPressed: () {
            cameraProv.loadCameras(user);
            incidentProv.loadData(user);
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await cameraProv.loadCameras(user);
          await incidentProv.loadData(user);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Role-Aware Welcome & Scope Banner
              _buildRoleScopeBanner(user),
              const SizedBox(height: 24),

              // 2. Metrics Grid
              _buildMetricsGrid(context, summary, cameraProv),
              const SizedBox(height: 28),

              // 3. Two-Column Operations Layout
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildCameraGridPreview(context, cameraProv.cameras)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildRecentIncidentsPanel(context, incidentProv.incidents)),
                  ],
                )
              else ...[
                _buildCameraGridPreview(context, cameraProv.cameras),
                const SizedBox(height: 24),
                _buildRecentIncidentsPanel(context, incidentProv.incidents),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleScopeBanner(UserProfile user) {
    String scopeLabel;
    IconData scopeIcon;

    switch (user.role) {
      case UserRole.superAdmin:
        scopeLabel = 'Full Enterprise Scope: All Tenants & Brands';
        scopeIcon = Icons.public;
        break;
      case UserRole.brandManager:
        scopeLabel = 'Brand Scope: ${user.brandName ?? "Ego Fashion"} (Retail KPIs & Cameras)';
        scopeIcon = Icons.store;
        break;
      case UserRole.branchSecurity:
        scopeLabel = 'Site Security: ${user.branchName ?? "Mall of Arabia Branch"} (Live Surveillance)';
        scopeIcon = Icons.local_police;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(scopeIcon, size: 20, color: AppColors.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              scopeLabel,
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, size: 12, color: AppColors.success),
                SizedBox(width: 4),
                Text('AI Vision Online', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, dynamic summary, CameraProvider cameraProv) {
    final isDesktop = ResponsiveUtil.isDesktop(context);
    final columns = isDesktop ? 4 : 2;

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isDesktop ? 1.6 : 1.4,
      children: [
        MetricCard(
          title: 'Surveillance Cameras',
          value: '${cameraProv.onlineCount}/${cameraProv.totalCamerasCount}',
          subtitle: '${cameraProv.rtspCamerasCount} RTSP • ${cameraProv.hikvisionCamerasCount} Hikvision P2P',
          icon: Icons.videocam_outlined,
          color: AppColors.primary,
          onTap: () => context.go('/cameras'),
        ),
        MetricCard(
          title: 'Cashier Empty Alerts',
          value: '${summary.cashierAlerts}',
          subtitle: '>180s Unattended Counters',
          icon: Icons.timer_outlined,
          color: AppColors.warning,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'Critical Incidents',
          value: '${summary.criticalAlerts}',
          subtitle: 'Active Security Breaches',
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          onTap: () => context.go('/incidents'),
        ),
        MetricCard(
          title: 'System Uptime',
          value: '${summary.networkUptimePercentage}%',
          subtitle: 'Streaming Gateway Active',
          icon: Icons.network_check_outlined,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildCameraGridPreview(BuildContext context, List<CameraModel> cameras) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Camera Surveillance', style: AppTypography.h3),
                TextButton.icon(
                  onPressed: () => context.go('/cameras'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cameras.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No cameras provisioned in this branch.')),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cameras.take(4).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final cam = cameras[index];
                  return _buildMiniCameraCard(context, cam);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCameraCard(BuildContext context, CameraModel camera) {
    return InkWell(
      onTap: () => context.go('/cameras/${camera.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    camera.name,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: camera.status),
              ],
            ),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SourceTypeBadge(sourceType: camera.sourceType),
                Text(
                  camera.streamProfile.toUpperCase(),
                  style: AppTypography.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIncidentsPanel(BuildContext context, List<IncidentModel> incidents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Event Stream', style: AppTypography.h3),
                TextButton.icon(
                  onPressed: () => context.go('/incidents'),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (incidents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No active incidents recorded.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incidents.take(4).length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final inc = incidents[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: SeverityBadge(severity: inc.severity),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${inc.cameraName} • ${inc.description}',
                              style: AppTypography.caption.copyWith(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
