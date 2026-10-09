import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/core/widgets/home_widget_service.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final savedWidgetData = <String, dynamic>{};

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('track_me_widget_schedule_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'saveWidgetData') {
          final args = methodCall.arguments as Map;
          savedWidgetData[args['id']] = args['data'];
          return true;
        } else if (methodCall.method == 'getWidgetData') {
          final args = methodCall.arguments as Map;
          return savedWidgetData[args['id']];
        } else if (methodCall.method == 'updateWidget') {
          return true;
        }
        return true;
      },
    );
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    savedWidgetData.clear();
  });

  test('Habit excluded for today is never sent to the widget habits_json', () async {
    final now = DateTime.now();
    final todayWeekdayIndex = now.weekday - 1; // 0 = Mon, 6 = Sun

    // Habit 1: Scheduled only for today
    final repeatToday = List.filled(7, false);
    repeatToday[todayWeekdayIndex] = true;
    final scheduledHabit = HabitModel(
      id: 'scheduled_1',
      name: 'Reading',
      category: 'Education',
      repeatDays: repeatToday,
      createdAt: now.subtract(const Duration(days: 3)),
      completedDates: [],
      skippedDates: [],
    );

    // Habit 2: Gym scheduled for other days, but excluded today
    final repeatOtherDays = List.filled(7, true);
    repeatOtherDays[todayWeekdayIndex] = false; // Excluded today!
    final excludedGymHabit = HabitModel(
      id: 'gym_excluded',
      name: 'Gym Workout',
      category: 'Fitness',
      repeatDays: repeatOtherDays,
      createdAt: now.subtract(const Duration(days: 3)),
      completedDates: [],
      skippedDates: [],
    );

    await HomeWidgetService.instance.syncHabitsData(
      habits: [scheduledHabit, excludedGymHabit],
      overallStreak: 1,
    );

    final habitsJson = savedWidgetData['habits_json'] as String?;
    expect(habitsJson, isNotNull);

    final items = (jsonDecode(habitsJson!) as List).cast<Map<String, dynamic>>();
    expect(items.length, 1);
    expect(items.first['id'], 'scheduled_1');
    expect(items.any((i) => i['id'] == 'gym_excluded'), isFalse,
        reason: 'Excluded habit must not appear in the widget');

    expect(savedWidgetData['total_count'], 1);
    expect(savedWidgetData['completed_count'], 0);
    expect(savedWidgetData['progress_percent'], 0);
    expect(savedWidgetData['progress_ratio'], '0/1');
  });

  test('Widget progress percent is strictly clamped to 100% and never reaches 125%', () async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayWeekdayIndex = now.weekday - 1;

    final repeatToday = List.filled(7, false);
    repeatToday[todayWeekdayIndex] = true;

    // 2 habits scheduled today, both completed
    final habit1 = HabitModel(
      id: 'h1',
      name: 'Habit 1',
      category: 'Health',
      repeatDays: repeatToday,
      createdAt: now.subtract(const Duration(days: 3)),
      completedDates: [todayStr],
      skippedDates: [],
    );
    final habit2 = HabitModel(
      id: 'h2',
      name: 'Habit 2',
      category: 'Health',
      repeatDays: repeatToday,
      createdAt: now.subtract(const Duration(days: 3)),
      completedDates: [todayStr],
      skippedDates: [],
    );

    // Unscheduled habit with completedDates containing today
    final repeatOtherDays = List.filled(7, true);
    repeatOtherDays[todayWeekdayIndex] = false;
    final unscheduledHabit = HabitModel(
      id: 'h_unscheduled',
      name: 'Gym',
      category: 'Fitness',
      repeatDays: repeatOtherDays,
      createdAt: now.subtract(const Duration(days: 3)),
      completedDates: [todayStr],
      skippedDates: [],
    );

    await HomeWidgetService.instance.syncHabitsData(
      habits: [habit1, habit2, unscheduledHabit],
      overallStreak: 3,
    );

    expect(savedWidgetData['total_count'], 2);
    expect(savedWidgetData['completed_count'], 2);
    expect(savedWidgetData['progress_percent'], 100);
    expect(savedWidgetData['progress_ratio'], '2/2');

    final habitsJson = savedWidgetData['habits_json'] as String?;
    final items = (jsonDecode(habitsJson!) as List).cast<Map<String, dynamic>>();
    expect(items.length, 2);
    expect(items.any((i) => i['id'] == 'h_unscheduled'), isFalse);
  });

  test('When no habits are scheduled for today, widget shows empty state without errors', () async {
    final now = DateTime.now();
    final todayWeekdayIndex = now.weekday - 1;

    // All habits excluded today
    final repeatOtherDays = List.filled(7, true);
    repeatOtherDays[todayWeekdayIndex] = false;

    final habit1 = HabitModel(
      id: 'h1',
      name: 'Weekday Only 1',
      category: 'Work',
      repeatDays: repeatOtherDays,
      createdAt: now.subtract(const Duration(days: 2)),
      completedDates: [],
      skippedDates: [],
    );
    final habit2 = HabitModel(
      id: 'h2',
      name: 'Weekday Only 2',
      category: 'Work',
      repeatDays: repeatOtherDays,
      createdAt: now.subtract(const Duration(days: 2)),
      completedDates: [],
      skippedDates: [],
    );

    await HomeWidgetService.instance.syncHabitsData(
      habits: [habit1, habit2],
      overallStreak: 0,
    );

    expect(savedWidgetData['total_count'], 0);
    expect(savedWidgetData['completed_count'], 0);
    expect(savedWidgetData['progress_percent'], 0);
    expect(savedWidgetData['progress_ratio'], '0/0');

    final habitsJson = savedWidgetData['habits_json'] as String?;
    final items = (jsonDecode(habitsJson!) as List).cast<Map<String, dynamic>>();
    expect(items, isEmpty);
  });
}
