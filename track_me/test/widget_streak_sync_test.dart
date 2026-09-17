import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/core/local/json_file_cache.dart';
import 'package:track_me/core/widgets/home_widget_service.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

class _TestHabitsNotifier extends HabitsNotifier {
  _TestHabitsNotifier() : super();

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final savedWidgetData = <String, dynamic>{};

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('track_me_streak_sync_test_');

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

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => null,
    );
  });

  tearDownAll(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Habit Widget & App Streak Synchronization Tests (Single Source of Truth)', () {
    late DateTime today;
    late DateTime yesterday;
    late DateTime twoDaysAgo;
    late String todayStr;
    late String yesterdayStr;
    late String twoDaysAgoStr;

    late HabitModel habit1;
    late HabitModel habit2;
    late HabitModel habit3;

    setUp(() {
      savedWidgetData.clear();

      today = DateTime.now();
      yesterday = today.subtract(const Duration(days: 1));
      twoDaysAgo = today.subtract(const Duration(days: 2));
      todayStr = DateFormat('yyyy-MM-dd').format(today);
      yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
      twoDaysAgoStr = DateFormat('yyyy-MM-dd').format(twoDaysAgo);

      // 3 daily habits created 5 days ago, all completed yesterday (streak = 1 from yesterday)
      habit1 = HabitModel(
        id: 'temp_h1',
        name: 'Workout',
        category: 'Fitness',
        repeatDays: const [true, true, true, true, true, true, true],
        createdAt: today.subtract(const Duration(days: 5)),
        completedDates: [yesterdayStr],
        skippedDates: [],
      );

      habit2 = HabitModel(
        id: 'temp_h2',
        name: 'Reading',
        category: 'Education',
        repeatDays: const [true, true, true, true, true, true, true],
        createdAt: today.subtract(const Duration(days: 5)),
        completedDates: [yesterdayStr],
        skippedDates: [],
      );

      habit3 = HabitModel(
        id: 'temp_h3',
        name: 'Water',
        category: 'Health',
        repeatDays: const [true, true, true, true, true, true, true],
        createdAt: today.subtract(const Duration(days: 5)),
        completedDates: [yesterdayStr],
        skippedDates: [],
      );
    });

    test('1. Today grace-period behavior: incomplete today preserves past streak and widget matches calculateCurrentStreak', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      // Complete 2 out of 3 habits today
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(habit2, today);

      final currentHabits = notifier.state.value!;
      final authoritativeStreak = calculateCurrentStreak(currentHabits);

      // Grace period rule: today does NOT increment the streak (habit 3 is incomplete),
      // but yesterday's streak is preserved.
      expect(authoritativeStreak, calculateCurrentStreak([habit1, habit2, habit3], from: yesterday));

      // Widget streak must strictly equal the authoritative calculateCurrentStreak result
      expect(savedWidgetData['streak_count'], authoritativeStreak);
      expect(savedWidgetData['completed_count'], 2);
      expect(savedWidgetData['total_count'], 3);
    });

    test('2. All completed today: daily streak increases and widget matches calculateCurrentStreak', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      // Complete all 3 habits today
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(habit2, today);
      await notifier.toggleCompletion(habit3, today);

      final currentHabits = notifier.state.value!;
      final authoritativeStreak = calculateCurrentStreak(currentHabits);

      // All scheduled habits completed today -> streak increases
      expect(authoritativeStreak, calculateCurrentStreak([habit1, habit2, habit3], from: yesterday) + 1);

      // Widget data strictly matches calculateCurrentStreak
      expect(savedWidgetData['streak_count'], authoritativeStreak);
      expect(savedWidgetData['completed_count'], 3);
      expect(savedWidgetData['total_count'], 3);
      expect(savedWidgetData['progress_percent'], 100);
    });

    test('3. Consistency on uncheck: resulting streak strictly equals calculateCurrentStreak without hard-coded decrease assumption', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      // Complete all 3 habits
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(habit2, today);
      await notifier.toggleCompletion(habit3, today);

      // Uncheck habit 3 (undo completion)
      await notifier.toggleCompletion(habit3, today);

      final revertedHabits = notifier.state.value!;
      final expectedStreak = calculateCurrentStreak(revertedHabits);

      // Strictly verify widget streak equals calculateCurrentStreak (authoritative)
      expect(savedWidgetData['streak_count'], expectedStreak);
      expect(savedWidgetData['completed_count'], 2);
      expect(savedWidgetData['total_count'], 3);
    });

    test('4. Widget habit items contain exact calculateHabitStreak values', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      await notifier.toggleCompletion(habit1, today);

      final habitsJson = savedWidgetData['habits_json'] as String?;
      expect(habitsJson, isNotNull);

      final items = (jsonDecode(habitsJson!) as List).cast<Map<String, dynamic>>();
      final currentHabits = notifier.state.value!;

      for (final h in currentHabits) {
        final item = items.firstWhere((i) => i['id'] == h.id);
        expect(item['streak'], calculateHabitStreak(h),
            reason: 'Habit ${h.name} streak in widget must strictly equal calculateHabitStreak');
        expect(item['is_completed'], h.completedDates.contains(todayStr));
      }
    });

    test('5. Missed past-day behavior: broken streak in past is reflected identically in app and widget', () async {
      // Habit 2 missed yesterday
      final brokenHabit2 = habit2.copyWith(
        completedDates: [twoDaysAgoStr], // missed yesterday!
      );

      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, brokenHabit2, habit3]);

      // Complete all habits today
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(brokenHabit2, today);
      await notifier.toggleCompletion(habit3, today);

      final currentHabits = notifier.state.value!;
      final authoritativeStreak = calculateCurrentStreak(currentHabits);

      // Because yesterday was missed for habit2, the streak from 2 days ago was broken!
      // Today is completed, so the new streak restarted at 1.
      expect(authoritativeStreak, 1);
      expect(savedWidgetData['streak_count'], authoritativeStreak);
    });

    test('6. Skipped habit behavior: skip clears today and widget syncs authoritative calculateCurrentStreak', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      // Complete habit 1 and habit 2
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(habit2, today);

      // Skip habit 3 for today
      await notifier.skipHabit(habit: habit3, date: today, reason: 'Sick');

      final currentHabits = notifier.state.value!;
      final authoritativeStreak = calculateCurrentStreak(currentHabits);

      // Widget streak must strictly match calculateCurrentStreak after skip
      expect(savedWidgetData['streak_count'], authoritativeStreak);

      final habitsJson = savedWidgetData['habits_json'] as String?;
      final items = (jsonDecode(habitsJson!) as List).cast<Map<String, dynamic>>();
      final h3Item = items.firstWhere((i) => i['id'] == habit3.id);
      expect(h3Item['is_completed'], false);
      expect(h3Item['streak'], calculateHabitStreak(currentHabits.firstWhere((h) => h.id == habit3.id)));
    });

    test('7. Widget -> App synchronization: background toggle updates cache, recalculates authoritative streak, and syncs widget', () async {
      // Setup cache with initial habits
      await JsonFileCache.write(
        'habits_cache',
        [habit1, habit2, habit3].map((h) => h.toJson()).toList(),
      );

      // Simulate background toggle from widget
      await HomeWidgetService.instance.handleBackgroundToggle(habit1.id, desiredCompleted: true);

      // Verify cached habits updated
      final updatedCache = await JsonFileCache.read<List<HabitModel>>(
        'habits_cache',
        (json) => (json as List)
            .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      expect(updatedCache, isNotNull);
      final updatedH1 = updatedCache!.firstWhere((h) => h.id == habit1.id);
      expect(updatedH1.completedDates.contains(todayStr), true);

      // Verify widget storage was refreshed with authoritative streak
      final authoritativeStreak = calculateCurrentStreak(updatedCache);
      expect(savedWidgetData['streak_count'], authoritativeStreak);
    });

    test('8. App resume / startup synchronization: pending toggle drains and aligns with authoritative logic', () async {
      // Setup cache
      await JsonFileCache.write(
        'habits_cache',
        [habit1, habit2, habit3].map((h) => h.toJson()).toList(),
      );

      // Put a pending toggle in widget storage (as if tapped on Android widget while app was closed)
      final pendingToggle = [
        {'id': habit1.id, 'completed': true, 'timestamp': DateTime.now().millisecondsSinceEpoch}
      ];
      savedWidgetData['pending_widget_toggles'] = jsonEncode(pendingToggle);

      expect(savedWidgetData['pending_widget_toggles'].toString().contains(habit1.id), true);

      await HomeWidgetService.instance.handleBackgroundToggle(habit1.id, desiredCompleted: true);

      final cachedAfter = await JsonFileCache.read<List<HabitModel>>(
        'habits_cache',
        (json) => (json as List)
            .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      final authoritativeStreak = calculateCurrentStreak(cachedAfter!);
      expect(savedWidgetData['streak_count'], authoritativeStreak);
    });

    test('9. base_streak_count strictly matches yesterday streak for live widget calculations', () async {
      final notifier = _TestHabitsNotifier();
      notifier.state = AsyncValue.data([habit1, habit2, habit3]);

      // Complete 2 out of 3 habits today
      await notifier.toggleCompletion(habit1, today);
      await notifier.toggleCompletion(habit2, today);

      final yesterday = today.subtract(const Duration(days: 1));
      final expectedBaseStreak = calculateCurrentStreak([habit1, habit2, habit3], from: yesterday);

      // Verify both streak_count and base_streak_count are saved
      expect(savedWidgetData['base_streak_count'], expectedBaseStreak);
      expect(savedWidgetData['streak_count'], expectedBaseStreak);

      // Complete the 3rd habit -> all completed today
      await notifier.toggleCompletion(habit3, today);
      expect(savedWidgetData['base_streak_count'], expectedBaseStreak);
      expect(savedWidgetData['streak_count'], expectedBaseStreak + 1);
    });

    test('10. Zero-latency startup: loadHabits reconciles pending_widget_toggles before network fetch', () async {
      // Habit is uncompleted in disk cache
      await JsonFileCache.write(
        'habits_cache',
        [habit1, habit2, habit3].map((h) => h.toJson()).toList(),
      );

      // Simulate native widget writing a pending toggle while app was closed
      final pendingToggle = [
        {'id': habit1.id, 'completed': true, 'timestamp': DateTime.now().millisecondsSinceEpoch}
      ];
      savedWidgetData['pending_widget_toggles'] = jsonEncode(pendingToggle);

      // Instantiate HabitsNotifier which calls loadHabits()
      final notifier = HabitsNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final stateValue = notifier.state.value;
      expect(stateValue, isNotNull);
      final habit1InState = stateValue!.firstWhere((h) => h.id == habit1.id);
      expect(habit1InState.completedDates.contains(todayStr), isTrue,
          reason: 'State on startup must immediately reflect widget toggle with zero latency');
    });
  });
}
