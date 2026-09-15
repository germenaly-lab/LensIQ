class AuditLogModel {
  final String id;
  final DateTime timestamp;
  final String action; // e.g. 'Camera Cashier 01 updated'
  final String actorName; // e.g. 'Alex Vance (Super Admin)'
  final String actorRole;
  final String details;
  final String category; // 'camera', 'roi', 'incident', 'rule', 'security'
  final String? ipAddress;

  const AuditLogModel({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.actorName,
    required this.actorRole,
    required this.details,
    required this.category,
    this.ipAddress,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      action: json['action'] ?? '',
      actorName: json['actor_name'] ?? 'System',
      actorRole: json['actor_role'] ?? 'super_admin',
      details: json['details'] ?? '',
      category: json['category'] ?? 'general',
      ipAddress: json['ip_address'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'actor_name': actorName,
        'actor_role': actorRole,
        'details': details,
        'category': category,
        'ip_address': ipAddress,
      };
}
