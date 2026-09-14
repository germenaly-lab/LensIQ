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
  degraded,
  provisioning;

  static CameraStatus fromString(String? status) {
    if (status == null) return CameraStatus.offline;
    switch (status.toLowerCase()) {
      case 'online':
      case 'streaming':
        return CameraStatus.online;
      case 'offline':
        return CameraStatus.offline;
      case 'degraded':
      case 'reconnecting':
        return CameraStatus.degraded;
      case 'provisioning':
      case 'configured':
      case 'connecting':
        return CameraStatus.provisioning;
      default:
        return CameraStatus.offline;
    }
  }
}

class CameraModel {
  final String id;
  final String name;
  final String companyId;
  final String brandId;
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

  const CameraModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.brandId,
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
  });

  bool get isOnline => status == CameraStatus.online;
  bool get isHikvision => sourceType == CameraSourceType.hikvisionP2p;
  bool get isRtsp => sourceType == CameraSourceType.rtsp;

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Camera',
      companyId: json['company_id'] ?? '',
      brandId: json['brand_id'] ?? '',
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company_id': companyId,
        'brand_id': brandId,
        'branch_id': branchId,
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
      };
}
