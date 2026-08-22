import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

/// Fake notifier that records updates without touching network/storage or the
/// notification scheduler.
class _FakeHabitsNotifier extends HabitsNotifier {
  _FakeHabitsNotifier();

  final List<HabitModel> updated = [];

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    updated.add(habit);
    state = AsyncValue<List<HabitModel>>.data([...updated]);
  }
}

HabitModel sampleHabit({String category = 'Health'}) => HabitModel(
      id: 'habit-1',
      name: 'Morning Run',
      category: category,
      emoji: '🏃',
      color: '#7C3AED',
      repeatDays: [true, true, true, true, true, false, false],
      reminderTime: '07:30',
      notes: 'Park loop',
      createdAt: DateTime(2026, 1, 1),
      completedDates: ['2026-01-01'],
      skippedDates: [],
    );

Future<_FakeHabitsNotifier> pumpApp(
  WidgetTester tester, {
  HabitModel? initialHabit,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final notifier = _FakeHabitsNotifier();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        habitsProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AddHabitDialog(initialHabit: initialHabit),
                ),
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open dialog'));
  await tester.pumpAndSettle();
}

Future<void> saveDialog(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save Changes'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save Changes'));
  await tester.pumpAndSettle();
  // Let the success snackbar timer finish so no timers are pending.
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('edit mode pre-fills the form and shows edit labels',
      (tester) async {
    await pumpApp(tester, initialHabit: sampleHabit());
    await openDialog(tester);

    expect(find.text('Edit Habit'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('New Habit'), findsNothing);
    expect(find.text('Save Habit'), findsNothing);

    // Name + notes pre-filled.
    expect(find.widgetWithText(TextFormField, 'Morning Run'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Park loop'), findsOneWidget);

    // Reminder time pre-filled (default en_US localization).
    expect(find.text('7:30 AM'), findsOneWidget);
  });

  testWidgets('edit mode keeps completion/skip history on save',
      (tester) async {
    final notifier = await pumpApp(tester, initialHabit: sampleHabit());
    await openDialog(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Morning Run'),
      'Morning Jog',
    );
    await saveDialog(tester);

    expect(notifier.updated, hasLength(1));
    final saved = notifier.updated.single;
    expect(saved.name, 'Morning Jog');
    expect(saved.id, 'habit-1');
    expect(saved.createdAt, DateTime(2026, 1, 1));
    expect(saved.completedDates, ['2026-01-01']);
    expect(saved.reminderTime, '07:30');
  });

  testWidgets('clearing the reminder time saves a null reminderTime',
      (tester) async {
    final notifier = await pumpApp(tester, initialHabit: sampleHabit());
    await openDialog(tester);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.text('7:30 AM'), findsNothing);

    await saveDialog(tester);
    expect(notifier.updated.single.reminderTime, isNull);
  });

  testWidgets('custom categories pre-fill the Others field', (tester) async {
    final notifier = await pumpApp(
      tester,
      initialHabit: sampleHabit(category: 'Learning'),
    );
    await openDialog(tester);

    expect(find.text('Custom Category'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Learning'), findsOneWidget);

    await saveDialog(tester);
    expect(notifier.updated.single.category, 'Learning');
  });

  testWidgets('preset categories map onto the dropdown without Others field',
      (tester) async {
    await pumpApp(
      tester,
      initialHabit: sampleHabit(category: 'Wealth'),
    );
    await openDialog(tester);

    expect(find.text('Custom Category'), findsNothing);
  });
}
