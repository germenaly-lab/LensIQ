import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../core/localization/app_locale_provider.dart';
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
    final colors = context.colors;

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
            _buildBrandHeader(user, isMobile, colors),
            const SizedBox(height: 24),

            // 2. Executive Metrics Row
            _buildMetricsGrid(
              brandBranchesCount: brandBranches.length,
              onlineCamerasCount: onlineCamerasCount,
              offlineCamerasCount: offlineCamerasCount,
              activeIncidentsCount: activeIncidents.length,
              uptimePercentage: uptimePercentage,
              isMobile: isMobile,
              colors: colors,
            ),
            const SizedBox(height: 24),

            // 3. Multi-Filter Bar
            _buildFilterCard(brandBranches, brandCameras, colors),
            const SizedBox(height: 24),

            // 4. Main Body: Incident Feed + Camera Health & Branches
            if (isMobile) ...[
              _buildActiveIncidentsSection(activeIncidents, colors),
              const SizedBox(height: 24),
              _buildBranchesSection(brandBranches, colors),
              const SizedBox(height: 24),
              _buildCameraHealthSection(brandCameras, colors),
              const SizedBox(height: 24),
              _buildIncidentHistorySection(resolvedIncidents, colors),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActiveIncidentsSection(activeIncidents, colors),
                        const SizedBox(height: 24),
                        _buildIncidentHistorySection(resolvedIncidents, colors),
                        const SizedBox(height: 24),
                        _buildAiEventsSection(brandIncidents, colors),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBranchesSection(brandBranches, colors),
                        const SizedBox(height: 24),
                        _buildCameraHealthSection(brandCameras, colors),
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

  Widget _buildBrandHeader(UserProfile user, bool isMobile, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
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
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.storefront, color: colors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.brandName ?? 'Brand Operations', style: AppTypography.h2Of(context).copyWith(fontSize: 18)),
                          Text(user.companyName ?? 'Ego Retail Holding', style: AppTypography.captionOf(context)),
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
                    _buildPill(context.tr('Brand Manager'), colors.primary),
                    _buildPill(context.tr('Brand Scoped'), colors.secondary),
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
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.storefront, color: colors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.brandName ?? 'Brand Operations', style: AppTypography.h2Of(context).copyWith(fontSize: 20)),
                          const SizedBox(width: 12),
                          _buildPill(context.tr('Brand Manager'), colors.primary),
                          const SizedBox(width: 8),
                          _buildPill(context.tr('Brand Scoped'), colors.secondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoring branches and cameras under ${user.brandName} (${user.companyName ?? "Holding"}). Multi-tenancy RLS isolation active.',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
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
    required AppSemanticColors colors,
  }) {
    final cards = [
      MetricCard(
        title: 'Branches',
        value: '$brandBranchesCount',
        subtitle: 'Assigned brand stores',
        icon: Icons.storefront,
        color: colors.primary,
      ),
      MetricCard(
        title: 'Online Cameras',
        value: '$onlineCamerasCount',
        subtitle: '$offlineCamerasCount offline',
        icon: Icons.videocam,
        color: colors.success,
      ),
      MetricCard(
        title: 'Active Incidents',
        value: '$activeIncidentsCount',
        subtitle: activeIncidentsCount > 0 ? 'Requires attention' : 'All quiet',
        icon: Icons.warning_amber_rounded,
        color: activeIncidentsCount > 0 ? colors.error : colors.success,
      ),
      MetricCard(
        title: 'Camera Health',
        value: '${uptimePercentage.toStringAsFixed(1)}%',
        subtitle: 'Brand fleet availability',
        icon: Icons.speed,
        color: colors.secondary,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _buildFilterCard(List<BranchModel> branches, List<CameraModel> cameras, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(context.tr('Filter'), style: AppTypography.h3Of(context).copyWith(fontSize: 14)),
              const Spacer(),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(context.tr('Clear Filters'), style: const TextStyle(fontSize: 12)),
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
                hint: Text(context.tr('All Branches'), style: const TextStyle(fontSize: 12)),
                underline: const SizedBox(),
                dropdownColor: colors.surfaceElevated,
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('All Branches'))),
                  ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                ],
                onChanged: (val) => setState(() => _selectedBranchId = val),
              ),

              // Camera Filter
              DropdownButton<String?>(
                value: _selectedCameraId,
                hint: Text(context.tr('All Sources'), style: const TextStyle(fontSize: 12)),
                underline: const SizedBox(),
                dropdownColor: colors.surfaceElevated,
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('All Sources'))),
                  ...cameras.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) => setState(() => _selectedCameraId = val),
              ),

              // Severity Filter
              DropdownButton<IncidentSeverity?>(
                value: _selectedSeverity,
                hint: Text(context.tr('All Severities'), style: const TextStyle(fontSize: 12)),
                underline: const SizedBox(),
                dropdownColor: colors.surfaceElevated,
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('All Severities'))),
                  DropdownMenuItem(value: IncidentSeverity.critical, child: Text(context.tr('Critical'))),
                  DropdownMenuItem(value: IncidentSeverity.warning, child: Text(context.tr('Warning'))),
                  DropdownMenuItem(value: IncidentSeverity.info, child: Text(context.tr('Info'))),
                ],
                onChanged: (val) => setState(() => _selectedSeverity = val),
              ),

              // Status Filter
              DropdownButton<IncidentStatus?>(
                value: _selectedStatus,
                hint: Text(context.tr('All Statuses'), style: const TextStyle(fontSize: 12)),
                underline: const SizedBox(),
                dropdownColor: colors.surfaceElevated,
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('All Statuses'))),
                  DropdownMenuItem(value: IncidentStatus.open, child: Text(context.tr('Open'))),
                  DropdownMenuItem(value: IncidentStatus.acknowledged, child: Text(context.tr('Acknowledged'))),
                  DropdownMenuItem(value: IncidentStatus.resolved, child: Text(context.tr('Resolved'))),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIncidentsSection(List<IncidentModel> incidents, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: colors.error, size: 20),
              const SizedBox(width: 8),
              Text('${context.tr("Active Incidents")} (${incidents.length})', style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
              const Spacer(),
              if (incidents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    context.tr('Critical').toUpperCase(),
                    style: TextStyle(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          Divider(height: 24, color: colors.borderSubtle),
          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(context.tr('No incidents found'), style: TextStyle(color: colors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inc = incidents[index];
                return _buildIncidentCard(inc, colors);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc, AppSemanticColors colors) {
    final provider = context.read<IncidentProvider>();
    final accentBorder = inc.isCritical ? colors.error : (inc.isWarning ? colors.warning : colors.info);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(color: accentBorder, width: 4),
          top: BorderSide(color: colors.borderSubtle),
          bottom: BorderSide(color: colors.borderSubtle),
          end: BorderSide(color: colors.borderSubtle),
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
                  context.tr(inc.title),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
                ),
              ),
              Text(
                '${inc.timestamp.hour.toString().padLeft(2, '0')}:${inc.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(inc.description, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.storefront, size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(inc.branchName, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.videocam, size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(inc.cameraName, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              const Spacer(),
              if (inc.status == IncidentStatus.open) ...[
                OutlinedButton(
                  onPressed: () => provider.acknowledgeIncident(inc.id),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 28),
                    side: BorderSide(color: colors.border),
                  ),
                  child: Text(context.tr('Acknowledge'), style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showResolveDialog(inc, colors),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(60, 28),
                  ),
                  child: Text(context.tr('Resolve'), style: const TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(IncidentModel incident, AppSemanticColors colors) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('${context.tr("Resolve")}: ${incident.title}', style: AppTypography.h3Of(context)),
        content: TextField(
          controller: noteController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: context.tr('Security Notes'),
            hintText: 'e.g. Cashier returned to station; queue cleared.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Cancel'), style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<IncidentProvider>().resolveIncident(incident.id, noteController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('Confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesSection(List<BranchModel> branches, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text('${context.tr("Branches")} (${branches.length})', style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
            ],
          ),
          Divider(height: 24, color: colors.borderSubtle),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = branches[index];
              final isOp = b.isOperational;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('${b.code} • ${b.address}', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${b.onlineCameraCount}/${b.cameraCount} ${context.tr("Online")}',
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOp ? colors.success.withOpacity(0.12) : colors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            b.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOp ? colors.success : colors.error,
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

  Widget _buildCameraHealthSection(List<CameraModel> cameras, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam, color: colors.secondary, size: 20),
              const SizedBox(width: 8),
              Text('${context.tr("Camera Health")} (${cameras.length})', style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
            ],
          ),
          Divider(height: 24, color: colors.borderSubtle),
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
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    StatusBadge(status: cam.status),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cam.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                          Text(
                            '${cam.branchName} • ${cam.sourceTypeDisplayName}',
                            style: TextStyle(fontSize: 10, color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      cam.isOnline ? '${cam.fps} FPS' : context.tr('Offline').toUpperCase(),
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
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

  Widget _buildIncidentHistorySection(List<IncidentModel> resolved, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: colors.success, size: 20),
              const SizedBox(width: 8),
              Text('${context.tr("Resolved Incidents")} (${resolved.length})', style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
            ],
          ),
          Divider(height: 24, color: colors.borderSubtle),
          if (resolved.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(context.tr('No data found'), style: TextStyle(color: colors.textMuted)),
              ),
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
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: colors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(inc.title),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
                            ),
                          ),
                          Text(
                            context.tr(inc.status.name).toUpperCase(),
                            style: TextStyle(color: colors.success, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (inc.resolutionNote != null && inc.resolutionNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Note: ${inc.resolutionNote}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
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

  Widget _buildAiEventsSection(List<IncidentModel> incidents, AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy_outlined, color: colors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(context.tr('AI Detection Rules'), style: AppTypography.h3Of(context).copyWith(fontSize: 15)),
            ],
          ),
          Divider(height: 24, color: colors.borderSubtle),
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
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: inc.isCritical ? colors.error : colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Trigger: ${inc.ruleType} (${inc.cameraName})',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary),
                          ),
                          Text(
                            'Confidence: ${((inc.confidence ?? 0.95) * 100).toStringAsFixed(0)}% • Duration: ${inc.durationSeconds ?? 0}s',
                            style: TextStyle(fontSize: 10, color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${inc.timestamp.hour}:${inc.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
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
}
