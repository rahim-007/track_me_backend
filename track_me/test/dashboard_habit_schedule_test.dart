import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';

HabitModel habit(String id, List<bool> repeatDays) => HabitModel(
      id: id,
      name: 'Habit $id',
      category: 'Health',
      emoji: '💪',
      color: '#7C3AED',
      repeatDays: repeatDays,
      reminderTime: null,
      notes: null,
      createdAt: DateTime(2026, 1, 1),
      completedDates: [],
      skippedDates: [],
    );

void main() {
  // 2026-08-15 is a Saturday (weekday 6), 2026-08-17 is a Monday (weekday 1).
  final saturday = DateTime(2026, 8, 15);
  final monday = DateTime(2026, 8, 17);

  test('a Mon-Fri habit is not scheduled on Saturday', () {
    final gym = habit(
      'gym',
      [true, true, true, true, true, false, false], // Mon-Fri
    );
    final result = habitsScheduledOn([gym], saturday);
    expect(result, isEmpty);
  });

  test('a Mon-Fri habit is scheduled on Monday', () {
    final gym = habit(
      'gym',
      [true, true, true, true, true, false, false], // Mon-Fri
    );
    final result = habitsScheduledOn([gym], monday);
    expect(result.map((h) => h.id), ['gym']);
  });

  test('a habit with no repeat day selected is treated as daily', () {
    final noRepeat = habit('custom', List.filled(7, false));
    expect(
        habitsScheduledOn([noRepeat], saturday).map((h) => h.id), ['custom']);
    expect(habitsScheduledOn([noRepeat], monday).map((h) => h.id), ['custom']);
  });

  test('an all-day habit is scheduled every day', () {
    final daily = habit('daily', List.filled(7, true));
    expect(habitsScheduledOn([daily], saturday).map((h) => h.id), ['daily']);
    expect(habitsScheduledOn([daily], monday).map((h) => h.id), ['daily']);
  });

  test('a weekend-only habit is not scheduled on Monday', () {
    final weekend = habit(
      'weekend',
      [false, false, false, false, false, true, true], // Sat-Sun
    );
    expect(habitsScheduledOn([weekend], monday), isEmpty);
    expect(
        habitsScheduledOn([weekend], saturday).map((h) => h.id), ['weekend']);
  });
}
