import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// High-importance channel used by BOTH local habit reminders and backend FCM
  /// pushes (the backend sets android.notification.channelId to this id). The
  /// channel must exist before any notification is shown on Android 8+.
  static const String habitChannelId = 'habit_reminders';
  static const String generalChannelId = 'general';

  static Future<void> initialize() async {
    if (kIsWeb) return;

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Create the channels up front so FCM pushes (which reference
    // habitChannelId) are never dropped for a missing channel.
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        habitChannelId,
        'Habit Reminders',
        description: 'Daily habit reminder notifications',
        importance: Importance.high,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        generalChannelId,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);
    await _ensureLocalTimezone();
  }

  /// Ask for the runtime permissions needed to show + exactly-timed reminders:
  /// POST_NOTIFICATIONS (Android 13+) and SCHEDULE_EXACT_ALARM (Android 12+).
  /// Safe to call repeatedly — already-granted/denied states resolve silently,
  /// only the first "undecided" request shows a system dialog.
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static bool _localTzResolved = false;

  /// Make sure [tz.local] is the device's real IANA timezone (e.g.
  /// "Asia/Kolkata"), not the timezone package's default (UTC). The scheduler
  /// computes reminder times against [tz.local], so without this a reminder
  /// fires at the wrong clock time — often a full day late. Best-effort:
  /// resolved once and cached; falls back to UTC on failure.
  static Future<void> _ensureLocalTimezone() async {
    if (_localTzResolved) return;
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      if (name.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(name));
        debugPrint('[NotificationService] Timezone set to $name');
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone resolve failed: $e');
    }
    _localTzResolved = true;
  }

  /// Schedule a habit reminder on the device (works even when the backend push
  /// is unreachable/misconfigured — it is the reliable fallback for the
  /// server-driven FCM reminder).
  ///
  /// [repeatDays] is a 7-bool list (Mon..Sun). Habits with no repeat day
  /// selected are treated as daily. One repeating notification is scheduled
  /// per selected weekday (plus a single daily one for daily habits), so a
  /// Mon–Fri habit never nags on the weekend.
  ///
  /// On Android 12+ exact alarms need SCHEDULE_EXACT_ALARM; if it isn't
  /// granted we silently fall back to an inexact alarm (may drift a few
  /// minutes) rather than failing to schedule at all.
  static Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required int hour,
    required int minute,
    List<bool> repeatDays = const [true, true, true, true, true, true, true],
    bool skipToday = false,
  }) async {
    if (kIsWeb) return;
    await _ensureLocalTimezone();
    // Cancel any previous reminder slots (daily/weekday) to prevent duplicate alarms
    await cancelHabitReminder(habitId);
    try {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await androidImpl?.canScheduleExactNotifications() ??
          true;
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          habitChannelId,
          'Habit Reminders',
          channelDescription: 'Daily habit reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      final hasRepeatDay = repeatDays.any((d) => d);
      if (!hasRepeatDay) {
        // Daily habit — a single repeating notification.
        await _plugin.zonedSchedule(
          _notificationId(habitId, slot: 0),
          '⏰ Time for your habit!',
          'Don\'t forget: $habitName',
          _nextInstanceOfTime(hour, minute, skipToday: skipToday),
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        return;
      }

      // One repeating weekly notification per selected weekday.
      for (var i = 0; i < repeatDays.length; i++) {
        if (!repeatDays[i]) continue;
        await _plugin.zonedSchedule(
          _notificationId(habitId, slot: i + 1),
          '⏰ Time for your habit!',
          'Don\'t forget: $habitName',
          _nextInstanceOfDay(
            hour,
            minute,
            weekdayIndex: i,
            skipToday: skipToday,
          ),
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule notification: $e');
    }
  }

  /// Cancel every slot scheduled for [habitId] (daily + all weekdays).
  static Future<void> cancelHabitReminder(String habitId) async {
    if (kIsWeb) return;
    try {
      final base = _notificationBase(habitId);
      for (var slot = 0; slot < 8; slot++) {
        await _plugin.cancel(base + slot);
      }
    } catch (_) {
      // Platform channel unavailable in test or background environments
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
    String channelId = generalChannelId,
  }) async {
    if (kIsWeb) return;
    final isHabitChannel = channelId == habitChannelId;
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isHabitChannel ? 'Habit Reminders' : 'General Notifications',
          channelDescription: isHabitChannel
              ? 'Daily habit reminder notifications'
              : 'General app notifications',
          importance:
              isHabitChannel ? Importance.high : Importance.defaultImportance,
          priority: isHabitChannel ? Priority.high : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Stable, bounded int id for a habit's reminder slot. Derived from the
  /// habit id string so create/delete/cancel always agree on the same ids,
  /// and capped well below Android's 32-bit notification id limit.
  ///
  /// Uses an explicit FNV-1a hash instead of [String.hashCode], which the Dart
  /// VM re-seeds per process. An unstable id would leave the previous session's
  /// repeating alarm alive after a restart, producing duplicate reminders.
  static int _notificationBase(String habitId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in habitId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    hash = hash % 100000000;
    return AppConstants.habitNotificationBaseId + hash * 8;
  }

  static int _notificationId(String habitId, {required int slot}) {
    return _notificationBase(habitId) + slot;
  }

  static tz.TZDateTime _nextInstanceOfTime(
    int hour,
    int minute, {
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (skipToday) {
      // Habit is already completed/handled today — start from tomorrow
      scheduled = scheduled.add(const Duration(days: 1));
      while (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Next occurrence of [hour]:[minute] on the given weekday
  /// ([weekdayIndex] 0 = Monday … 6 = Sunday).
  static tz.TZDateTime _nextInstanceOfDay(
    int hour,
    int minute, {
    required int weekdayIndex,
    bool skipToday = false,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final targetWeekday = weekdayIndex + 1; // tz: 1 = Monday … 7 = Sunday
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If today is the scheduled weekday and today's habit is completed, advance to tomorrow before searching
    if (skipToday && scheduled.weekday == targetWeekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
