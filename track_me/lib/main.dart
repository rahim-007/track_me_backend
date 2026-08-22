import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest.dart' as tz_init;

import 'app/app.dart';
import 'core/local/isar_service.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never freeze silently: surface any uncaught error in the console so the
  // real cause of a startup hang is visible in `flutter run`.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[startup] FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[startup] Platform error: $error\n$stack');
    // In debug let the framework surface the crash; in release swallow it so
    // a recoverable platform hiccup can't take the whole app down.
    return !kDebugMode;
  };

  // (1) Bounded, best-effort platform setup — a slow channel here must never
  //     leave the app stuck on the native splash logo.
  try {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('[startup] Orientation lock skipped: $e');
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // (2) Synchronous, pure-Dart init — cannot hang, so it is safe before runApp.
  //     All providers fetch the DioClient() singleton, so the client must be
  //     ready before the first widget builds.
  tz_init.initializeTimeZones();
  DioClient().init();

  // (3) Bounded read of the saved theme — the UI appears immediately even if
  //     secure storage is slow.
  var initialIsDark = false;
  try {
    const storage = FlutterSecureStorage();
    final stored = await storage
        .read(key: 'is_dark_mode')
        .timeout(const Duration(seconds: 2));
    initialIsDark = stored == 'true';
  } catch (_) {
    // Fall back to light theme; toggling still works after launch.
  }
  AppColors.isDarkMode = initialIsDark;

  // (4) Render the app NOW — the in-app splash screen covers the time the
  //     background services below need to come up.
  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeNotifier(initialIsDark)),
      ],
      child: const TrackMeApp(),
    ),
  );

  // (5) Everything else initializes in the background with hard timeouts, so a
  //     single stalled plugin can never block the first frame again.
  unawaited(_initServicesAsync());
}

Future<void> _initServicesAsync() async {
  try {
    debugPrint('[startup] Isar init…');
    await IsarService.initialize().timeout(const Duration(seconds: 12));
    debugPrint('[startup] Isar ready');
  } catch (e) {
    debugPrint('[startup] Isar init failed: $e');
  }

  try {
    debugPrint('[startup] Firebase init…');
    await FirebaseService.initialize().timeout(const Duration(seconds: 10));
    debugPrint('[startup] Firebase ready');
  } catch (e) {
    debugPrint('[startup] Firebase init failed: $e');
  }

  try {
    debugPrint('[startup] Notifications init…');
    await NotificationService.initialize().timeout(const Duration(seconds: 8));
    debugPrint('[startup] Notifications ready');

    // Ask for POST_NOTIFICATIONS (Android 13+) + SCHEDULE_EXACT_ALARM once at
    // startup so FCM pushes and exact-timed reminders can be shown even for
    // users who never create a habit with a reminder time. Safe to call
    // repeatedly — already-granted/denied states resolve silently.
    await NotificationService.requestPermissions();
  } catch (e) {
    debugPrint('[startup] Notifications init failed: $e');
  }
}
