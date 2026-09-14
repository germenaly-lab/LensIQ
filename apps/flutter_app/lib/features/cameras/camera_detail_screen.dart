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
import '../../widgets/error_view.dart';

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
              child: cameraProv.isStreamingLoading
                  ? const LoadingView(message: 'Connecting to Streaming Gateway & negotiating WebRTC...')
                  : session == null
                      ? ErrorView(
                          message: cameraProv.errorMessage ?? 'Unable to start stream session',
                          onRetry: () => cameraProv.startStream(user, widget.cameraId),
                        )
                      : Stack(
                          children: [
                            // Simulated Video Feed Content
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    camera.isHikvision ? Icons.cloud_done : Icons.videocam,
                                    size: 64,
                                    color: AppColors.primary.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${session.protocol.toUpperCase()} STREAM ACTIVE',
                                    style: AppTypography.h3.copyWith(color: Colors.white, letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Transcoded via LensIQ Gateway • Deduplicated Ingest',
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),

                            // Top In-Feed HUD Overlay
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'LIVE',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${session.fps} FPS • ${session.resolution} • ${session.codec.toUpperCase()}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Top Right Latency & Viewers
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.speed, size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${session.latencyMs} ms',
                                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.people_outline, size: 14, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${session.viewerCount}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom Controls Bar
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white),
                                      tooltip: 'Reconnect Source',
                                      onPressed: () => cameraProv.startStream(user, widget.cameraId),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Session: ${session.sessionId.substring(0, 16)}...',
                                      style: AppTypography.code.copyWith(color: Colors.white70, fontSize: 11),
                                    ),
                                    const Spacer(),
                                    if (session.demoMode)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DEMO MODE',
                                          style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 24),

            // Technical Stream & Security Telemetry
            if (session != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stream Gateway Security & Protocol Telemetry', style: AppTypography.h3),
                      const SizedBox(height: 14),
                      _TelemetryRow(label: 'Playback Protocol', value: session.protocol.toUpperCase()),
                      _TelemetryRow(label: 'Connection State', value: session.connectionStatus.toUpperCase()),
                      _TelemetryRow(label: 'Single Ingest Deduplication', value: 'Active (1 pipeline for branch)'),
                      _TelemetryRow(label: 'Session Ephemeral Token', value: '${session.token.substring(0, 24)}... (HMAC Signed)'),
                      _TelemetryRow(
                        label: 'Client Security Guarantee',
                        value: 'Zero Credential Exposure (Raw passwords & Hikvision keys hidden)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
