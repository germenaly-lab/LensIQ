import 'camera.dart';

class StreamSessionModel {
  final String sessionId;
  final String cameraId;
  final CameraSourceType sourceType;
  final String streamUrl;
  final String token;
  final String protocol;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewerCount;
  final bool demoMode;
  final String resolution;
  final int fps;
  final String codec;
  final int latencyMs;
  final String connectionStatus;

  const StreamSessionModel({
    required this.sessionId,
    required this.cameraId,
    required this.sourceType,
    required this.streamUrl,
    required this.token,
    required this.protocol,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.viewerCount = 1,
    this.demoMode = false,
    this.resolution = '1920x1080',
    this.fps = 30,
    this.codec = 'h264',
    this.latencyMs = 45,
    this.connectionStatus = 'streaming',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory StreamSessionModel.fromJson(Map<String, dynamic> json) {
    final monitoring = json['monitoring'] as Map<String, dynamic>? ?? {};
    final streamInfo = json['stream_info'] as Map<String, dynamic>? ?? {};

    return StreamSessionModel(
      sessionId: json['session_id'] ?? json['sessionId'] ?? '',
      cameraId: json['camera_id'] ?? json['cameraId'] ?? '',
      sourceType: CameraSourceType.fromString(json['source_type'] ?? json['sourceType']),
      streamUrl: json['stream_url'] ?? json['streamEndpoint'] ?? '',
      token: json['token'] ?? '',
      protocol: json['protocol'] ?? json['playbackProtocol'] ?? 'webrtc',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at']) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      viewerCount: json['viewer_count'] ?? (monitoring['viewer_count'] as num?)?.toInt() ?? 1,
      demoMode: json['demo_mode'] ?? false,
      resolution: streamInfo['resolution'] ?? '1920x1080',
      fps: (streamInfo['fps'] as num?)?.toInt() ?? 30,
      codec: streamInfo['codec'] ?? 'h264',
      latencyMs: (monitoring['latency_ms'] as num?)?.toInt() ?? 45,
      connectionStatus: monitoring['connection_status'] ?? json['connectionStatus'] ?? 'streaming',
    );
  }
}
