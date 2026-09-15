import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';
import '../repositories/notification_repository.dart';
import '../services/fcm_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final FcmNotificationService _fcmService;

  List<NotificationItem> _notifications = [];
  NotificationPreferencesModel _preferences = const NotificationPreferencesModel();
  bool _isLoading = false;
  String? _errorMessage;
  String? _deviceToken;
  bool _hasPermission = false;
  NotificationItem? _latestForegroundNotification;
  StreamSubscription<NotificationItem>? _subscription;

  NotificationProvider(this._repository, this._fcmService);

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  NotificationPreferencesModel get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get deviceToken => _deviceToken;
  bool get hasPermission => _hasPermission;
  NotificationItem? get latestForegroundNotification => _latestForegroundNotification;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize(UserProfile user) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Request FCM notification permissions
      _hasPermission = await _fcmService.requestPermissions();

      // 2. Fetch device token
      _deviceToken = await _fcmService.getDeviceToken();

      // 3. Register device token on backend
      if (_deviceToken != null) {
        final platformStr = kIsWeb
            ? 'web'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
        await _repository.registerDeviceToken(user, _deviceToken!, platformStr);
      }

      // 4. Load notification history and preferences
      final results = await Future.wait([
        _repository.getNotifications(user),
        _repository.getPreferences(user),
      ]);

      _notifications = List.from(results[0] as List<NotificationItem>);
      _preferences = results[1] as NotificationPreferencesModel;

      // 5. Listen to foreground notifications
      _subscription?.cancel();
      _subscription = _fcmService.onForegroundNotification.listen((item) {
        addIncomingNotification(item);
      });
    } catch (e) {
      _errorMessage = 'Failed to initialize notification system: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addIncomingNotification(NotificationItem item) {
    _notifications.insert(0, item);
    _latestForegroundNotification = item;
    notifyListeners();
  }

  void dismissForegroundBanner() {
    _latestForegroundNotification = null;
    notifyListeners();
  }

  Future<void> markAsRead(UserProfile user, String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(readAt: DateTime.now());
      notifyListeners();
      await _repository.markAsRead(user, notificationId);
    }
  }

  Future<void> markAllAsRead(UserProfile user) async {
    final now = DateTime.now();
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(readAt: now);
      }
    }
    notifyListeners();
    await _repository.markAllAsRead(user);
  }

  Future<void> updatePreferences(
    UserProfile user,
    NotificationPreferencesModel newPrefs,
  ) async {
    _preferences = newPrefs;
    notifyListeners();

    try {
      _preferences = await _repository.updatePreferences(user, newPrefs);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save preferences: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
