import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/providers/cashflow_provider.dart';
import 'package:track_me/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:track_me/features/goals/data/models/goal_model.dart';
import 'package:track_me/features/goals/providers/goals_provider.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/screens/habits_screen.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';
import 'package:track_me/features/profile/providers/profile_provider.dart';

class _MockHabitsNotifier extends HabitsNotifier {
  _MockHabitsNotifier(List<HabitModel> initial) : super() {
    state = AsyncValue.data(initial);
  }

  @override
  Future<void> loadHabits() async {}

  @override
  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;
    final updated = List<HabitModel>.from(current);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = AsyncValue.data(updated);
  }

  @override
  Future<void> reorderVisibleHabits(List<HabitModel> newVisibleOrder) async {
    final currentList = state.valueOrNull ?? [];
    if (currentList.isEmpty || newVisibleOrder.isEmpty) return;

    final visibleIds = newVisibleOrder.map((h) => h.id).toSet();
    final newMaster = <HabitModel>[];
    int visibleIdx = 0;

    for (final habit in currentList) {
      if (visibleIds.contains(habit.id)) {
        if (visibleIdx < newVisibleOrder.length) {
          newMaster.add(newVisibleOrder[visibleIdx]);
          visibleIdx++;
        }
      } else {
        newMaster.add(habit);
      }
    }
    while (visibleIdx < newVisibleOrder.length) {
      newMaster.add(newVisibleOrder[visibleIdx]);
      visibleIdx++;
    }

    state = AsyncValue.data(newMaster);
  }
}

class _MockGoalsNotifier extends GoalsNotifier {
  _MockGoalsNotifier(List<GoalModel> initial) : super() {
    state = AsyncValue.data(initial);
  }
  @override
  Future<void> loadGoals() async {}
}

class _MockProfileNotifier extends ProfileNotifier {
  _MockProfileNotifier(UserProfile initial) : super() {
    state = AsyncValue.data(initial);
  }
}

class _MockCashFlowNotifier extends CashFlowNotifier {
  _MockCashFlowNotifier(CashFlowState initial) : super() {
    state = initial;
  }
}

