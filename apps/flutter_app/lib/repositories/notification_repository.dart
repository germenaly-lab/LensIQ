import '../core/network/api_client.dart';
import '../models/user_profile.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  // Local in-memory store for offline/demo operation
  final List<NotificationItem> _localNotifications = [];
  NotificationPreferencesModel _localPreferences = const NotificationPreferencesModel();

  NotificationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /**
   * Registers/syncs the device FCM token with the backend
   */
  Future<bool> registerDeviceToken(
    UserProfile user,
    String token,
    String platform, {
    String? deviceModel,
  }) async {
    final response = await _apiClient.post(
      '/notifications/tokens',
      user: user,
      body: {
        'token': token,
        'platform': platform,
        'deviceModel': deviceModel ?? 'Flutter Client',
      },
    );
    return response.success;
  }

  /**
   * Retrieves notification history and unread count
   */
  Future<List<NotificationItem>> getNotifications(UserProfile user) async {
    final response = await _apiClient.get(
      '/notifications',
      user: user,
      fromJson: (json) {
        if (json is Map && json['notifications'] is List) {
          return (json['notifications'] as List)
              .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <NotificationItem>[];
      },
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    // Offline / Demo fallback
    if (_localNotifications.isEmpty) {
      _seedLocalDemoNotifications(user);
    }
    return List.unmodifiable(_localNotifications);
  }

  /**
   * Marks a single notification as read
   */
  Future<bool> markAsRead(UserProfile user, String notificationId) async {
    final response = await _apiClient.patch(
      '/notifications/$notificationId/read',
      user: user,
    );

    final idx = _localNotifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _localNotifications[idx] = _localNotifications[idx].copyWith(readAt: DateTime.now());
    }

    return response.success;
  }

  /**
   * Marks all notifications as read
   */
  Future<bool> markAllAsRead(UserProfile user) async {
    final response = await _apiClient.post(
      '/notifications/read-all',
      user: user,
    );

    final now = DateTime.now();
    for (int i = 0; i < _localNotifications.length; i++) {
      if (_localNotifications[i].readAt == null) {
        _localNotifications[i] = _localNotifications[i].copyWith(readAt: now);
      }
    }

    return response.success;
  }

  /**
   * Retrieves user notification preferences
   */
  Future<NotificationPreferencesModel> getPreferences(UserProfile user) async {
    final response = await _apiClient.get(
      '/notifications/preferences',
      user: user,
      fromJson: (json) => NotificationPreferencesModel.fromJson(json as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    return _localPreferences;
  }

  /**
   * Updates user notification preferences
   */
  Future<NotificationPreferencesModel> updatePreferences(
    UserProfile user,
    NotificationPreferencesModel preferences,
  ) async {
    final response = await _apiClient.put(
      '/notifications/preferences',
      user: user,
      body: preferences.toJson(),
      fromJson: (json) => NotificationPreferencesModel.fromJson(json as Map<String, dynamic>),
    );

    _localPreferences = preferences;

    if (response.success && response.data != null) {
      return response.data!;
    }

    return preferences;
  }

  /**
   * Local seed data for offline / web demonstration
   */
  void _seedLocalDemoNotifications(UserProfile user) {
    final now = DateTime.now();
    _localNotifications.addAll([
      NotificationItem(
        id: 'notif_demo_01',
        recipientId: user.id,
        incidentId: 'inc_cashier_01',
        title: 'CRITICAL: Cashier Area Empty',
        body: 'Armani Exchange • Mall of Arabia • Cashier 01: Cashier area empty for 3 minutes.',
        sentAt: now.subtract(const Duration(minutes: 5)),
        deliveryStatus: 'delivered',
        data: {
          'severity': 'critical',
          'incidentId': 'inc_cashier_01',
          'branchName': 'Mall of Arabia',
          'route': '/incidents?id=inc_cashier_01',
        },
      ),
      NotificationItem(
        id: 'notif_demo_02',
        recipientId: user.id,
        incidentId: 'inc_loiter_02',
        title: 'WARNING: Loitering Detected',
        body: 'Ego Fashion • Mall of Arabia • Fitting Room: Extended loitering detected.',
        sentAt: now.subtract(const Duration(minutes: 42)),
        deliveryStatus: 'delivered',
        data: {
          'severity': 'warning',
          'incidentId': 'inc_loiter_02',
          'branchName': 'Mall of Arabia',
          'route': '/incidents?id=inc_loiter_02',
        },
      ),
    ]);
  }
}
