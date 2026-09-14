enum IncidentSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case IncidentSeverity.info:
        return 'Information';
      case IncidentSeverity.warning:
        return 'Warning';
      case IncidentSeverity.critical:
        return 'Critical Alert';
    }
  }

  static IncidentSeverity fromString(String? severity) {
    if (severity == null) return IncidentSeverity.info;
    switch (severity.toLowerCase()) {
      case 'critical':
        return IncidentSeverity.critical;
      case 'warning':
        return IncidentSeverity.warning;
      case 'info':
      default:
        return IncidentSeverity.info;
    }
  }
}

enum IncidentStatus {
  open,
  acknowledged,
  resolved;

  static IncidentStatus fromString(String? status) {
    if (status == null) return IncidentStatus.open;
    switch (status.toLowerCase()) {
      case 'acknowledged':
        return IncidentStatus.acknowledged;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'open':
      default:
        return IncidentStatus.open;
    }
  }
}

class IncidentModel {
  final String id;
  final String cameraId;
  final String cameraName;
  final String branchId;
  final String branchName;
  final String ruleType; // 'cashier_empty', 'unattended_area', 'loitering'
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String title;
  final String description;
  final DateTime timestamp;
  final int? durationSeconds;
  final double? confidence;

  const IncidentModel({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    required this.branchId,
    required this.branchName,
    required this.ruleType,
    required this.severity,
    this.status = IncidentStatus.open,
    required this.title,
    required this.description,
    required this.timestamp,
    this.durationSeconds,
    this.confidence,
  });

  bool get isCritical => severity == IncidentSeverity.critical;
  bool get isCashierAlert => ruleType.contains('cashier');

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] ?? '',
      cameraId: json['camera_id'] ?? '',
      cameraName: json['camera_name'] ?? 'Counter Camera',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? 'Main Branch',
      ruleType: json['rule_type'] ?? 'cashier_empty',
      severity: IncidentSeverity.fromString(json['severity'] as String?),
      status: IncidentStatus.fromString(json['status'] as String?),
      title: json['title'] ?? 'AI Detection Alert',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      durationSeconds: json['duration_seconds'] != null
          ? (json['duration_seconds'] as num).toInt()
          : null,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'camera_id': cameraId,
        'camera_name': cameraName,
        'branch_id': branchId,
        'branch_name': branchName,
        'rule_type': ruleType,
        'severity': severity.name,
        'status': status.name,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'duration_seconds': durationSeconds,
        'confidence': confidence,
      };
}