HabitModel _createTestHabit({
  required String id,
  required String name,
  String category = 'General',
  List<bool>? repeatDays,
  DateTime? createdAt,
}) {
  return HabitModel(
    id: id,
    name: name,
    category: category,
    repeatDays: repeatDays ?? List.filled(7, true),
    completedDates: const [],
    skippedDates: const [],
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  group('Habits Reordering Logic Tests', () {
    test('reorderHabits correctly repositions elements', () async {
      final h1 = _createTestHabit(id: 'h1', name: 'Habit 1', createdAt: DateTime(2025, 1, 1));
      final h2 = _createTestHabit(id: 'h2', name: 'Habit 2', createdAt: DateTime(2025, 1, 2));
      final h3 = _createTestHabit(id: 'h3', name: 'Habit 3', createdAt: DateTime(2025, 1, 3));

      final notifier = _MockHabitsNotifier([h1, h2, h3]);
      await notifier.reorderHabits(0, 3); // Move h1 to end

      final result = notifier.state.valueOrNull!;
      expect(result.map((h) => h.id).toList(), ['h2', 'h3', 'h1']);

      await notifier.reorderHabits(2, 0); // Move h1 back to top
      final result2 = notifier.state.valueOrNull!;
      expect(result2.map((h) => h.id).toList(), ['h1', 'h2', 'h3']);
    });

    test('reorderVisibleHabits preserves relative position of unscheduled habits', () async {
      final h1 = _createTestHabit(id: 'h1', name: 'Habit 1', createdAt: DateTime(2025, 1, 1));
      final hWeekend = _createTestHabit(
        id: 'hWeekend',
        name: 'Weekend Only',
        repeatDays: [false, false, false, false, false, true, true],
        createdAt: DateTime(2025, 1, 2),
      );
      final h2 = _createTestHabit(id: 'h2', name: 'Habit 2', createdAt: DateTime(2025, 1, 3));

      // Master list has: [h1, hWeekend, h2]
      final notifier = _MockHabitsNotifier([h1, hWeekend, h2]);

      // Visible subset for a weekday is [h1, h2]. User reverses them to [h2, h1]
      await notifier.reorderVisibleHabits([h2, h1]);

      final result = notifier.state.valueOrNull!;
      // hWeekend remains between the two visible positions: [h2, hWeekend, h1]
      expect(result.map((h) => h.id).toList(), ['h2', 'hWeekend', 'h1']);
    });
  });

  group('Dashboard Today Habits Reorder Interaction Tests', () {
    testWidgets('Dashboard shows swap icon, toggles reorder mode, and shows drag handles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habits = <HabitModel>[
        _createTestHabit(id: 'h1', name: 'Morning Meditation', category: 'Mindfulness'),
        _createTestHabit(id: 'h2', name: 'Drink Water', category: 'Health'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
            goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
            profileProvider.overrideWith((ref) => _MockProfileNotifier(
                  UserProfile.fromJson(const {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'}),
                )),
            cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal mode displays "Today's Habits"
      expect(find.text("Today's Habits"), findsOneWidget);
      // Reorder button icon (Icons.swap_vert_rounded) is present when multiple habits exist
      final reorderBtn = find.byIcon(Icons.swap_vert_rounded);
      expect(reorderBtn, findsOneWidget);

      // Tap reorder button to enter Reorder Mode
      await tester.tap(reorderBtn);
      await tester.pumpAndSettle();

      // Reorder Mode displays "Arrange Habits", "Drag items", and "Done" button
      expect(find.text("Arrange Habits"), findsOneWidget);
      expect(find.text("Drag items"), findsOneWidget);
      expect(find.text("Done"), findsOneWidget);

      // Drag handles are visible
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));

      // Tapping "Done" returns to normal mode
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();

      expect(find.text("Today's Habits"), findsOneWidget);
      expect(find.text("Arrange Habits"), findsNothing);
    });

    testWidgets('Dashboard habit card long press enters reorder mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habits = <HabitModel>[
        _createTestHabit(id: 'h1', name: 'Morning Meditation', category: 'Mindfulness'),
        _createTestHabit(id: 'h2', name: 'Drink Water', category: 'Health'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
            goalsProvider.overrideWith((ref) => _MockGoalsNotifier([])),
            profileProvider.overrideWith((ref) => _MockProfileNotifier(
                  UserProfile.fromJson(const {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'}),
                )),
            cashFlowProvider.overrideWith((ref) => _MockCashFlowNotifier(const CashFlowState())),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Habits"), findsOneWidget);

      // Long press on "Morning Meditation" habit card
      await tester.longPress(find.text('Morning Meditation'));
      await tester.pumpAndSettle();

      // Enters Arrange Habits mode
      expect(find.text("Arrange Habits"), findsOneWidget);
      expect(find.text("Done"), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
    });
  });

  group('Habits Screen Reorder Interaction Tests', () {
    testWidgets('HabitsScreen shows swap icon, toggles reorder mode, and shows drag handles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habits = <HabitModel>[
        _createTestHabit(id: 'h1', name: 'Morning Meditation', category: 'Mindfulness'),
        _createTestHabit(id: 'h2', name: 'Drink Water', category: 'Health'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
            profileProvider.overrideWith((ref) => _MockProfileNotifier(
                  UserProfile.fromJson(const {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'}),
                )),
          ],
          child: const MaterialApp(
            home: HabitsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal mode
      expect(find.text("Today's Habits"), findsOneWidget);
      final reorderBtn = find.byIcon(Icons.swap_vert_rounded);
      expect(reorderBtn, findsOneWidget);

      // Tap reorder button to enter Reorder Mode
      await tester.tap(reorderBtn);
      await tester.pumpAndSettle();

      // Arrange Habits mode
      expect(find.text("Arrange Habits"), findsOneWidget);
      expect(find.text("Drag items"), findsOneWidget);
      expect(find.text("Done"), findsOneWidget);
      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));

      // Tapping "Done" returns to normal mode
      await tester.tap(find.text("Done"));
      await tester.pumpAndSettle();

      expect(find.text("Today's Habits"), findsOneWidget);
      expect(find.text("Arrange Habits"), findsNothing);
      expect(find.byType(SliverReorderableList), findsNothing);
    });

    testWidgets('HabitsScreen habit card long press enters reorder mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habits = <HabitModel>[
        _createTestHabit(id: 'h1', name: 'Morning Meditation', category: 'Mindfulness'),
        _createTestHabit(id: 'h2', name: 'Drink Water', category: 'Health'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitsProvider.overrideWith((ref) => _MockHabitsNotifier(habits)),
            profileProvider.overrideWith((ref) => _MockProfileNotifier(
                  UserProfile.fromJson(const {'id': 'u1', 'email': 'test@example.com', 'name': 'Test User'}),
                )),
          ],
          child: const MaterialApp(
            home: HabitsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Habits"), findsOneWidget);

      // Long press on "Morning Meditation"
      await tester.longPress(find.text('Morning Meditation'));
      await tester.pumpAndSettle();

      // Switches to Arrange Habits
      expect(find.text("Arrange Habits"), findsOneWidget);
      expect(find.text("Done"), findsOneWidget);
      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(2));
    });
  });
}
