import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'supabase/supabase_client_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _initializedForUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  Future<void> init({required String userId}) async {
    if (_initializedForUserId == userId) {
      return;
    }

    await _messaging.setAutoInitEnabled(true);

    // Request permissions where the platform requires runtime approval.
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await SupabaseService.instance.upsertDeviceToken(
        userId: userId,
        token: token,
        platform: defaultTargetPlatform.toString(),
      );
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      newToken,
    ) async {
      await SupabaseService.instance.upsertDeviceToken(
        userId: userId,
        token: newToken,
        platform: defaultTargetPlatform.toString(),
      );
    });

    _initializedForUserId = userId;

    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint('Foreground notification: ${message.messageId}');
    });
  }

  Future<void> clearCurrentDeviceToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await SupabaseService.instance.deleteDeviceToken(token: token);
    }
    _initializedForUserId = null;
  }
}
