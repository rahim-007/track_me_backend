import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/screens/habits_screen.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

class _MockHabitsNotifier extends HabitsNotifier {
  _MockHabitsNotifier(List<HabitModel> initial) : super() {
    state = AsyncValue.data(initial);
  }

  @override
  Future<void> loadHabits() async {}

  @override
  Future<void> toggleCompletion(HabitModel habit, DateTime date, {bool debounce = false}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final current = state.valueOrNull ?? [];
    final updated = current.map((h) {
      if (h.id != habit.id) return h;
      final dates = List<String>.from(h.completedDates);
      if (dates.contains(dateStr)) {
        dates.remove(dateStr);
      } else {
        dates.add(dateStr);
      }
      return h.copyWith(completedDates: dates);
    }).toList();
    state = AsyncValue.data(updated);
  }
}

void main() {
  testWidgets('Today habit can be completed and toggled', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testHabit = HabitModel(
      id: 'habit_1',
      name: 'Read 20 mins',
      category: 'Learning',
      repeatDays: List.filled(7, true),
      completedDates: [],
      skippedDates: const [],
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier([testHabit])),
        ],
        child: const MaterialApp(
          home: HabitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Read 20 mins'), findsOneWidget);
    expect(find.text('Mark Done'), findsOneWidget);

    // Tap Mark Done on Today
    await tester.tap(find.text('Mark Done'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('Yesterday habit is within grace period and can be marked done', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDayNum = yesterday.day.toString();

    final testHabit = HabitModel(
      id: 'habit_2',
      name: 'Workout',
      category: 'Fitness',
      repeatDays: List.filled(7, true),
      completedDates: [],
      skippedDates: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier([testHabit])),
        ],
        child: const MaterialApp(
          home: HabitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap yesterday in the week strip if it is in the same week view
    final yesterdayFinder = find.text(yesterdayDayNum);
    if (yesterdayFinder.evaluate().isNotEmpty) {
      await tester.tap(yesterdayFinder.first);
      await tester.pumpAndSettle();

      expect(find.text("Yesterday's Habits"), findsOneWidget);
      expect(find.text('Mark Done'), findsOneWidget);

      await tester.tap(find.text('Mark Done'));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsWidgets);
    }
  });

  testWidgets('Records older than yesterday cannot be modified and show toast', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dateStr = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

    final testHabit = HabitModel(
      id: 'habit_3',
      name: 'Meditate',
      category: 'Mindfulness',
      repeatDays: List.filled(7, true),
      completedDates: [dateStr], // Already marked completed on sevenDaysAgo
      skippedDates: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitsProvider.overrideWith((ref) => _MockHabitsNotifier([testHabit])),
        ],
        child: const MaterialApp(
          home: HabitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate back to previous week using '<' (which selects exactly sevenDaysAgo)
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Habits 🔒'), findsOneWidget);

    // Because sevenDaysAgo is marked done in completedDates, it renders check_rounded in locked completed state
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Tapping it must NOT unmark it, and must show the integrity toast
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Records older than 24 hours are locked'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
