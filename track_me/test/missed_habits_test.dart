import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';
import 'package:track_me/features/habits/providers/missed_habits_provider.dart';

class _FakeHabitsNotifier extends HabitsNotifier {
  final List<HabitModel> _fakeHabits;
  _FakeHabitsNotifier(this._fakeHabits);

  @override
  Future<void> loadHabits() async {
    state = AsyncValue.data(_fakeHabits);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

  HabitModel buildTestHabit({
    required String id,
    required String name,
    required DateTime createdAt,
    List<String> completedDates = const [],
    List<String> skippedDates = const [],
    List<bool> repeatDays = const [true, true, true, true, true, true, true],
  }) {
    return HabitModel(
      id: id,
      name: name,
      category: 'Health',
      createdAt: createdAt,
      completedDates: List.from(completedDates),
      skippedDates: List.from(skippedDates),
      repeatDays: repeatDays,
    );
  }

  group('MissedHabitEntry validation', () {
    test('needsReason is true only when answered didComplete == false', () {
      final habit = buildTestHabit(
        id: 'h1',
        name: 'Drink Water',
        createdAt: yesterday.subtract(const Duration(days: 2)),
      );

      final entry = MissedHabitEntry(habit: habit);
      expect(entry.needsReason, isFalse); // null initially

      entry.didComplete = true;
      expect(entry.needsReason, isFalse);

      entry.didComplete = false;
      expect(entry.needsReason, isTrue);
    });

    test('isValid accepts completions without reason', () {
      final habit = buildTestHabit(
        id: 'h1',
        name: 'Drink Water',
        createdAt: yesterday.subtract(const Duration(days: 2)),
      );

      final entry = MissedHabitEntry(habit: habit, didComplete: true);
      expect(entry.isValid, isTrue);
    });

    test('isValid enforces >= 5 characters when habit is missed', () {
      final habit = buildTestHabit(
        id: 'h1',
        name: 'Drink Water',
        createdAt: yesterday.subtract(const Duration(days: 2)),
      );

      final entry = MissedHabitEntry(habit: habit, didComplete: false, reason: 'Busy');
      expect(entry.isValid, isFalse); // 'Busy' has 4 chars

      entry.reason = 'Tired';
      expect(entry.isValid, isTrue); // 'Tired' has 5 chars

      entry.reason = 'Had a long exhausting day at work';
      expect(entry.isValid, isTrue);
    });
  });

  group('missedYesterdayHabitsProvider filtering logic', () {
    test('identifies genuinely missed habits from yesterday and excludes others', () async {
      final pastDate = yesterday.subtract(const Duration(days: 5));

      final missedHabit = buildTestHabit(
        id: 'missed-1',
        name: 'Read 20 pages',
        createdAt: pastDate,
        completedDates: [],
        skippedDates: [],
      );

      final completedYesterdayHabit = buildTestHabit(
        id: 'done-1',
        name: 'Morning Jog',
        createdAt: pastDate,
        completedDates: [yesterdayStr],
        skippedDates: [],
      );

      final skippedYesterdayHabit = buildTestHabit(
        id: 'skipped-1',
        name: 'Meditation',
        createdAt: pastDate,
        completedDates: [],
        skippedDates: [yesterdayStr],
      );

      final createdTodayHabit = buildTestHabit(
        id: 'today-1',
        name: 'Evening Piano',
        createdAt: today,
        completedDates: [],
        skippedDates: [],
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => _FakeHabitsNotifier([
              missedHabit,
              completedYesterdayHabit,
              skippedYesterdayHabit,
              createdTodayHabit,
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Force habits to load
      await container.read(habitsProvider.notifier).loadHabits();

      // Read missed habits provider
      final missedList = await container.read(missedYesterdayHabitsProvider.future);

      expect(missedList.length, 1);
      expect(missedList.first.id, 'missed-1');
      expect(missedList.first.name, 'Read 20 pages');
    });

    test('returns empty list when all scheduled habits were completed or skipped', () async {
      final pastDate = yesterday.subtract(const Duration(days: 3));

      final habit1 = buildTestHabit(
        id: 'h1',
        name: 'Exercise',
        createdAt: pastDate,
        completedDates: [yesterdayStr],
      );

      final habit2 = buildTestHabit(
        id: 'h2',
        name: 'Journaling',
        createdAt: pastDate,
        skippedDates: [yesterdayStr],
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => _FakeHabitsNotifier([habit1, habit2]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.notifier).loadHabits();

      final missedList = await container.read(missedYesterdayHabitsProvider.future);
      expect(missedList, isEmpty);
    });

    test('handles empty habits list without error or hanging', () async {
      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith((ref) => _FakeHabitsNotifier([])),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.notifier).loadHabits();

      final missedList = await container.read(missedYesterdayHabitsProvider.future);
      expect(missedList, isEmpty);
    });

    test('treats habit with empty/all-false repeatDays as scheduled daily', () async {
      final pastDate = yesterday.subtract(const Duration(days: 4));
      final allFalseHabit = buildTestHabit(
        id: 'all-false-1',
        name: 'Daily Stretch',
        createdAt: pastDate,
        repeatDays: List.filled(7, false),
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => _FakeHabitsNotifier([allFalseHabit]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.notifier).loadHabits();

      final missedList = await container.read(missedYesterdayHabitsProvider.future);
      expect(missedList.length, 1);
      expect(missedList.first.id, 'all-false-1');
    });

    test('excludes habit not scheduled for yesterday weekday', () async {
      final pastDate = yesterday.subtract(const Duration(days: 4));
      final yesterdayWeekdayIndex = yesterday.weekday - 1;

      // Repeat days where yesterday is false, but another day is true
      final repeatDays = List.filled(7, false);
      final otherDayIndex = (yesterdayWeekdayIndex + 1) % 7;
      repeatDays[otherDayIndex] = true;

      final unscheduledHabit = buildTestHabit(
        id: 'unscheduled-1',
        name: 'Weekend Only Habit',
        createdAt: pastDate,
        repeatDays: repeatDays,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => _FakeHabitsNotifier([unscheduledHabit]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.notifier).loadHabits();

      final missedList = await container.read(missedYesterdayHabitsProvider.future);
      expect(missedList, isEmpty);
    });

    test('correctly handles createdAt with UTC time offsets', () async {
      // Habit created yesterday in UTC
      final habitCreatedYesterdayUtc = buildTestHabit(
        id: 'utc-yesterday',
        name: 'Yesterday Habit',
        createdAt: yesterday.toUtc(),
      );

      // Habit created today in UTC
      final habitCreatedTodayUtc = buildTestHabit(
        id: 'utc-today',
        name: 'Today Habit',
        createdAt: today.toUtc(),
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => _FakeHabitsNotifier([
              habitCreatedYesterdayUtc,
              habitCreatedTodayUtc,
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(habitsProvider.notifier).loadHabits();

      final missedList = await container.read(missedYesterdayHabitsProvider.future);
      expect(missedList.length, 1);
      expect(missedList.first.id, 'utc-yesterday');
    });
  });
}
