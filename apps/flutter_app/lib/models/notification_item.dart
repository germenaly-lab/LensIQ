class NotificationItem {
  final String id;
  final String recipientId;
  final String incidentId;
  final String title;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;
  final String deliveryStatus;
  final Map<String, dynamic> data;

  const NotificationItem({
    required this.id,
    required this.recipientId,
    required this.incidentId,
    required this.title,
    required this.body,
    required this.sentAt,
    this.readAt,
    this.deliveryStatus = 'delivered',
    this.data = const {},
  });

  bool get isRead => readAt != null;
  bool get isCritical =>
      title.toLowerCase().contains('critical') || (data['severity']?.toString().toLowerCase() == 'critical');
  bool get isWarning =>
      title.toLowerCase().contains('warning') || (data['severity']?.toString().toLowerCase() == 'warning');

  NotificationItem copyWith({
    String? id,
    String? recipientId,
    String? incidentId,
    String? title,
    String? body,
    DateTime? sentAt,
    DateTime? readAt,
    String? deliveryStatus,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      incidentId: incidentId ?? this.incidentId,
      title: title ?? this.title,
      body: body ?? this.body,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      data: data ?? this.data,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      incidentId: json['incidentId'] as String? ?? (json['data']?['incidentId'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'] as String) : null,
      deliveryStatus: json['deliveryStatus'] as String? ?? 'delivered',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'incidentId': incidentId,
      'title': title,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deliveryStatus': deliveryStatus,
      'data': data,
    };
  }
}
