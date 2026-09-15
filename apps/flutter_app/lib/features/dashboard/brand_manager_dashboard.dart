import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/user_profile.dart';
import '../../models/camera.dart';
import '../../models/incident.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/severity_badge.dart';
import 'widgets/metric_card.dart';

class BrandManagerDashboard extends StatefulWidget {
  const BrandManagerDashboard({Key? key}) : super(key: key);

  @override
  State<BrandManagerDashboard> createState() => _BrandManagerDashboardState();
}

class _BrandManagerDashboardState extends State<BrandManagerDashboard> {
  String? _selectedBranchId;
  String? _selectedCameraId;
  IncidentSeverity? _selectedSeverity;
  IncidentStatus? _selectedStatus;
  DateTimeRange? _selectedDateRange;

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

  void _resetFilters() {
    setState(() {
      _selectedBranchId = null;
      _selectedCameraId = null;
      _selectedSeverity = null;
      _selectedStatus = null;
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final incidentProvider = context.watch<IncidentProvider>();
    final cameraProvider = context.watch<CameraProvider>();
    final adminProvider = context.watch<AdminProvider>();

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Scoped cameras and branches for this brand ONLY
    final brandCameras = cameraProvider.cameras.where((c) => c.brandId == user.brandId).toList();
    final brandBranches = adminProvider.branches.where((b) => b.brandId == user.brandId).toList();

    // Filtered Incidents for this brand
    var brandIncidents = incidentProvider.rawIncidents.where((i) => i.brandId == user.brandId).toList();

    if (_selectedBranchId != null) {
      brandIncidents = brandIncidents.where((i) => i.branchId == _selectedBranchId).toList();
    }
    if (_selectedCameraId != null) {
      brandIncidents = brandIncidents.where((i) => i.cameraId == _selectedCameraId).toList();
    }
    if (_selectedSeverity != null) {
      brandIncidents = brandIncidents.where((i) => i.severity == _selectedSeverity).toList();
    }
    if (_selectedStatus != null) {
      brandIncidents = brandIncidents.where((i) => i.status == _selectedStatus).toList();
    }
    if (_selectedDateRange != null) {
      brandIncidents = brandIncidents.where((i) {
        return i.timestamp.isAfter(_selectedDateRange!.start) &&
            i.timestamp.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    final activeIncidents = brandIncidents.where((i) => i.status == IncidentStatus.open).toList();
    final resolvedIncidents = brandIncidents.where((i) => i.status == IncidentStatus.resolved).toList();
    final onlineCamerasCount = brandCameras.where((c) => c.isOnline).length;
    final offlineCamerasCount = brandCameras.where((c) => !c.isOnline).length;
    final uptimePercentage = brandCameras.isEmpty
        ? 100.0
        : (onlineCamerasCount / brandCameras.length * 100.0);

    final isMobile = ResponsiveUtil.isMobile(context);

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Brand Header
            _buildBrandHeader(user, isMobile),
            const SizedBox(height: 24),

            // 2. Executive Metrics Row
            _buildMetricsGrid(
              brandBranchesCount: brandBranches.length,
              onlineCamerasCount: onlineCamerasCount,
              offlineCamerasCount: offlineCamerasCount,
              activeIncidentsCount: activeIncidents.length,
              uptimePercentage: uptimePercentage,
              isMobile: isMobile,
            ),
            const SizedBox(height: 24),

            // 3. Multi-Filter Bar (Branch, Camera, Severity, Status, Date)
            _buildFilterCard(brandBranches, brandCameras),
            const SizedBox(height: 24),

            // 4. Main Body: Incident Feed + Camera Health & Branches
            if (isMobile) ...[
              _buildActiveIncidentsSection(activeIncidents),
              const SizedBox(height: 24),
              _buildBranchesSection(brandBranches),
              const SizedBox(height: 24),
              _buildCameraHealthSection(brandCameras),
              const SizedBox(height: 24),
              _buildIncidentHistorySection(resolvedIncidents),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Active Incidents + Resolution History
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActiveIncidentsSection(activeIncidents),
                        const SizedBox(height: 24),
                        _buildIncidentHistorySection(resolvedIncidents),
                        const SizedBox(height: 24),
                        _buildAiEventsSection(brandIncidents),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Branches List & Camera Health
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBranchesSection(brandBranches),
                        const SizedBox(height: 24),
                        _buildCameraHealthSection(brandCameras),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader(UserProfile user, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.brandName ?? 'Brand Dashboard', style: AppTypography.h2),
                          Text(user.companyName ?? 'Ego Retail Holding', style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPill('ROLE: BRAND MANAGER', AppColors.primary),
                    _buildPill('SCOPE: ASSIGNED BRAND ONLY', AppColors.secondary),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.brandName ?? 'Brand Dashboard', style: AppTypography.h1),
                          const SizedBox(width: 12),
                          _buildPill('BRAND MANAGER', AppColors.primary),
                          const SizedBox(width: 8),
                          _buildPill('RESTRICTED ACCESS', AppColors.secondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoring branches and cameras under ${user.brandName} (${user.companyName ?? "Ego Holding"}). Cross-brand access disabled by RLS.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  tooltip: 'Refresh Data',
                  onPressed: _loadData,
                ),
              ],
            ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int brandBranchesCount,
    required int onlineCamerasCount,
    required int offlineCamerasCount,
    required int activeIncidentsCount,
    required double uptimePercentage,
    required bool isMobile,
  }) {
    final cards = [
      MetricCard(
        title: 'Brand Branches',
        value: '$brandBranchesCount',
        subtitle: 'Assigned brand stores',
        icon: Icons.storefront,
        color: AppColors.primary,
      ),
      MetricCard(
        title: 'Online Cameras',
        value: '$onlineCamerasCount',
        subtitle: '$offlineCamerasCount offline / warning',
        icon: Icons.videocam,
        color: AppColors.success,
      ),
      MetricCard(
        title: 'Active Incidents',
        value: '$activeIncidentsCount',
        subtitle: activeIncidentsCount > 0 ? 'Requires attention' : 'All quiet',
        icon: Icons.warning_amber_rounded,
        color: activeIncidentsCount > 0 ? AppColors.error : AppColors.success,
      ),
      MetricCard(
        title: 'Camera Uptime',
        value: '${uptimePercentage.toStringAsFixed(1)}%',
        subtitle: 'Brand fleet availability',
        icon: Icons.speed,
        color: AppColors.secondary,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _buildFilterCard(List<BranchModel> branches, List<CameraModel> cameras) {
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
          Row(
            children: [
              const Icon(Icons.filter_list, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Brand Incident & Camera Filters', style: AppTypography.h3),
              const Spacer(),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Branch Filter
              DropdownButton<String?>(
                value: _selectedBranchId,
                hint: const Text('All Branches', style: TextStyle(fontSize: 13)),
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Branches')),
                  ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                ],
                onChanged: (val) => setState(() => _selectedBranchId = val),
              ),

              // Camera Filter
              DropdownButton<String?>(
                value: _selectedCameraId,
                hint: const Text('All Cameras', style: TextStyle(fontSize: 13)),
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Cameras')),
                  ...cameras.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) => setState(() => _selectedCameraId = val),
              ),

              // Severity Filter
              DropdownButton<IncidentSeverity?>(
                value: _selectedSeverity,
                hint: const Text('All Severities', style: TextStyle(fontSize: 13)),
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Severities')),
                  DropdownMenuItem(value: IncidentSeverity.critical, child: Text('Critical')),
                  DropdownMenuItem(value: IncidentSeverity.warning, child: Text('Warning')),
                  DropdownMenuItem(value: IncidentSeverity.info, child: Text('Info')),
                ],
                onChanged: (val) => setState(() => _selectedSeverity = val),
              ),

              // Status Filter
              DropdownButton<IncidentStatus?>(
                value: _selectedStatus,
                hint: const Text('All Statuses', style: TextStyle(fontSize: 13)),
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: IncidentStatus.open, child: Text('Open / Active')),
                  DropdownMenuItem(value: IncidentStatus.acknowledged, child: Text('Acknowledged')),
                  DropdownMenuItem(value: IncidentStatus.resolved, child: Text('Resolved')),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIncidentsSection(List<IncidentModel> incidents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text('Active Incidents (${incidents.length})', style: AppTypography.h3),
              const Spacer(),
              if (incidents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('ACTION REQUIRED', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Divider(height: 24),
          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No active incidents reported for this brand.', style: AppTypography.bodySmall)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final inc = incidents[index];
                return _buildIncidentCard(inc);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final provider = context.read<IncidentProvider>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: inc.isCritical ? AppColors.error.withOpacity(0.4) : AppColors.border,
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
                child: Text(inc.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(
                '${inc.timestamp.hour.toString().padLeft(2, '0')}:${inc.timestamp.minute.toString().padLeft(2, '0')}',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(inc.description, style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.storefront, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(inc.branchName, style: AppTypography.caption),
              const SizedBox(width: 12),
              Icon(Icons.videocam, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(inc.cameraName, style: AppTypography.caption),
              const Spacer(),
              if (inc.status == IncidentStatus.open) ...[
                OutlinedButton(
                  onPressed: () => provider.acknowledgeIncident(inc.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 28),
                  ),
                  child: const Text('Acknowledge', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showResolveDialog(inc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 28),
                  ),
                  child: const Text('Resolve', style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(IncidentModel incident) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve Incident: ${incident.title}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Resolution Note',
            hintText: 'e.g. Cashier returned to station; queue cleared.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<IncidentProvider>().resolveIncident(incident.id, noteController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesSection(List<BranchModel> branches) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Brand Branches (${branches.length})', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = branches[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${b.code} • ${b.address}', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${b.onlineCameraCount}/${b.cameraCount} Online', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: b.isOperational
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            b.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: b.isOperational ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraHealthSection(List<CameraModel> cameras) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('Camera Health (${cameras.length})', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cameras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cam = cameras[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    StatusBadge(status: cam.status),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cam.name, style: AppTypography.bodyMedium),
                          Text('${cam.branchName} • ${cam.sourceTypeDisplayName}', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text(cam.isOnline ? '${cam.fps} FPS' : 'OFFLINE', style: AppTypography.caption),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentHistorySection(List<IncidentModel> resolved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Incident History & Resolutions (${resolved.length})', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 24),
          if (resolved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No resolved incidents in current filter scope.', style: AppTypography.bodySmall)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resolved.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inc = resolved[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(child: Text(inc.title, style: AppTypography.bodyMedium)),
                          Text(inc.status.name.toUpperCase(), style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (inc.resolutionNote != null && inc.resolutionNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Note: ${inc.resolutionNote}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAiEventsSection(List<IncidentModel> incidents) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text('AI Vision Events Log', style: AppTypography.h3),
            ],
          ),
          const Divider(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incidents.length > 5 ? 5 : incidents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final inc = incidents[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: inc.isCritical ? AppColors.error : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Trigger: ${inc.ruleType} (${inc.cameraName})', style: AppTypography.bodySmall),
                          Text('Confidence: ${((inc.confidence ?? 0.95) * 100).toStringAsFixed(0)}% • Duration: ${inc.durationSeconds ?? 0}s', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Text('${inc.timestamp.hour}:${inc.timestamp.minute.toString().padLeft(2, '0')}', style: AppTypography.caption),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
