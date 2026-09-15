class NotificationPreferencesModel {
  final bool criticalAlerts;
  final bool warningAlerts;
  final bool infoAlerts;
  final bool cameraOffline;
  final bool aiEvents;
  final List<String> allowedBrandIds;
  final List<String> allowedBranchIds;

  const NotificationPreferencesModel({
    this.criticalAlerts = true,
    this.warningAlerts = true,
    this.infoAlerts = false,
    this.cameraOffline = true,
    this.aiEvents = true,
    this.allowedBrandIds = const [],
    this.allowedBranchIds = const [],
  });

  bool get inAppPushEnabled => criticalAlerts || warningAlerts || infoAlerts || cameraOffline || aiEvents;

  NotificationPreferencesModel copyWith({
    bool? criticalAlerts,
    bool? warningAlerts,
    bool? infoAlerts,
    bool? cameraOffline,
    bool? aiEvents,
    List<String>? allowedBrandIds,
    List<String>? allowedBranchIds,
  }) {
    return NotificationPreferencesModel(
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      warningAlerts: warningAlerts ?? this.warningAlerts,
      infoAlerts: infoAlerts ?? this.infoAlerts,
      cameraOffline: cameraOffline ?? this.cameraOffline,
      aiEvents: aiEvents ?? this.aiEvents,
      allowedBrandIds: allowedBrandIds ?? this.allowedBrandIds,
      allowedBranchIds: allowedBranchIds ?? this.allowedBranchIds,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      criticalAlerts: json['criticalAlerts'] as bool? ?? true,
      warningAlerts: json['warningAlerts'] as bool? ?? true,
      infoAlerts: json['infoAlerts'] as bool? ?? false,
      cameraOffline: json['cameraOffline'] as bool? ?? true,
      aiEvents: json['aiEvents'] as bool? ?? true,
      allowedBrandIds:
          (json['allowedBrandIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      allowedBranchIds:
          (json['allowedBranchIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'criticalAlerts': criticalAlerts,
      'warningAlerts': warningAlerts,
      'infoAlerts': infoAlerts,
      'cameraOffline': cameraOffline,
      'aiEvents': aiEvents,
      'allowedBrandIds': allowedBrandIds,
      'allowedBranchIds': allowedBranchIds,
    };
  }
}
