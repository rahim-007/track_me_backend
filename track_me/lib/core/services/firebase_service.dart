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
    } catch (e) {
      // Firebase not configured yet — safe to ignore for development
      debugPrint('Firebase not configured: $e');
    }
  }

  static Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // FCM rotates tokens (monthly, reinstall, clear-data). Re-register the new
    // token with the backend so pushes never silently die on a stale token.
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token rotated: $newToken');
      unawaited(registerTokenWithBackend(newToken));
    });

    // Handle foreground messages: Android suppresses a `notification`-payload
    // push from the system tray while the app is open and delivers it only
    // here. Re-surface it through the local plugin or live pushes are
    // invisible whenever the app is in the foreground.
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title == null && body == null) return;
      debugPrint('FCM Foreground: $title');
      NotificationService.showInstantNotification(
        title: title ?? 'Track Me',
        body: body ?? '',
        channelId: NotificationService.habitChannelId,
      );
    });

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Push the current device's FCM token to the backend so the server can
  /// send push notifications to this device. Safe to call any time: it's a
  /// no-op when Firebase is unavailable, no token is registered, or the user
  /// isn't authenticated (the request will 401 and be silently ignored).
  static Future<void> registerTokenWithBackend([String? token]) async {
    token ??= await getFcmToken();
    if (token == null || token.isEmpty) return;
    try {
      await DioClient().dio.post(
        '/notifications/device-token',
        data: {'token': token},
      );
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('FCM token registration skipped: $e');
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
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background: ${message.notification?.title}');
}
