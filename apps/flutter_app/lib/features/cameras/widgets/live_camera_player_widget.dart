import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/camera.dart';
import '../../../models/incident.dart';
import '../../../models/stream_session.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/camera_provider.dart';
import '../../../providers/incident_provider.dart';
import '../../../widgets/status_badge.dart';

class LiveCameraPlayerWidget extends StatefulWidget {
  final CameraModel camera;
  final bool isCompact;
  final bool showControls;
  final bool showAiOverlay;
  final VoidCallback? onExpand;

  const LiveCameraPlayerWidget({
    Key? key,
    required this.camera,
    this.isCompact = false,
    this.showControls = true,
    this.showAiOverlay = true,
    this.onExpand,
  }) : super(key: key);

  @override
  State<LiveCameraPlayerWidget> createState() => _LiveCameraPlayerWidgetState();
}

class _LiveCameraPlayerWidgetState extends State<LiveCameraPlayerWidget> {
  Timer? _ticker;
  bool _overlayVisible = true;
  bool _cashierOccupied = true;
  int _emptyElapsedSeconds = 0;
  bool _hasTriggeredAlert = false;
  int _simulatedPeopleCount = 1;

  @override
  void initState() {
    super.initState();
    _overlayVisible = widget.showAiOverlay;

    // Start stream session on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStream();
    });

    // 1-second simulation clock for Cashier Empty 180s (3-min) rule & detection ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _tickSimulation();
    });
  }

  void _initStream() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && widget.camera.isOnline) {
      context.read<CameraProvider>().startCameraStream(user, widget.camera.id);
    }
  }

  void _tickSimulation() {
    if (!widget.camera.isOnline) return;

    if (!_cashierOccupied) {
      setState(() {
        _emptyElapsedSeconds += 1;
        _simulatedPeopleCount = 0;
      });

      // 180 seconds (3 continuous minutes) threshold trigger
      if (_emptyElapsedSeconds >= 180 && !_hasTriggeredAlert) {
        _hasTriggeredAlert = true;
        _fireCashierEmptyIncident();
      }
    } else {
      if (_emptyElapsedSeconds > 0) {
        // Reset timer when person enters ROI before threshold
        setState(() {
          _emptyElapsedSeconds = 0;
          _hasTriggeredAlert = false;
          _simulatedPeopleCount = 1;
        });
      }
    }
  }

  void _fireCashierEmptyIncident() {
    final incidentProv = context.read<IncidentProvider>();
    final newIncident = IncidentModel(
      id: 'inc_cashier_${widget.camera.id}_${DateTime.now().millisecondsSinceEpoch}',
      cameraId: widget.camera.id,
      cameraName: widget.camera.name,
      brandId: widget.camera.brandId,
      brandName: widget.camera.brandName ?? 'Retail Brand',
      branchId: widget.camera.branchId,
      branchName: widget.camera.branchName ?? 'Branch',
      ruleType: 'cashier_empty',
      severity: IncidentSeverity.critical,
      status: IncidentStatus.open,
      title: 'Cashier Area Empty',
      description: 'Cashier counter unattended for 3 continuous minutes (180s) on ${widget.camera.name}.',
      timestamp: DateTime.now(),
      durationSeconds: 180,
      confidence: 0.98,
    );
    incidentProv.addRealtimeIncident(newIncident);
  }

  CameraProvider? _cameraProvider;
  UserProfile? _currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraProvider = context.read<CameraProvider>();
    _currentUser = context.read<AuthProvider>().currentUser;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Stop and release stream session on unmount to optimize server bandwidth
    if (_currentUser != null && _cameraProvider != null) {
      _cameraProvider!.stopCameraStream(_currentUser!, widget.camera.id);
    }
    super.dispose();
  }

  void _toggleCashierPresence() {
    setState(() {
      _cashierOccupied = !_cashierOccupied;
      if (_cashierOccupied) {
        _emptyElapsedSeconds = 0;
        _hasTriggeredAlert = false;
        _simulatedPeopleCount = 1;
      } else {
        _simulatedPeopleCount = 0;
      }
    });
  }

  void _fastForwardTo178s() {
    setState(() {
      _cashierOccupied = false;
      _emptyElapsedSeconds = 178;
      _simulatedPeopleCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraProv = context.watch<CameraProvider>();
    final streamState = cameraProv.getStreamState(widget.camera.id);
    final session = cameraProv.getActiveSessionForCamera(widget.camera.id);
    final user = context.watch<AuthProvider>().currentUser;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Stream Canvas or Fallback View
            _buildCanvasContent(streamState, session, user),

            // Layer 2: YOLOv8 Person & ROI Overlay
            if (streamState == LiveStreamState.online && _overlayVisible)
              Positioned.fill(
                child: CustomPaint(
                  painter: _AiDetectionPainter(
                    isOccupied: _cashierOccupied,
                    emptyDurationSeconds: _emptyElapsedSeconds,
                    isHikvision: widget.camera.isHikvision,
                    isCompact: widget.isCompact,
                  ),
                ),
              ),

            // Layer 3: Top HUD (Status, Live, Source Type, People Count)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _buildTopHud(streamState, session),
            ),

            // Layer 4: Cashier Empty 3-Minute Rule Alert Banner
            if (_hasTriggeredAlert)
              Positioned(
                top: 42,
                left: 12,
                right: 12,
                child: _buildAlertBanner(),
              ),

            // Layer 5: Bottom Stream Controls & Metadata
            if (widget.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(streamState, user),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasContent(
    LiveStreamState state,
    StreamSessionModel? session,
    UserProfile? user,
  ) {
    switch (state) {
      case LiveStreamState.offline:
      case LiveStreamState.deviceUnavailable:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 38, color: AppColors.error),
              const SizedBox(height: 8),
              Text(
                'DEVICE OFFLINE',
                style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Camera signal disconnected from Gateway',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        );

      case LiveStreamState.connecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'Connecting Gateway (${widget.camera.sourceTypeDisplayName})...',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),
        );

      case LiveStreamState.reconnecting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning),
              ),
              const SizedBox(height: 10),
              const Text(
                'Reconnecting Source...',
                style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );

      case LiveStreamState.streamError:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppColors.error),
              const SizedBox(height: 6),
              const Text(
                'Stream Error',
                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (user != null)
                TextButton.icon(
                  onPressed: () => context.read<CameraProvider>().reconnectCameraStream(user, widget.camera.id),
                  icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                  label: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
        );

      case LiveStreamState.online:
        // Simulated high-definition live security camera canvas
        return Stack(
          children: [
            // Dark CCTV gradient backdrop
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.1),
                  radius: 0.9,
                  colors: [Color(0xFF1E293B), Color(0xFF090D16)],
                ),
              ),
            ),
            // Security grid scan-lines & crosshairs
            CustomPaint(
              size: Size.infinite,
              painter: _CctvGridPainter(),
            ),
            // Watermark center branding
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  widget.camera.isHikvision ? Icons.cloud_circle : Icons.videocam,
                  size: 140,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTopHud(LiveStreamState state, StreamSessionModel? session) {
    return Row(
      children: [
        // Live Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: state == LiveStreamState.online
                ? AppColors.error.withOpacity(0.85)
                : Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == LiveStreamState.online) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                state == LiveStreamState.online ? 'LIVE' : state.displayName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Source Type Badge: RTSP vs Hikvision P2P
        SourceTypeBadge(sourceType: widget.camera.sourceType),
        const SizedBox(width: 6),

        // People Count Badge
        if (state == LiveStreamState.online && !widget.isCompact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 10, color: AppColors.success),
                const SizedBox(width: 3),
                Text(
                  '$_simulatedPeopleCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        const Spacer(),

        // FPS & Latency
        if (session != null && state == LiveStreamState.online && !widget.isCompact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${session.fps} FPS • ${session.latencyMs}ms',
              style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: AppColors.error.withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'CRITICAL: Cashier Empty > 3 mins (180s)! Alert dispatched.',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(LiveStreamState state, UserProfile? user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: widget.isCompact ? 4 : 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Camera Name and Branch
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.camera.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.isCompact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!widget.isCompact)
                  Text(
                    widget.camera.branchName ?? 'LensIQ Unified Gateway',
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Simulation Controls (Test 3-min Cashier Empty rule)
          if (!widget.isCompact) ...[
            Tooltip(
              message: _cashierOccupied ? 'Simulate Cashier Empty' : 'Simulate Cashier Return (Resets Timer)',
              child: InkWell(
                onTap: _toggleCashierPresence,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _cashierOccupied ? AppColors.warning.withOpacity(0.25) : AppColors.success.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _cashierOccupied ? AppColors.warning : AppColors.success,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _cashierOccupied ? 'Test Empty' : 'Test Return',
                    style: TextStyle(
                      color: _cashierOccupied ? AppColors.warning : AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            if (!_cashierOccupied && _emptyElapsedSeconds < 180)
              Tooltip(
                message: 'Fast-forward to 178s to trigger 180s rule',
                child: InkWell(
                  onTap: _fastForwardTo178s,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('>> 178s', style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
              ),
            const SizedBox(width: 6),
          ],

          // Toggle AI Overlay
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              _overlayVisible ? Icons.layers : Icons.layers_clear,
              size: 14,
              color: _overlayVisible ? AppColors.primaryLight : Colors.white54,
            ),
            tooltip: _overlayVisible ? 'Hide AI Overlays' : 'Show AI Overlays',
            onPressed: () => setState(() => _overlayVisible = !_overlayVisible),
          ),

          // Reconnect
          if (user != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.refresh, size: 14, color: Colors.white70),
              tooltip: 'Reconnect Source Adapter',
              onPressed: () => context.read<CameraProvider>().reconnectCameraStream(user, widget.camera.id),
            ),

          // Expand / Fullscreen
          if (widget.onExpand != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.fullscreen, size: 16, color: Colors.white),
              tooltip: 'Full Camera View',
              onPressed: widget.onExpand,
            ),
        ],
      ),
    );
  }
}

// Custom Painter for CCTV grid lines & optical crosshairs
class _CctvGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Center subtle reticle lines
    final midX = size.width / 2;
    final midY = size.height / 2;
    canvas.drawLine(Offset(midX - 20, midY), Offset(midX + 20, midY), paint);
    canvas.drawLine(Offset(midX, midY - 20), Offset(midX, midY + 20), paint);

    // Corner optical marks
    final crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.2;

    const cornerSize = 16.0;
    // Top-left
    canvas.drawLine(const Offset(12, 12), const Offset(12 + cornerSize, 12), crossPaint);
    canvas.drawLine(const Offset(12, 12), const Offset(12, 12 + cornerSize), crossPaint);
    // Top-right
    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12 - cornerSize, 12), crossPaint);
    canvas.drawLine(Offset(size.width - 12, 12), Offset(size.width - 12, 12 + cornerSize), crossPaint);
    // Bottom-left
    canvas.drawLine(Offset(12, size.height - 12), Offset(12 + cornerSize, size.height - 12), crossPaint);
    canvas.drawLine(Offset(12, size.height - 12), Offset(12, size.height - 12 - cornerSize), crossPaint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12 - cornerSize, size.height - 12), crossPaint);
    canvas.drawLine(Offset(size.width - 12, size.height - 12), Offset(size.width - 12, size.height - 12 - cornerSize), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for YOLOv8 Bounding Boxes & ROI Polygons
class _AiDetectionPainter extends CustomPainter {
  final bool isOccupied;
  final int emptyDurationSeconds;
  final bool isHikvision;
  final bool isCompact;

  _AiDetectionPainter({
    required this.isOccupied,
    required this.emptyDurationSeconds,
    required this.isHikvision,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ROI Box: Cashier Counter Zone
    final roiRect = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.32,
      size.width * 0.56,
      size.height * 0.48,
    );

    final roiFillPaint = Paint()
      ..color = isOccupied
          ? AppColors.success.withOpacity(0.08)
          : (emptyDurationSeconds >= 180 ? AppColors.error.withOpacity(0.18) : AppColors.warning.withOpacity(0.10))
      ..style = PaintingStyle.fill;

    final roiBorderPaint = Paint()
      ..color = isOccupied
          ? AppColors.success.withOpacity(0.8)
          : (emptyDurationSeconds >= 180 ? AppColors.error : AppColors.warning)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(roiRect, roiFillPaint);
    canvas.drawRect(roiRect, roiBorderPaint);

    // ROI Label & Status
    final roiLabel = isOccupied
        ? 'ROI: CASHIER COUNTER [OCCUPIED]'
        : 'ROI: CASHIER COUNTER [EMPTY: ${emptyDurationSeconds}s / 180s]';

    final textSpan = TextSpan(
      text: roiLabel,
      style: TextStyle(
        color: isOccupied
            ? AppColors.success
            : (emptyDurationSeconds >= 180 ? AppColors.error : AppColors.warning),
        fontSize: isCompact ? 8 : 10,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(roiRect.left + 4, roiRect.top + 4));

    // Person YOLOv8 Detection Box if Occupied
    if (isOccupied) {
      final personRect = Rect.fromLTWH(
        size.width * 0.40,
        size.height * 0.38,
        size.width * 0.20,
        size.height * 0.36,
      );

      final personPaint = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;

      canvas.drawRect(personRect, personPaint);

      final personLabelSpan = TextSpan(
        text: 'person: 0.94 [Cashier 01]',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 7 : 9,
          fontWeight: FontWeight.bold,
          backgroundColor: AppColors.secondary.withOpacity(0.85),
        ),
      );
      final personTp = TextPainter(text: personLabelSpan, textDirection: TextDirection.ltr)..layout();
      personTp.paint(canvas, Offset(personRect.left, personRect.top - (isCompact ? 10 : 13)));
    }
  }

  @override
  bool shouldRepaint(covariant _AiDetectionPainter oldDelegate) {
    return oldDelegate.isOccupied != isOccupied ||
        oldDelegate.emptyDurationSeconds != emptyDurationSeconds ||
        oldDelegate.isCompact != isCompact;
  }
}
