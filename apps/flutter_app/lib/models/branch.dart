class BranchModel {
  final String id;
  final String companyId;
  final String brandId;
  final String name;
  final String code;
  final String address;
  final int cameraCount;
  final int onlineCameraCount;
  final int activeIncidentCount;
  final String status; // 'operational', 'alert', 'degraded'

  const BranchModel({
    required this.id,
    required this.companyId,
    required this.brandId,
    required this.name,
    required this.code,
    required this.address,
    this.cameraCount = 0,
    this.onlineCameraCount = 0,
    this.activeIncidentCount = 0,
    this.status = 'operational',
  });

  bool get isOperational => status == 'operational';
  bool get hasActiveAlerts => activeIncidentCount > 0;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? '',
      companyId: json['company_id'] ?? '',
      brandId: json['brand_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'] ?? '',
      cameraCount: json['camera_count'] ?? 0,
      onlineCameraCount: json['online_camera_count'] ?? 0,
      activeIncidentCount: json['active_incident_count'] ?? 0,
      status: json['status'] ?? 'operational',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'brand_id': brandId,
        'name': name,
        'code': code,
        'address': address,
        'camera_count': cameraCount,
        'online_camera_count': onlineCameraCount,
        'active_incident_count': activeIncidentCount,
        'status': status,
      };

  BranchModel copyWith({
    String? id,
    String? companyId,
    String? brandId,
    String? name,
    String? code,
    String? address,
    int? cameraCount,
    int? onlineCameraCount,
    int? activeIncidentCount,
    String? status,
  }) {
    return BranchModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      cameraCount: cameraCount ?? this.cameraCount,
      onlineCameraCount: onlineCameraCount ?? this.onlineCameraCount,
      activeIncidentCount: activeIncidentCount ?? this.activeIncidentCount,
      status: status ?? this.status,
    );
  }
}
