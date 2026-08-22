import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/widgets/habit_grid_row.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

/// Real HabitsNotifier logic, but without the network/cache load on startup.
class _NoLoadHabitsNotifier extends HabitsNotifier {
  _NoLoadHabitsNotifier();

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }
}

HabitModel habit(
  String id, {
  List<String> completed = const [],
  List<String> skipped = const [],
}) =>
    HabitModel(
      id: id,
      name: 'Habit $id',
      category: 'Health',
      emoji: '💪',
      color: '#7C3AED',
      repeatDays: List.filled(7, true),
      reminderTime: null,
      notes: null,
      createdAt: DateTime(2026, 1, 1),
      completedDates: List.of(completed),
      skippedDates: List.of(skipped),
    );

int completedCount(HabitsNotifier notifier, String dateStr) {
  return (notifier.state.valueOrNull ?? [])
      .where((h) => h.completedDates.contains(dateStr))
      .length;
}

void main() {
  final today = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(today);

  group('Habit status state machine (provider)', () {
    test('Pending -> Completed increases progress exactly once', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      expect(completedCount(notifier, todayStr), 0);
      await notifier.toggleCompletion(h, today);
      expect(completedCount(notifier, todayStr), 1);
      expect(notifier.state.valueOrNull!.single.completedDates,
          contains(todayStr));
      expect(notifier.state.valueOrNull!.single.skippedDates, isEmpty);
    });

    test('Completed -> tap again (undo) never double-counts', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      await notifier.toggleCompletion(h, today);
      expect(completedCount(notifier, todayStr), 1);

      await notifier.toggleCompletion(h, today); // undo
      expect(completedCount(notifier, todayStr), 0);

      await notifier.toggleCompletion(h, today); // complete again
      expect(completedCount(notifier, todayStr), 1);
      final dates = notifier.state.valueOrNull!.single.completedDates
          .where((d) => d == todayStr)
          .length;
      expect(dates, 1); // never duplicated
    });

    test('Pending -> Skipped does not increase progress', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      await notifier.skipHabit(habit: h, date: today, reason: 'Too Busy');
      expect(completedCount(notifier, todayStr), 0);
      expect(
          notifier.state.valueOrNull!.single.skippedDates, contains(todayStr));
      expect(notifier.state.valueOrNull!.single.completedDates, isEmpty);
    });

    test('Skipped -> Skipped is idempotent and never completes', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      await notifier.skipHabit(habit: h, date: today, reason: 'Forgot');
      await notifier.skipHabit(habit: h, date: today, reason: 'Forgot');
      final state = notifier.state.valueOrNull!.single;
      expect(state.skippedDates.where((d) => d == todayStr).length, 1);
      expect(state.completedDates, isEmpty);
      expect(completedCount(notifier, todayStr), 0);
    });

    test('Skipped -> Completed via toggle is blocked (no-op)', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a', skipped: [todayStr]);
      notifier.state = AsyncValue.data([h]);

      await notifier.toggleCompletion(h, today);
      final state = notifier.state.valueOrNull!.single;
      expect(state.completedDates, isEmpty); // still not completed
      expect(state.skippedDates, contains(todayStr)); // still skipped
      expect(completedCount(notifier, todayStr), 0);
    });

    test('3 habits: 2 done + 1 skipped stays 2/3 after repeat skip and toggle',
        () async {
      final notifier = _NoLoadHabitsNotifier();
      final a = habit('temp_a');
      final b = habit('temp_b');
      final c = habit('temp_c');
      notifier.state = AsyncValue.data([a, b, c]);

      await notifier.toggleCompletion(a, today);
      await notifier.toggleCompletion(b, today);
      expect(completedCount(notifier, todayStr), 2); // 2/3

      await notifier.skipHabit(habit: c, date: today, reason: 'Traveling');
      expect(completedCount(notifier, todayStr), 2); // 2/3

      await notifier.skipHabit(habit: c, date: today, reason: 'Traveling');
      expect(completedCount(notifier, todayStr), 2); // still 2/3

      await notifier.toggleCompletion(c, today); // attempted flip
      expect(completedCount(notifier, todayStr), 2); // still 2/3
      expect(notifier.state.valueOrNull!.last.skippedDates, contains(todayStr));
    });

    test('skipping clears any existing completion for that day', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      await notifier.toggleCompletion(h, today);
      expect(completedCount(notifier, todayStr), 1);

      await notifier.skipHabit(habit: h, date: today, reason: 'Sick');
      final state = notifier.state.valueOrNull!.single;
      expect(state.completedDates, isEmpty);
      expect(state.skippedDates, contains(todayStr));
      expect(completedCount(notifier, todayStr), 0);
    });

    test('statuses stay independent per date', () async {
      final notifier = _NoLoadHabitsNotifier();
      final h = habit('temp_a');
      notifier.state = AsyncValue.data([h]);

      final day1 = DateTime(2026, 8, 17); // Monday
      final day2 = DateTime(2026, 8, 18); // Tuesday
      final day1Str = DateFormat('yyyy-MM-dd').format(day1);
      final day2Str = DateFormat('yyyy-MM-dd').format(day2);

      await notifier.toggleCompletion(h, day1);
      await notifier.skipHabit(habit: h, date: day2, reason: 'Busy');

      final state = notifier.state.valueOrNull!.single;
      expect(state.completedDates, contains(day1Str));
      expect(state.skippedDates, contains(day2Str));
      expect(state.completedDates.contains(day2Str), isFalse);
    });
  });

  group('Habit status button (widget)', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      required HabitModel h,
      required VoidCallback onComplete,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsProvider.overrideWith((ref) => _NoLoadHabitsNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HabitGridRow(
                habit: h,
                selectedDate: today,
                onComplete: (_) => onComplete(),
                onSkip: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Pending shows Mark and tapping it completes', (tester) async {
      var completeCalls = 0;
      await pumpRow(
        tester,
        h: habit('temp_a'),
        onComplete: () => completeCalls++,
      );

      expect(find.text('Mark'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget); // skip available when pending

      await tester.tap(find.text('Mark'));
      await tester.pumpAndSettle();
      expect(completeCalls, 1);
    });

    testWidgets('tapping the Skipped button does NOT complete the habit',
        (tester) async {
      var completeCalls = 0;
      await pumpRow(
        tester,
        h: habit('temp_a', skipped: [todayStr]),
        onComplete: () => completeCalls++,
      );

      // Status button shows Skipped; no Skip action available anymore.
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Skipped'));
      await tester.pumpAndSettle();

      // The reported bug: this must NOT call onComplete.
      expect(completeCalls, 0);
    });

    testWidgets('tapping Done still triggers the undo path', (tester) async {
      var completeCalls = 0;
      await pumpRow(
        tester,
        h: habit('temp_a', completed: [todayStr]),
        onComplete: () => completeCalls++,
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Skip'), findsNothing); // can't skip a done habit

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(completeCalls, 1); // existing undo behavior preserved
    });
  });
}
