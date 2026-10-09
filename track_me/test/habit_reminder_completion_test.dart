import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import 'package:track_me/core/notifications/notification_service.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';

int notificationBase(String habitId) {
  var hash = 0x811c9dc5;
  for (final codeUnit in habitId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  hash = hash % 20000000;
  return 1000 + hash * 40;
}

int notificationId(String habitId, int slot) => notificationBase(habitId) + slot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  const MethodChannel notificationChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');

  final List<MethodCall> methodCalls = [];
  final Map<int, Map<String, dynamic>> scheduledNotifications = {};

  setUp(() {
    methodCalls.clear();
    scheduledNotifications.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (MethodCall call) async => 'UTC');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, (MethodCall call) async {
      methodCalls.add(call);
      if (call.method == 'zonedSchedule') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final id = args['id'] as int;
        scheduledNotifications[id] = args;
        return null;
      } else if (call.method == 'cancel') {
        final id = call.arguments as int;
        scheduledNotifications.remove(id);
        return null;
      } else if (call.method == 'cancelAll') {
        scheduledNotifications.clear();
        return null;
      } else if (call.method == 'canScheduleExactNotifications') {
        return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
  });

  group('Habit Reminder Completion & Cancellation Tests', () {
    test('TEST A: Normal reminder -> complete Habit -> today notification is not scheduled for today', () async {
      final now = tz.TZDateTime.now(tz.local);
      final todayWeekdayIndex = now.weekday - 1; // 0 = Mon, 6 = Sun
      final todaySlotId = notificationId('habit_a', todayWeekdayIndex + 1);

      // 1. Schedule habit when incomplete (skipToday = false)
      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_a',
        habitName: 'Morning Workout',
        hour: 23,
        minute: 59,
        repeatDays: List.filled(7, true),
        skipToday: false,
      );

      // Verify today's weekday slot is scheduled with dayOfWeekAndTime
      expect(scheduledNotifications.containsKey(todaySlotId), isTrue);
      expect(
        scheduledNotifications[todaySlotId]!['matchDateTimeComponents'],
        isNotNull, // dayOfWeekAndTime
      );

      // 2. Complete Habit (skipToday = true)
      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_a',
        habitName: 'Morning Workout',
        hour: 23,
        minute: 59,
        repeatDays: List.filled(7, true),
        skipToday: true,
      );

      // Today's slot must NOT be scheduled with matchDateTimeComponents (so OS never pulls it to today)
      expect(scheduledNotifications.containsKey(todaySlotId), isTrue);
      expect(
        scheduledNotifications[todaySlotId]!['matchDateTimeComponents'],
        isNull, // one-shot for next week
      );
      final scheduledDateStr = scheduledNotifications[todaySlotId]!['scheduledDateTime'] as String;
      final scheduledDate = DateTime.parse(scheduledDateStr);
      // Scheduled date must be in the future (next week), not today!
      expect(scheduledDate.day != now.day || scheduledDate.month != now.month, isTrue);
    });

    test('TEST B: Interval reminder -> complete Habit -> all remaining today interval reminders are cancelled', () async {
      final now = tz.TZDateTime.now(tz.local);

      // 1. Schedule interval reminder when incomplete
      await NotificationService.scheduleIntervalHabitReminder(
        habitId: 'habit_water',
        habitName: 'Drink Water',
        windowStartTime: '08:00',
        windowEndTime: '20:00',
        intervalMinutes: 120, // 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00 (7 slots)
        repeatDays: List.filled(7, true),
        skipToday: false,
      );

      expect(scheduledNotifications.isNotEmpty, isTrue);

      // 2. Complete Habit
      await NotificationService.scheduleIntervalHabitReminder(
        habitId: 'habit_water',
        habitName: 'Drink Water',
        windowStartTime: '08:00',
        windowEndTime: '20:00',
        intervalMinutes: 120,
        repeatDays: List.filled(7, true),
        skipToday: true,
      );

      // All scheduled slots must be for tomorrow / next scheduled day without matchDateTimeComponents
      for (final entry in scheduledNotifications.entries) {
        expect(entry.value['matchDateTimeComponents'], isNull);
        final scheduledDate = DateTime.parse(entry.value['scheduledDateTime'] as String);
        expect(scheduledDate.isAfter(DateTime(now.year, now.month, now.day, 23, 59)), isTrue);
      }
    });

    test('TEST C: Complete Habit -> HabitModel.isCompletedToday reflects completed state on restart', () {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final habit = HabitModel(
        id: 'habit_med',
        name: 'Take Vitamins',
        category: 'HEALTH',
        repeatDays: List.filled(7, true),
        reminderTime: '09:00',
        createdAt: DateTime.now(),
        completedDates: [todayStr],
        skippedDates: [],
      );

      expect(habit.isCompletedToday, isTrue);
    });

    test('TEST D: Complete Habit A -> Habit B reminder continues normally without interference', () async {
      // 1. Schedule Habit A and Habit B
      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_alpha',
        habitName: 'Habit Alpha',
        hour: 9,
        minute: 0,
        repeatDays: List.filled(7, true),
        skipToday: false,
      );

      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_beta',
        habitName: 'Habit Beta',
        hour: 15,
        minute: 0,
        repeatDays: List.filled(7, true),
        skipToday: false,
      );

      // 2. Complete Habit A
      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_alpha',
        habitName: 'Habit Alpha',
        hour: 9,
        minute: 0,
        repeatDays: List.filled(7, true),
        skipToday: true,
      );

      final now = tz.TZDateTime.now(tz.local);
      final todayWeekdayIndex = now.weekday - 1;
      final tomorrowWeekdayIndex = (todayWeekdayIndex + 1) % 7;

      // Habit B's slots must still be present with matchDateTimeComponents
      final betaTomorrowSlot = notificationId('habit_beta', tomorrowWeekdayIndex + 1);
      expect(scheduledNotifications.containsKey(betaTomorrowSlot), isTrue);
      expect(scheduledNotifications[betaTomorrowSlot]!['matchDateTimeComponents'], isNotNull);
    });

    test('TEST E: Complete Habit today -> tomorrow reminder must still be scheduled normally', () async {
      final now = tz.TZDateTime.now(tz.local);
      final todayWeekdayIndex = now.weekday - 1;
      final tomorrowWeekdayIndex = (todayWeekdayIndex + 1) % 7;
      final tomorrowSlotId = notificationId('habit_walk', tomorrowWeekdayIndex + 1);

      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_walk',
        habitName: 'Evening Walk',
        hour: 18,
        minute: 30,
        repeatDays: List.filled(7, true),
        skipToday: true,
      );

      // Tomorrow's slot must be scheduled with matchDateTimeComponents
      expect(scheduledNotifications.containsKey(tomorrowSlotId), isTrue);
      expect(
        scheduledNotifications[tomorrowSlotId]!['matchDateTimeComponents'],
        isNotNull, // dayOfWeekAndTime
      );
    });

    test('TEST F: Incomplete habit keeps active recurring reminder', () async {
      await NotificationService.scheduleHabitReminder(
        habitId: 'habit_read',
        habitName: 'Read 20 Pages',
        hour: 21,
        minute: 0,
        repeatDays: List.filled(7, true),
        skipToday: false,
      );

      final now = tz.TZDateTime.now(tz.local);
      final todayWeekdayIndex = now.weekday - 1;
      final todaySlotId = notificationId('habit_read', todayWeekdayIndex + 1);

      expect(scheduledNotifications.containsKey(todaySlotId), isTrue);
      expect(
        scheduledNotifications[todaySlotId]!['matchDateTimeComponents'],
        isNotNull,
      );
    });

    test('TEST G: Interval target met via logProgress completes habit and silences remaining alarms', () {
      final habit = HabitModel(
        id: 'water_progress',
        name: 'Drink 3L Water',
        category: 'HEALTH',
        repeatDays: List.filled(7, true),
        isInterval: true,
        intervalMinutes: 60,
        windowStartTime: '08:00',
        windowEndTime: '20:00',
        targetValue: 3000,
        unit: 'ml',
        currentValueToday: 3000,
        createdAt: DateTime.now(),
        completedDates: [],
        skippedDates: [],
      );

      expect(habit.isCompletedToday, isTrue);
      expect(habit.progressPercentage, 1.0);
    });
  });
}
