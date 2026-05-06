import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../view/screens/courses/course_detail_screen.dart';
import '../view/screens/courses/module_video_screen.dart';
import 'supabase/supabase_client_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static const String _notificationsEnabledPrefKey =
      'push_notifications_enabled';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _initializedForUserId;
  bool? _notificationsEnabled;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  bool _initialMessageHandled = false;

  Future<void> init({required String userId, bool forceRefresh = false}) async {
    await _configureMessageHandlers();

    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      _initializedForUserId = userId;
      return;
    }

    if (!forceRefresh && _initializedForUserId == userId) {
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

  Future<bool> areNotificationsEnabled() async {
    if (_notificationsEnabled != null) {
      return _notificationsEnabled!;
    }

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled =
        prefs.getBool(_notificationsEnabledPrefKey) ?? true;
    return _notificationsEnabled!;
  }

  Future<void> setNotificationsEnabled(
    bool enabled, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledPrefKey, enabled);
    _notificationsEnabled = enabled;

    if (!enabled) {
      await clearCurrentDeviceToken(deleteLocalToken: true);
      await _messaging.setAutoInitEnabled(false);
      return;
    }

    await _messaging.setAutoInitEnabled(true);

    final effectiveUserId =
        userId ??
        _initializedForUserId ??
        Supabase.instance.client.auth.currentUser?.id;
    if (effectiveUserId != null) {
      await init(userId: effectiveUserId, forceRefresh: true);
    }
  }

  Future<void> clearCurrentDeviceToken({bool deleteLocalToken = true}) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await SupabaseService.instance.deleteDeviceToken(token: token);
    }
    if (deleteLocalToken) {
      await _messaging.deleteToken();
    }
    _initializedForUserId = null;
  }

  Future<void> handleNotificationData(Map<String, dynamic> data) async {
    final action = data['action']?.toString();
    final courseId = data['course_id']?.toString();
    final moduleId = data['module_id']?.toString();
    final videoId = data['video_id']?.toString();

    if (action == 'open_module' && courseId != null && moduleId != null) {
      final course = await SupabaseService.instance.getCourseById(courseId);
      final module = await SupabaseService.instance.getModuleById(moduleId);
      if (course != null && module != null) {
        Get.to(
          () => ModuleVideosScreen(
            course: course,
            module: module,
            initialVideoId: videoId,
          ),
        );
      }
      return;
    }

    if (courseId != null) {
      final course = await SupabaseService.instance.getCourseById(courseId);
      if (course != null) {
        Get.to(
          () => CourseDetailScreen(
            course: course,
            initiallyEnrolled: false,
          ),
        );
      }
    }
  }

  Future<void> _configureMessageHandlers() async {
    await _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _scheduleNotificationNavigation(message.data);
      },
    );

    if (_initialMessageHandled) {
      return;
    }

    _initialMessageHandled = true;
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleNotificationNavigation(initialMessage.data);
    }
  }

  void _scheduleNotificationNavigation(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(handleNotificationData(data));
    });
  }
}
