import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

// All dates: week of Mon 2026-08-10.
HabitModel makeHabit({
  String id = 'h1',
  List<bool>? repeatDays,
  List<String>? completedDates,
  List<String>? skippedDates,
}) {
  return HabitModel(
    id: id,
    name: 'Test habit',
    category: 'Health',
    repeatDays: repeatDays ?? List.filled(7, true),
    createdAt: DateTime(2026, 8, 1),
    completedDates: completedDates ?? [],
    skippedDates: skippedDates ?? [],
  );
}

void main() {
  // repeatDays index 0 = Monday … 6 = Sunday
  final monWedFri = [true, false, true, false, true, false, false];
  final monFri = [true, false, false, false, true, false, false];

  group('calculateHabitStreak (per-habit, schedule-aware)', () {
    test('Mon/Wed/Fri completed → 3 scheduled-day streak (Test 2)', () {
      final h = makeHabit(
        repeatDays: monWedFri,
        completedDates: ['2026-08-10', '2026-08-12', '2026-08-14'],
      );
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 14)), 3);
    });

    test('scheduled missing day breaks the streak (Test 3)', () {
      // Mon ✅, Wed ❌ missing, Fri ✅ → breaks at Wed.
      final h = makeHabit(
        repeatDays: monWedFri,
        completedDates: ['2026-08-10', '2026-08-14'],
      );
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 14)), 1);
    });

    test('scheduled skipped day breaks the streak (Test 4)', () {
      // Wed skipped → breaks.
      final h = makeHabit(
        repeatDays: monWedFri,
        completedDates: ['2026-08-10', '2026-08-14'],
        skippedDates: ['2026-08-12'],
      );
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 14)), 1);
    });

    test('unscheduled days never break the streak (Test 5)', () {
      // Mon ✅, Tue not scheduled, Wed ✅ → 2.
      final h = makeHabit(
        repeatDays: monWedFri,
        completedDates: ['2026-08-10', '2026-08-12'],
      );
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 12)), 2);
    });

    test('daily habit keeps streak alive on incomplete today (grace period)', () {
      // Mon ✅, Tue ✅, Wed (today, incomplete) → streak stays 2 from Mon+Tue.
      final h = makeHabit(completedDates: ['2026-08-10', '2026-08-11']);
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 12)), 2);
    });

    test('daily habit breaks on a missing past day', () {
      // Mon ✅, Tue ✅, Wed (missing past day), Thu (today, incomplete) → breaks on Wed (0).
      final h = makeHabit(completedDates: ['2026-08-10', '2026-08-11']);
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 13)), 0);
    });

    test('no repeat day selected is treated as daily', () {
      final h = makeHabit(
        repeatDays: List.filled(7, false),
        completedDates: ['2026-08-10', '2026-08-11'],
      );
      // On Thu Aug 13 (after missing Wed Aug 12), streak is 0.
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 13)), 0);
    });

    test('Mon/Fri with both completed → 2 scheduled-day streak', () {
      final h = makeHabit(
        repeatDays: monFri,
        completedDates: ['2026-08-10', '2026-08-14'],
      );
      expect(calculateHabitStreak(h, from: DateTime(2026, 8, 14)), 2);
    });
  });

  group('calculateCurrentStreak (overall)', () {
    test('skipped habit: 2/3 completed and the day does not count (Test 1)',
        () {
      final a =
          makeHabit(id: 'a', completedDates: ['2026-08-11', '2026-08-12']);
      final b =
          makeHabit(id: 'b', completedDates: ['2026-08-11', '2026-08-12']);
      final c = makeHabit(
        id: 'c',
        completedDates: ['2026-08-11'],
        skippedDates: ['2026-08-12'],
      );
      final habits = [a, b, c];

      // "Overall completed = 2/3"
      final completedToday =
          habits.where((h) => h.completedDates.contains('2026-08-12')).length;
      expect(completedToday, 2);
      expect(habits.length, 3);

      // The skipped day never adds to the streak; yesterday's all-done day
      // still counts (today keeps its grace period).
      expect(calculateCurrentStreak(habits, from: DateTime(2026, 8, 12)), 1);
      expect(calculateLongestStreak(habits, from: DateTime(2026, 8, 12)), 1);
    });

    test('a skipped habit on a past scheduled day breaks the streak', () {
      final a = makeHabit(
          id: 'a', completedDates: ['2026-08-10', '2026-08-11', '2026-08-12']);
      final b = makeHabit(
          id: 'b', completedDates: ['2026-08-10', '2026-08-11', '2026-08-12']);
      final c = makeHabit(
        id: 'c',
        completedDates: ['2026-08-10', '2026-08-11'],
        skippedDates: ['2026-08-12'],
      );
      // Aug 12 (past): C skipped → breaks. Aug 13 (today) incomplete → grace.
      expect(calculateCurrentStreak([a, b, c], from: DateTime(2026, 8, 13)), 0);
    });

    test('incomplete today keeps the streak alive (grace period)', () {
      final a = makeHabit(id: 'a', completedDates: ['2026-08-12']);
      final b = makeHabit(id: 'b', completedDates: ['2026-08-12']);
      expect(calculateCurrentStreak([a, b], from: DateTime(2026, 8, 13)), 1);
    });

    test('a missing habit on a past scheduled day breaks the streak', () {
      final a = makeHabit(id: 'a', completedDates: ['2026-08-11']);
      final b = makeHabit(id: 'b', completedDates: []);
      expect(calculateCurrentStreak([a, b], from: DateTime(2026, 8, 12)), 0);
    });

    test('days with nothing scheduled are neutral (ignored)', () {
      final h = makeHabit(
        id: 'h',
        repeatDays: monWedFri,
        completedDates: ['2026-08-12'], // Wednesday
      );
      // Thu Aug 13 (today) not scheduled → neutral, streak stays 1.
      expect(calculateCurrentStreak([h], from: DateTime(2026, 8, 13)), 1);
    });

    test('longest streak spans non-consecutive runs', () {
      final a = makeHabit(
        id: 'a',
        completedDates: [
          '2026-08-09',
          '2026-08-10',
          '2026-08-11',
          '2026-08-13',
          '2026-08-14'
        ],
      );
      final current = calculateCurrentStreak([a], from: DateTime(2026, 8, 14));
      final longest = calculateLongestStreak([a], from: DateTime(2026, 8, 14));
      // Aug 14 ✅, Aug 13 ✅, Aug 12 missing (past) → current = 2; longest run = 3.
      expect(current, 2);
      expect(longest, 3);
    });
  });

  group('data integrity', () {
    test('existing skipped records remain skipped after round-trip (Test 8)',
        () {
      final h = makeHabit(
        repeatDays: monWedFri,
        completedDates: ['2026-08-10'],
        skippedDates: ['2026-08-12'],
      );
      final restored = HabitModel.fromJson(h.toJson());
      expect(restored.skippedDates, ['2026-08-12']);
      expect(restored.completedDates, ['2026-08-10']);
      expect(restored.repeatDays, monWedFri);
    });
  });
}
