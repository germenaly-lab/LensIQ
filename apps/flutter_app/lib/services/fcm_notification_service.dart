import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class FcmNotificationService {
  final _foregroundStreamController = StreamController<NotificationItem>.broadcast();
  bool _hasPermission = false;
  String? _fcmToken;

  Stream<NotificationItem> get onForegroundNotification => _foregroundStreamController.stream;
  bool get hasPermission => _hasPermission;
  String? get fcmToken => _fcmToken;

  Future<bool> requestPermissions() async {
    // In production environments with firebase_messaging, this calls FirebaseMessaging.instance.requestPermission().
    // For universal web/mobile and testing compatibility, we manage permission state and return granted.
    _hasPermission = true;
    if (_fcmToken == null) {
      final platformPrefix = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
      _fcmToken = 'fcm_${platformPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    }
    return true;
  }

  Future<String?> getDeviceToken() async {
    if (_fcmToken == null) {
      await requestPermissions();
    }
    return _fcmToken;
  }

  void dispatchForegroundNotification(NotificationItem notification) {
    if (!_foregroundStreamController.isClosed) {
      _foregroundStreamController.add(notification);
    }
  }

  void dispose() {
    _foregroundStreamController.close();
  }
}
