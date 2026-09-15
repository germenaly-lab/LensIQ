import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_util.dart';
import '../../models/camera.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/loading_view.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import 'widgets/add_camera_dialog.dart';
import 'widgets/live_camera_player_widget.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({Key? key}) : super(key: key);

  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  String _searchQuery = '';
  bool _isLiveMonitor = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CameraProvider>().loadCameras(user);
      }
    });
  }

  void _openAddCameraDialog(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AddCameraDialog(
        onAdd: (newCamera) {
          context.read<CameraProvider>().addCamera(user, newCamera);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera "${newCamera.name}" successfully provisioned!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  void _simulateCashierIncident(BuildContext context, CameraModel camera) {
    final incident = IncidentModel(
      id: 'inc_cashier_sim_${DateTime.now().millisecondsSinceEpoch}',
      cameraId: camera.id,
      cameraName: camera.name,
      brandId: camera.brandId,
      brandName: camera.brandName ?? 'Ego Fashion',
      branchId: camera.branchId,
      branchName: camera.branchName ?? 'City Stars Mall',
      ruleType: 'cashier_empty',
      severity: IncidentSeverity.critical,
      status: IncidentStatus.open,
      title: 'Cashier Area Empty',
      description: 'Cashier counter unattended for 3 continuous minutes (180s) on ${camera.name}.',
      timestamp: DateTime.now(),
      durationSeconds: 180,
      confidence: 0.98,
    );
    context.read<IncidentProvider>().addRealtimeIncident(incident);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CRITICAL ALERT: Cashier Empty (180s) dispatched on ${camera.name}!'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraProv = context.watch<CameraProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDesktop = ResponsiveUtil.isDesktop(context);

    if (user == null) return const Scaffold(body: LoadingView());

    // Filter cameras according to search & source
    final filteredCameras = cameraProv.cameras.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.locationDescription?.toLowerCase().contains(q) ?? false) ||
          (c.branchName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/cameras',
      title: 'Live CCTV Monitoring',
      actions: [
        if (user.role == UserRole.superAdmin || user.role == UserRole.brandManager)
          ElevatedButton.icon(
            onPressed: () => _openAddCameraDialog(context, user),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Cameras',
          onPressed: () => cameraProv.loadCameras(user),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Monitor Mode Switch + Source Filters + Grid (1/4/9) Layout
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Mode Toggle: Live Monitor vs Inventory Directory
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModeToggleButton(
                            icon: Icons.videocam,
                            label: 'Live Grid Monitor',
                            isSelected: _isLiveMonitor,
                            onTap: () => setState(() => _isLiveMonitor = true),
                          ),
                          _ModeToggleButton(
                            icon: Icons.list_alt,
                            label: 'Camera Directory',
                            isSelected: !_isLiveMonitor,
                            onTap: () => setState(() => _isLiveMonitor = false),
                          ),
                        ],
                      ),
                    ),

                    // 1, 4, 9 Layout Buttons (Only in Live Monitor mode)
                    if (_isLiveMonitor)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GRID LAYOUT:',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _GridLayoutButton(
                            count: 1,
                            label: '1 CAM',
                            isSelected: cameraProv.gridLayout == 1,
                            onTap: () => cameraProv.setGridLayout(1),
                          ),
                          const SizedBox(width: 4),
                          _GridLayoutButton(
                            count: 4,
                            label: '4 CAMS (2x2)',
                            isSelected: cameraProv.gridLayout == 4,
                            onTap: () => cameraProv.setGridLayout(4),
                          ),
                          const SizedBox(width: 4),
                          _GridLayoutButton(
                            count: 9,
                            label: '9 CAMS (3x3)',
                            isSelected: cameraProv.gridLayout == 9,
                            onTap: () => cameraProv.setGridLayout(9),
                          ),
                        ],
                      ),

                    // Source Filters: All, RTSP, Hikvision P2P
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FilterChip(
                          label: 'All (${cameraProv.totalCamerasCount})',
                          isSelected: cameraProv.filterSource == null,
                          onTap: () => cameraProv.setFilterSource(null),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'RTSP (${cameraProv.rtspCamerasCount})',
                          isSelected: cameraProv.filterSource == CameraSourceType.rtsp,
                          onTap: () => cameraProv.setFilterSource(CameraSourceType.rtsp),
                          accentColor: AppColors.rtspBadge,
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Hikvision P2P (${cameraProv.hikvisionCamerasCount})',
                          isSelected: cameraProv.filterSource == CameraSourceType.hikvisionP2p,
                          onTap: () => cameraProv.setFilterSource(CameraSourceType.hikvisionP2p),
                          accentColor: AppColors.hikvisionBadge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // AI Cashier Empty Rule Simulation Banner
            if (_isLiveMonitor)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI PIPELINE RULE: 0 people in ROI -> 3-min countdown (180s) -> Critical Incident -> Supabase Realtime -> Alert on Dashboard. Person entry resets timer.',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (filteredCameras.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning, width: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _simulateCashierIncident(context, filteredCameras.first),
                        icon: const Icon(Icons.play_arrow, size: 12),
                        label: const Text('Simulate 180s Alert'),
                      ),
                  ],
                ),
              ),

            // Main Content Area: Live Multi-View Grid or Directory
            Expanded(
              child: cameraProv.isLoading
                  ? const LoadingView(message: 'Loading multi-source camera streams...')
                  : filteredCameras.isEmpty
                      ? EmptyStateView(
                          title: 'No Cameras Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No cameras matching "$_searchQuery". Try clearing your search.'
                              : 'No cameras provisioned under your authorization scope.',
                        )
                      : _isLiveMonitor
                          ? _buildLiveGrid(context, filteredCameras, cameraProv.gridLayout, isDesktop)
                          : _buildInventoryGrid(context, filteredCameras, cameraProv, isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveGrid(
    BuildContext context,
    List<CameraModel> cameras,
    int targetLayout,
    bool isDesktop,
  ) {
    // Slice cameras to matching layout count: 1, 4, or 9
    final activeCount = targetLayout.clamp(1, 9);
    final displayedCameras = cameras.take(activeCount).toList();

    int crossAxisCount;
    double childAspectRatio;

    if (targetLayout == 1) {
      crossAxisCount = 1;
      childAspectRatio = isDesktop ? 1.78 : 1.35;
    } else if (targetLayout == 4) {
      crossAxisCount = isDesktop ? 2 : (ResponsiveUtil.isTablet(context) ? 2 : 1);
      childAspectRatio = 1.45;
    } else {
      // 9 cameras
      crossAxisCount = isDesktop ? 3 : (ResponsiveUtil.isTablet(context) ? 2 : 1);
      childAspectRatio = 1.35;
    }

    return GridView.builder(
      itemCount: activeCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        if (index < displayedCameras.length) {
          final camera = displayedCameras[index];
          return LiveCameraPlayerWidget(
            key: ValueKey('live_cam_${camera.id}_$targetLayout'),
            camera: camera,
            isCompact: targetLayout == 9,
            showControls: true,
            showAiOverlay: true,
            onExpand: () => context.go('/cameras/${camera.id}'),
          );
        } else {
          // Placeholder empty slot
          return Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_outlined, size: 32, color: Colors.white24),
                  const SizedBox(height: 6),
                  Text(
                    'CH-0${index + 1} STANDBY',
                    style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildInventoryGrid(
    BuildContext context,
    List<CameraModel> cameras,
    CameraProvider cameraProv,
    bool isDesktop,
  ) {
    return Column(
      children: [
        // Search Box in Inventory View
        TextField(
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
            hintText: 'Search camera by name or branch location...',
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 14),

        Expanded(
          child: GridView.builder(
            itemCount: cameras.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : (ResponsiveUtil.isTablet(context) ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final camera = cameras[index];
              return _CameraCard(
                camera: camera,
                onWatch: () => context.go('/cameras/${camera.id}'),
                onEdit: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => _EditCameraDialog(
                      camera: camera,
                      onSave: (updated) => cameraProv.updateCamera(updated),
                    ),
                  );
                },
                onToggleEnabled: () => cameraProv.toggleCameraEnabled(camera.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final CameraModel camera;
  final VoidCallback onWatch;
  final VoidCallback onEdit;
  final VoidCallback onToggleEnabled;

  const _CameraCard({
    required this.camera,
    required this.onWatch,
    required this.onEdit,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    camera.name,
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: camera.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              camera.locationDescription ?? 'Standard Store Surveillance',
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    camera.isHikvision ? Icons.cloud_done_outlined : Icons.router_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      camera.isHikvision
                          ? 'Device: ${camera.hikDeviceId ?? "P2P Cloud"} (Ch ${camera.hikChannel ?? 1})'
                          : 'RTSP Stream: ${camera.streamProfile.toUpperCase()} Profile',
                      style: AppTypography.code.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SourceTypeBadge(sourceType: camera.sourceType),
                const SizedBox(width: 8),
                Text(
                  camera.enabled ? 'ENABLED' : 'DISABLED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: camera.enabled ? AppColors.success : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Camera',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    camera.enabled ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: camera.enabled ? AppColors.primary : AppColors.textMuted,
                  ),
                  tooltip: camera.enabled ? 'Disable Camera' : 'Enable Camera',
                  onPressed: onToggleEnabled,
                ),
                ElevatedButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.play_circle_fill, size: 16),
                  label: const Text('Live Stream'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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

class _EditCameraDialog extends StatefulWidget {
  final CameraModel camera;
  final Function(CameraModel updated) onSave;

  const _EditCameraDialog({required this.camera, required this.onSave});

  @override
  State<_EditCameraDialog> createState() => _EditCameraDialogState();
}

class _EditCameraDialogState extends State<_EditCameraDialog> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late String _streamProfile;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camera.name);
    _locationController = TextEditingController(text: widget.camera.locationDescription ?? '');
    _streamProfile = widget.camera.streamProfile;
    _enabled = widget.camera.enabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _submit() {
    final updated = widget.camera.copyWith(
      name: _nameController.text.trim(),
      locationDescription: _locationController.text.trim(),
      streamProfile: _streamProfile,
      enabled: _enabled,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Camera Settings', style: AppTypography.h2),
            const SizedBox(height: 6),
            Text(
              'Update surveillance parameters. Credentials remain securely stored in the Vault.',
              style: AppTypography.caption,
            ),
            const Divider(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Camera Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Zone / Location Description'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _streamProfile,
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Stream Profile'),
              items: const [
                DropdownMenuItem(value: 'main', child: Text('Main Stream (1080p Full Quality)')),
                DropdownMenuItem(value: 'sub', child: Text('Sub Stream (360p Low Bandwidth)')),
              ],
              onChanged: (val) => setState(() => _streamProfile = val ?? 'main'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Camera Enabled', style: AppTypography.bodyMedium),
              subtitle: const Text('Active for AI computer vision ingest', style: AppTypography.caption),
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridLayoutButton extends StatelessWidget {
  final int count;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GridLayoutButton({
    required this.count,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
