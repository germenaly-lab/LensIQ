import 'incident.dart';

class AiRuleModel {
  final String id;
  final String name;
  final String ruleType; // 'cashier_empty', 'perimeter_breach', 'loitering', 'occupancy_limit'
  final bool enabled;
  final int durationSeconds; // timeout threshold
  final int minPeople; // e.g. 0 for cashier empty, 1 for intruder
  final IncidentSeverity severity;
  final String cameraId;
  final String cameraName;
  final String branchId;
  final String branchName;
  final String? roiId;
  final String? roiName;

  const AiRuleModel({
    required this.id,
    required this.name,
    required this.ruleType,
    this.enabled = true,
    required this.durationSeconds,
    required this.minPeople,
    required this.severity,
    required this.cameraId,
    required this.cameraName,
    required this.branchId,
    required this.branchName,
    this.roiId,
    this.roiName,
  });

  String get ruleTypeDisplayName {
    switch (ruleType) {
      case 'cashier_empty':
        return 'Unattended Cashier Counter';
      case 'perimeter_breach':
        return 'Restricted Zone Perimeter Breach';
      case 'loitering':
        return 'Suspicious Loitering Detection';
      case 'occupancy_limit':
        return 'Maximum Customer Occupancy Limit';
      default:
        return ruleType.replaceAll('_', ' ').toUpperCase();
    }
  }

  AiRuleModel copyWith({
    String? id,
    String? name,
    String? ruleType,
    bool? enabled,
    int? durationSeconds,
    int? minPeople,
    IncidentSeverity? severity,
    String? cameraId,
    String? cameraName,
    String? branchId,
    String? branchName,
    String? roiId,
    String? roiName,
  }) {
    return AiRuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ruleType: ruleType ?? this.ruleType,
      enabled: enabled ?? this.enabled,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      minPeople: minPeople ?? this.minPeople,
      severity: severity ?? this.severity,
      cameraId: cameraId ?? this.cameraId,
      cameraName: cameraName ?? this.cameraName,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      roiId: roiId ?? this.roiId,
      roiName: roiName ?? this.roiName,
    );
  }

  factory AiRuleModel.fromJson(Map<String, dynamic> json) {
    return AiRuleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ruleType: json['rule_type'] ?? 'cashier_empty',
      enabled: json['enabled'] ?? true,
      durationSeconds: json['duration_seconds'] ?? 180,
      minPeople: json['min_people'] ?? 0,
      severity: IncidentSeverity.fromString(json['severity']),
      cameraId: json['camera_id'] ?? '',
      cameraName: json['camera_name'] ?? 'Camera',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? 'Branch',
      roiId: json['roi_id'],
      roiName: json['roi_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rule_type': ruleType,
        'enabled': enabled,
        'duration_seconds': durationSeconds,
        'min_people': minPeople,
        'severity': severity.name,
        'camera_id': cameraId,
        'camera_name': cameraName,
        'branch_id': branchId,
        'branch_name': branchName,
        'roi_id': roiId,
        'roi_name': roiName,
      };
}
