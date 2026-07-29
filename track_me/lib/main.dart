 mimport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'core/local/isar_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize timezone
  tz.initializeTimeZones();

  // Initialize Isar
  await IsarService.initialize();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Local Notifications
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: TrackMeApp(),
    ),
  );
}
