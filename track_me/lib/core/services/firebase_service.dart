import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
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
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background: ${message.notification?.title}');
}
