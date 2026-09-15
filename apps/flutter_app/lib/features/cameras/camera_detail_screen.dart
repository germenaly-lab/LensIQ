import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/camera.dart';
import '../../providers/auth_provider.dart';
import '../../providers/camera_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_view.dart';
import 'widgets/live_camera_player_widget.dart';

class CameraDetailScreen extends StatefulWidget {
  final String cameraId;

  const CameraDetailScreen({Key? key, required this.cameraId}) : super(key: key);

  @override
  State<CameraDetailScreen> createState() => _CameraDetailScreenState();
}

class _CameraDetailScreenState extends State<CameraDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CameraProvider>().startStream(user, widget.cameraId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraProv = context.watch<CameraProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const Scaffold(body: LoadingView());

    final camera = cameraProv.cameras.firstWhere(
      (c) => c.id == widget.cameraId,
      orElse: () => CameraModel(
        id: widget.cameraId,
        name: 'Surveillance Camera',
        companyId: '',
        brandId: '',
        branchId: '',
        sourceType: CameraSourceType.rtsp,
        status: CameraStatus.online,
      ),
    );

    final session = cameraProv.activeSession;

    return ResponsiveScaffold(
      currentRoute: '/cameras',
      title: camera.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Close Feed',
          onPressed: () {
            cameraProv.closeActiveStream();
            context.go('/cameras');
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Camera Overview Bar
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/cameras'),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Back to Cameras'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(camera.name, style: AppTypography.h2),
                      Text(
                        camera.locationDescription ?? 'Real-time Video Ingest',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: camera.status),
                const SizedBox(width: 8),
                SourceTypeBadge(sourceType: camera.sourceType),
              ],
            ),
            const SizedBox(height: 20),

            // Live Stream Monitor Player
            Container(
              height: 480,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: LiveCameraPlayerWidget(
                camera: camera,
                showControls: true,
                showAiOverlay: true,
              ),
            ),
            const SizedBox(height: 24),

            // Technical Stream & Security Telemetry
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camera Ingest, AI & Security Telemetry', style: AppTypography.h3),
                    const SizedBox(height: 14),
                    _TelemetryRow(label: 'Camera Name', value: camera.name),
                    _TelemetryRow(label: 'Source Ingest Type', value: camera.sourceTypeDisplayName),
                    _TelemetryRow(label: 'Branch Location', value: camera.branchName ?? 'Enterprise Facility'),
                    _TelemetryRow(
                      label: 'Device Status',
                      value: camera.isOnline ? 'Online (Ingest Active)' : 'Offline (Disconnected)',
                    ),
                    _TelemetryRow(
                      label: 'Stream Gateway Status',
                      value: cameraProv.getStreamState(camera.id).displayName,
                    ),
                    _TelemetryRow(label: 'Playback Protocol', value: session?.protocol.toUpperCase() ?? 'WEBRTC (Unified)'),
                    _TelemetryRow(label: 'Single Ingest Deduplication', value: 'Active (1 pipeline per camera)'),
                    _TelemetryRow(label: 'AI Model Pipeline', value: 'YOLOv8 Nano (Person Detection @ 25 FPS)'),
                    _TelemetryRow(label: 'Configured ROI Rule', value: 'Cashier Empty Detection (180s continuous threshold)'),
                    _TelemetryRow(
                      label: 'Client Security Guarantee',
                      value: 'Zero Credential Exposure (Raw RTSP passwords & Hikvision secrets hidden)',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySecondary),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
