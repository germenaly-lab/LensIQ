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
import 'widgets/add_camera_dialog.dart';

class CameraListScreen extends StatefulWidget {
  const CameraListScreen({Key? key}) : super(key: key);

  @override
  State<CameraListScreen> createState() => _CameraListScreenState();
}

class _CameraListScreenState extends State<CameraListScreen> {
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final cameraProv = context.watch<CameraProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isDesktop = ResponsiveUtil.isDesktop(context);

    if (user == null) return const Scaffold(body: LoadingView());

    // Filter by search query
    final filteredCameras = cameraProv.cameras.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.locationDescription?.toLowerCase().contains(q) ?? false) ||
          (c.branchName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/cameras',
      title: 'Multi-Source Cameras',
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter & Search Controls Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Search box
                    Expanded(
                      flex: 2,
                      child: TextField(
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                          hintText: 'Search camera by name or location...',
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Source Type Segmented Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All (${cameraProv.totalCamerasCount})',
                            isSelected: cameraProv.filterSource == null,
                            onTap: () => cameraProv.setFilterSource(null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'RTSP (${cameraProv.rtspCamerasCount})',
                            isSelected: cameraProv.filterSource == CameraSourceType.rtsp,
                            onTap: () => cameraProv.setFilterSource(CameraSourceType.rtsp),
                            accentColor: AppColors.rtspBadge,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Hikvision P2P (${cameraProv.hikvisionCamerasCount})',
                            isSelected: cameraProv.filterSource == CameraSourceType.hikvisionP2p,
                            onTap: () => cameraProv.setFilterSource(CameraSourceType.hikvisionP2p),
                            accentColor: AppColors.hikvisionBadge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Camera Grid
            Expanded(
              child: cameraProv.isLoading
                  ? const LoadingView(message: 'Loading multi-source camera inventory...')
                  : filteredCameras.isEmpty
                      ? EmptyStateView(
                          title: 'No Cameras Found',
                          description: _searchQuery.isNotEmpty
                              ? 'No cameras matching "$_searchQuery". Try clearing your search.'
                              : 'No cameras provisioned under your authorization scope.',
                        )
                      : GridView.builder(
                          itemCount: filteredCameras.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : (ResponsiveUtil.isTablet(context) ? 2 : 1),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.35,
                          ),
                          itemBuilder: (context, index) {
                            final camera = filteredCameras[index];
                            return _CameraCard(
                              camera: camera,
                              onWatch: () => context.go('/cameras/${camera.id}'),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
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

  const _CameraCard({required this.camera, required this.onWatch});

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
                const Spacer(),
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
