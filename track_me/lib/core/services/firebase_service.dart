import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../network/dio_client.dart';
import '../notifications/notification_service.dart';

class FirebaseService {
  FirebaseService._();

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      await _setupFCM();
      // Ensure the device token and timezone are registered with the backend on every startup
      unawaited(registerDeviceWithBackend());
    } catch (e) {
      // Firebase not configured yet — safe to ignore for development
      debugPrint('[FCM] Firebase not configured or init failed: $e');
    }
  }

  static Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permissions (alert, badge, sound)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Notification authorization status: ${settings.authorizationStatus}');

    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('[FCM] Token acquired: $token');
    if (token != null && token.isNotEmpty) {
      unawaited(registerTokenWithBackend(token));
    }

    // FCM rotates tokens (monthly, reinstall, clear-data). Re-register the new
    // token with the backend so pushes never silently die on a stale token.
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token rotated: $newToken');
      unawaited(registerTokenWithBackend(newToken));
    });

    // Handle foreground messages: Android suppresses a `notification`-payload
    // push from the system tray while the app is open and delivers it only
    // here. Re-surface it through the local plugin or live pushes are
    // invisible whenever the app is in the foreground.
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];
      if (title == null && body == null) return;

      // Habit reminders are managed by the device-side local alarm scheduler.
      // Skip duplicate foreground display if an FCM push is marked as a habit reminder.
      final type = message.data['type']?.toString().toLowerCase();
      final category = message.data['category']?.toString().toLowerCase();
      if (type == 'habit_reminder' || type == 'habit' || category == 'habit') {
        debugPrint('[FCM] Skipping habit push in foreground (managed by local scheduler)');
        return;
      }

      final channelId = message.data['channelId'] as String? ?? NotificationService.generalChannelId;
      final notificationId = message.messageId?.hashCode ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      debugPrint('[FCM] Foreground message received: $title');
      NotificationService.showInstantNotification(
        id: notificationId,
        title: title ?? 'UrDay',
        body: body ?? '',
        channelId: channelId,
      );
    });

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FCM] Error getting FCM token: $e');
      return null;
    }
  }

  /// Push the current device's FCM token to the backend so the server can
  /// send push notifications to this device. Safe to call any time: it's a
  /// no-op when Firebase is unavailable, no token is registered, or the user
  /// isn't authenticated (the request will 401 and be silently ignored).
  static Future<void> registerTokenWithBackend([String? token]) async {
    if (kIsWeb) return;

    // Retry token acquisition up to 3 times if initially null
    for (var attempt = 0; attempt < 3; attempt++) {
      token ??= await getFcmToken();
      if (token != null && token.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (token == null || token.isEmpty) {
      debugPrint('[FCM] No FCM token available to register');
      return;
    }

    try {
      await DioClient().dio.post(
        '/notifications/device-token',
        data: {'token': token},
      );
      debugPrint('[FCM] FCM token successfully registered with backend');
    } catch (e) {
      debugPrint('[FCM] FCM token registration skipped/failed: $e');
    }
  }

  /// Send the device's IANA timezone (e.g. "Asia/Kolkata") to the backend so
  /// habit/goal reminders fire at the user's local clock. Best-effort: no-op
  /// when the plugin is unavailable (tests/web) or the request fails.
  static Future<void> syncTimezoneWithBackend() async {
    if (kIsWeb) return;
    String? timezoneName;
    try {
      timezoneName = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('Timezone lookup skipped: $e');
      return;
    }
    if (timezoneName.isEmpty) return;
    try {
      await DioClient().dio.patch(
        '/users/me',
        data: {'timezone': timezoneName},
      );
      debugPrint('Timezone registered with backend: $timezoneName');
    } catch (e) {
      debugPrint('Timezone registration skipped: $e');
    }
  }

  /// Register this device with the backend: FCM token (for pushes) + IANA
  /// timezone (for local-clock reminders). Best-effort and safe to call on
  /// every login/launch — failures are logged and swallowed.
  static Future<void> registerDeviceWithBackend() async {
    await registerTokenWithBackend();
    await syncTimezoneWithBackend();
  }

  /// Trigger an immediate test push notification from the backend to verify
  /// delivery to this device.
  static Future<bool> sendTestPush() async {
    try {
      final response = await DioClient().dio.post('/notifications/test-push');
      final data = response.data['data'] ?? response.data;
      debugPrint('[FCM] Test push response: $data');
      return data['success'] == true || data['deliveredToFCM'] == true;
    } catch (e) {
      debugPrint('[FCM] Test push failed: $e');
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background: ${message.notification?.title}');
}
