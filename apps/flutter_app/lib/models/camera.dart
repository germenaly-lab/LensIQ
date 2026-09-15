enum CameraSourceType {
  rtsp,
  hikvisionP2p;

  String get displayName {
    switch (this) {
      case CameraSourceType.rtsp:
        return 'RTSP Stream';
      case CameraSourceType.hikvisionP2p:
        return 'Hikvision P2P';
    }
  }

  static CameraSourceType fromString(String? type) {
    if (type == null) return CameraSourceType.rtsp;
    final t = type.toLowerCase();
    if (t == 'hikvision_p2p' || t == 'hikvisionp2p' || t.contains('hik')) {
      return CameraSourceType.hikvisionP2p;
    }
    return CameraSourceType.rtsp;
  }
}

enum CameraStatus {
  online,
  offline,
  warning,
  unknown;

  String get displayName {
    switch (this) {
      case CameraStatus.online:
        return 'Online';
      case CameraStatus.offline:
        return 'Offline';
      case CameraStatus.warning:
        return 'Warning';
      case CameraStatus.unknown:
        return 'Unknown';
    }
  }

  static CameraStatus fromString(String? status) {
    if (status == null) return CameraStatus.unknown;
    switch (status.toLowerCase()) {
      case 'online':
      case 'streaming':
        return CameraStatus.online;
      case 'offline':
        return CameraStatus.offline;
      case 'warning':
      case 'degraded':
      case 'reconnecting':
        return CameraStatus.warning;
      case 'unknown':
      case 'provisioning':
      case 'configured':
      case 'connecting':
      default:
        return CameraStatus.unknown;
    }
  }
}

class CameraModel {
  final String id;
  final String name;
  final String companyId;
  final String brandId;
  final String? brandName;
  final String branchId;
  final String? branchName;
  final CameraSourceType sourceType;
  final CameraStatus status;
  final bool enabled;
  final String? locationDescription;
  final String? rtspUrl;
  final String? hikDeviceId;
  final String? hikSerialNumber;
  final int? hikChannel;
  final String streamProfile;
  final DateTime? lastSeenAt;
  final int fps;
  final int latencyMs;

  const CameraModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.brandId,
    this.brandName,
    required this.branchId,
    this.branchName,
    required this.sourceType,
    required this.status,
    this.enabled = true,
    this.locationDescription,
    this.rtspUrl,
    this.hikDeviceId,
    this.hikSerialNumber,
    this.hikChannel,
    this.streamProfile = 'main',
    this.lastSeenAt,
    this.fps = 30,
    this.latencyMs = 45,
  });

  bool get isOnline => status == CameraStatus.online;
  bool get isHikvision => sourceType == CameraSourceType.hikvisionP2p;
  bool get isRtsp => sourceType == CameraSourceType.rtsp;
  String get sourceTypeDisplayName => sourceType.displayName;

  CameraModel copyWith({
    String? id,
    String? name,
    String? companyId,
    String? brandId,
    String? brandName,
    String? branchId,
    String? branchName,
    CameraSourceType? sourceType,
    CameraStatus? status,
    bool? enabled,
    String? locationDescription,
    String? rtspUrl,
    String? hikDeviceId,
    String? hikSerialNumber,
    int? hikChannel,
    String? streamProfile,
    DateTime? lastSeenAt,
    int? fps,
    int? latencyMs,
  }) {
    return CameraModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      sourceType: sourceType ?? this.sourceType,
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      locationDescription: locationDescription ?? this.locationDescription,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      hikDeviceId: hikDeviceId ?? this.hikDeviceId,
      hikSerialNumber: hikSerialNumber ?? this.hikSerialNumber,
      hikChannel: hikChannel ?? this.hikChannel,
      streamProfile: streamProfile ?? this.streamProfile,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      fps: fps ?? this.fps,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Camera',
      companyId: json['company_id'] ?? '',
      brandId: json['brand_id'] ?? '',
      brandName: json['brand_name'] ?? 'Ego Fashion',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'],
      sourceType: CameraSourceType.fromString(json['source_type'] as String?),
      status: CameraStatus.fromString(json['status'] as String?),
      enabled: json['enabled'] ?? true,
      locationDescription: json['location_description'],
      rtspUrl: json['rtsp_url'],
      hikDeviceId: json['hik_device_id'],
      hikSerialNumber: json['hik_serial_number'],
      hikChannel: json['hik_channel'] != null ? (json['hik_channel'] as num).toInt() : null,
      streamProfile: json['stream_profile'] ?? 'main',
      lastSeenAt: json['last_seen_at'] != null ? DateTime.tryParse(json['last_seen_at']) : null,
      fps: json['fps'] != null ? (json['fps'] as num).toInt() : 30,
      latencyMs: json['latency_ms'] != null ? (json['latency_ms'] as num).toInt() : 45,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company_id': companyId,
        'brand_id': brandId,
        'brand_name': brandName,
        'branch_id': branchId,
        'branch_name': branchName,
        'source_type': sourceType.name,
        'status': status.name,
        'enabled': enabled,
        'location_description': locationDescription,
        'rtsp_url': rtspUrl,
        'hik_device_id': hikDeviceId,
        'hik_serial_number': hikSerialNumber,
        'hik_channel': hikChannel,
        'stream_profile': streamProfile,
        'last_seen_at': lastSeenAt?.toIso8601String(),
        'fps': fps,
        'latency_ms': latencyMs,
      };
}
