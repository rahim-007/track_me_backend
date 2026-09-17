import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/core/local/json_file_cache.dart';
import 'package:track_me/core/widgets/home_widget_service.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

class _NoLoadHabitsNotifier extends HabitsNotifier {
  _NoLoadHabitsNotifier() : super();

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('track_me_test_cache_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (MethodCall methodCall) async => true,
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

  group('Habit Toggle & Rebound Prevention Tests', () {
    late HabitModel testHabit;
    late DateTime today;
    late String todayStr;

    setUp(() {
      today = DateTime.now();
      todayStr = DateFormat('yyyy-MM-dd').format(today);
      testHabit = HabitModel(
        id: 'temp_habit_test_1',
        name: 'Morning Meditation',
        category: 'Mindfulness',
        repeatDays: const [true, true, true, true, true, true, true],
        createdAt: today.subtract(const Duration(days: 7)),
        completedDates: [],
        skippedDates: [],
      );
    });

    test('toggleCompletion debounces rapid taps when debounce: true', () async {
      final notifier = _NoLoadHabitsNotifier();
      notifier.state = AsyncValue.data([testHabit]);

      // First tap marks it complete
      await notifier.toggleCompletion(testHabit, today, debounce: true);
      final firstState = notifier.state.value!.first;
      expect(firstState.completedDates.contains(todayStr), isTrue);

      // Immediate rapid second tap (within 450ms) is debounced
      await notifier.toggleCompletion(testHabit, today, debounce: true);
      final debouncedState = notifier.state.value!.first;
      expect(debouncedState.completedDates.contains(todayStr), isTrue,
          reason: 'Rapid double-tap must be ignored to prevent automatic unmarking');
    });

    test('toggleCompletion allows consecutive taps when debounce: false (programmatic/undo)', () async {
      final notifier = _NoLoadHabitsNotifier();
      notifier.state = AsyncValue.data([testHabit]);

      // First tap marks it complete
      await notifier.toggleCompletion(testHabit, today, debounce: false);
      expect(notifier.state.value!.first.completedDates.contains(todayStr), isTrue);

      // Second tap immediately unmarks when debounce is false
      await notifier.toggleCompletion(testHabit, today, debounce: false);
      expect(notifier.state.value!.first.completedDates.contains(todayStr), isFalse);
    });

    test('handleBackgroundToggle skips toggle when habit already matches desiredCompleted', () async {
      // Habit is already completed in cache
      final completedHabit = testHabit.copyWith(
        completedDates: [todayStr],
      );
      await JsonFileCache.write(
        'habits_cache',
        [completedHabit.toJson()],
      );

      // Call handleBackgroundToggle with desiredCompleted: true
      await HomeWidgetService.instance.handleBackgroundToggle(
        completedHabit.id,
        desiredCompleted: true,
      );

      // Verify habits_cache was NOT flipped back to uncompleted
      final cached = await JsonFileCache.read<List<HabitModel>>(
        'habits_cache',
        (json) => (json as List)
            .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      expect(cached, isNotNull);
      expect(cached!.first.completedDates.contains(todayStr), isTrue,
          reason: 'Must not flip completed habit to uncompleted when desiredCompleted is true');
      expect(HomeWidgetService.instance.isRecentlyHandled(completedHabit.id), isTrue);
    });

    test('HomeWidgetService isRecentlyHandled tracks handled habits for deduplication', () {
      final service = HomeWidgetService.instance;
      expect(service.isRecentlyHandled('habit_test_dedup_xyz'), isFalse);

      service.markHandled('habit_test_dedup_xyz');
      expect(service.isRecentlyHandled('habit_test_dedup_xyz'), isTrue);
    });
  });
}

