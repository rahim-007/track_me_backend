import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/goals/data/models/goal_model.dart';
import 'package:track_me/features/goals/presentation/screens/goals_screen.dart';
import 'package:track_me/features/goals/presentation/widgets/add_goal_dialog.dart';
import 'package:track_me/features/goals/providers/goals_provider.dart';

GoalModel makeGoal({
  String id = 'g1',
  String name = 'Run a Marathon',
  String category = 'Fitness',
  String priority = 'High',
  DateTime? targetDate,
  int durationDays = 365,
  double target = 0,
  String unit = 'kg',
  String? notes = 'Train 4 days a week',
}) {
  return GoalModel(
    id: id,
    name: name,
    category: category,
    targetDate: targetDate ?? DateTime(2026, 12, 31),
    priority: priority,
    status: 'in_progress',
    progress: 0.4,
    durationDays: durationDays,
    target: target,
    unit: unit,
    notes: notes,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _FakeGoalsNotifier extends GoalsNotifier {
  final List<GoalModel> created = [];
  final List<GoalModel> updated = [];

  @override
  Future<void> loadGoals() async {
    state = const AsyncValue.data([]);
  }

  void seed(List<GoalModel> items) {
    state = AsyncValue.data(items);
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    created.add(goal);
    final cur = state.valueOrNull ?? <GoalModel>[];
    state = AsyncValue.data([...cur, goal]);
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    updated.add(goal);
  }
}

Future<void> _pumpDialog(
  WidgetTester tester,
  _FakeGoalsNotifier notifier, {
  GoalModel? goal,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [goalsProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AddGoalDialog(goal: goal),
                ),
                child: const Text('Open Goal Form'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Goal Form'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Portrait phone surface so the full dialog fits without scrolling.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> usePhoneSurface(WidgetTester tester,
      [Size size = const Size(412, 915)]) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('edit mode pre-fills every field and shows Update Goal',
      (tester) async {
    await usePhoneSurface(tester);
    final notifier = _FakeGoalsNotifier();
    await _pumpDialog(tester, notifier,
        goal: makeGoal(target: 42, unit: 'kg'));

    expect(find.text('Edit Goal'), findsOneWidget); // dialog title
    expect(find.text('Update Goal'), findsOneWidget);

    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller!.text, 'Run a Marathon');

    // Target field is the second text field and is pre-filled.
    final targetField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(targetField.controller!.text, '42');

    final notesField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(2),
    );
    expect(notesField.controller!.text, 'Train 4 days a week');

    // Selected category, unit and duration are shown in the closed dropdowns.
    // (A closed dropdown renders its selected text twice — once hidden for
    // sizing — so we assert presence with findsWidgets.)
    expect(find.text('Fitness'), findsWidgets);
    expect(find.text('kg'), findsWidgets);
    expect(find.text('365 Days'), findsWidgets);

    expect(find.text('31/12/2026'), findsOneWidget); // target date
  });

  testWidgets('new-goal form defaults to 30 Days and offers 365 Days',
      (tester) async {
    await usePhoneSurface(tester);
    final notifier = _FakeGoalsNotifier();
    await _pumpDialog(tester, notifier);

    expect(find.text('New Goal'), findsOneWidget);
    expect(find.text('30 Days'), findsWidgets); // default duration

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('365 Days'), findsOneWidget); // menu item
    expect(find.text('30 Days'), findsWidgets);
  });

  testWidgets('saving an edit updates the goal and preserves server fields',
      (tester) async {
    await usePhoneSurface(tester);
    final notifier = _FakeGoalsNotifier();
    final original = makeGoal();
    await _pumpDialog(tester, notifier, goal: original);

    // Change the name.
    await tester.enterText(
      find.byType(TextFormField).first,
      'Run a 10K',
    );

    // Change the category to Health.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health').last);
    await tester.pumpAndSettle();

    // Change the priority to Medium.
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();

    // Change the duration to 90 Days.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90 Days').last);
    await tester.pumpAndSettle();

    // Change the notes.
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Recovery matters',
    );

    await tester.ensureVisible(find.text('Update Goal'));
    await tester.tap(find.text('Update Goal'));
    await tester.pumpAndSettle();

    expect(notifier.updated, hasLength(1));
    final saved = notifier.updated.single;
    expect(saved.id, 'g1');
    expect(saved.name, 'Run a 10K');
    expect(saved.category, 'Health');
    expect(saved.priority, 'Medium');
    expect(saved.durationDays, 90);
    expect(saved.notes, 'Recovery matters');
    // Switching to Health auto-suggests the L unit.
    expect(saved.unit, 'L');
    expect(saved.target, 0); // no target entered — stays unset
    // Server-managed fields are preserved by the edit form.
    expect(saved.progress, 0.4);
    expect(saved.status, 'in_progress');
    expect(saved.createdAt, original.createdAt);
  });

  testWidgets('Edit Goal action on the goal sheet opens the pre-filled form',
      (tester) async {
    // Wide surface: the Ahem test font renders the goal card's "Due …" row
    // wider than real fonts, which would overflow the default phone width.
    await usePhoneSurface(tester, const Size(560, 1000));
    final notifier = _FakeGoalsNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [goalsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );
    notifier.seed([makeGoal()]);
    await tester.pumpAndSettle();

    // Open the goal detail sheet.
    await tester.tap(find.text('Run a Marathon'));
    await tester.pumpAndSettle();
    expect(find.text('Save Progress'), findsOneWidget);

    // Tap Edit Goal → the form opens pre-filled.
    await tester.tap(find.text('Edit Goal'));
    await tester.pumpAndSettle();

    expect(find.text('Update Goal'), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(nameField.controller!.text, 'Run a Marathon');
  });

  testWidgets('selecting a duration auto-calculates the target date',
      (tester) async {
    await usePhoneSurface(tester);
    final notifier = _FakeGoalsNotifier();
    await _pumpDialog(tester, notifier); // new goal

    final today = GoalModel.dateOnly(DateTime.now());
    // New goal starts with target = today + 30 (the default duration).
    final expected30 = GoalModel.targetDateForDuration(today, 30);
    expect(
      find.text('${expected30.day}/${expected30.month}/${expected30.year}'),
      findsOneWidget,
    );

    // Switch to 180 Days → target date becomes today + 180.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('180 Days').last);
    await tester.pumpAndSettle();

    final expected180 = GoalModel.targetDateForDuration(today, 180);
    expect(
      find.text('${expected180.day}/${expected180.month}/${expected180.year}'),
      findsOneWidget,
    );
  });

  testWidgets('picking a target date sets the duration to match',
      (tester) async {
    await usePhoneSurface(tester);
    final notifier = _FakeGoalsNotifier();
    await _pumpDialog(tester, notifier);

    final today = GoalModel.dateOnly(DateTime.now());
    // The picker opens on the month of the current target (today + 30). Pick
    // the last day of that visible month — always a valid, future-enabled cell.
    final initial = GoalModel.targetDateForDuration(today, 30);
    final picked = DateTime(initial.year, initial.month + 1, 0);
    final expectedDuration =
        GoalModel.durationForTargetDate(today, picked);

    // Open the picker via the target-date field.
    await tester.tap(find.text('${initial.day}/${initial.month}/${initial.year}'));
    await tester.pumpAndSettle();

    // Select the last day of the visible month and confirm.
    await tester.tap(find.text('${picked.day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Target date updated…
    expect(
      find.text('${picked.day}/${picked.month}/${picked.year}'),
      findsOneWidget,
    );
    // …and the duration reflects the day difference (custom value included).
    expect(find.text('$expectedDuration Days'), findsWidgets);
  });

  group('type-aware target input', () {
    testWidgets('measurement units accept decimal targets', (tester) async {
      await usePhoneSurface(tester);
      final notifier = _FakeGoalsNotifier();
      await _pumpDialog(tester, notifier);

      // Pick the Fitness category → unit auto-suggests 'kg'.
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fitness').last);
      await tester.pumpAndSettle();
      expect(find.text('kg'), findsWidgets);

      final targetField = find.byType(TextFormField).at(1);
      // Decimal-capable keyboard for measurement units.
      final tf = tester.widget<TextField>(
        find.descendant(of: targetField, matching: find.byType(TextField)),
      );
      expect(
        tf.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );

      await tester.enterText(targetField, '0.5');
      final typed = tester.widget<TextFormField>(targetField);
      expect(typed.controller!.text, '0.5');
    });

    testWidgets('count units reject decimal input and use integer keyboard',
        (tester) async {
      await usePhoneSurface(tester);
      final notifier = _FakeGoalsNotifier();
      await _pumpDialog(tester, notifier);

      // Pick 'books' as the unit.
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('books').last);
      await tester.pumpAndSettle();

      final targetField = find.byType(TextFormField).at(1);
      final tf = tester.widget<TextField>(
        find.descendant(of: targetField, matching: find.byType(TextField)),
      );
      expect(tf.keyboardType, TextInputType.number);

      // '2.5' is blocked by the digits-only formatter.
      await tester.enterText(targetField, '2.5');
      final after = tester.widget<TextFormField>(targetField);
      expect(after.controller!.text, isEmpty);

      // Whole numbers are accepted.
      await tester.enterText(targetField, '10');
      final ok = tester.widget<TextFormField>(targetField);
      expect(ok.controller!.text, '10');
    });

    testWidgets('saving a new goal stores target and unit', (tester) async {
      await usePhoneSurface(tester);
      final notifier = _FakeGoalsNotifier();
      await _pumpDialog(tester, notifier);

      await tester.enterText(find.byType(TextFormField).first, 'Lose Weight');

      // Fitness → kg, then a fractional target.
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fitness').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '5');

      await tester.ensureVisible(find.text('Save Goal'));
      await tester.tap(find.text('Save Goal'));
      await tester.pumpAndSettle();

      expect(notifier.created, hasLength(1));
      final saved = notifier.created.single;
      expect(saved.name, 'Lose Weight');
      expect(saved.target, 5.0);
      expect(saved.unit, 'kg');
    });

    testWidgets('editing prefills target and unit from the goal',
        (tester) async {
      await usePhoneSurface(tester);
      final notifier = _FakeGoalsNotifier();
      await _pumpDialog(tester, notifier,
          goal: makeGoal(target: 2.5, unit: 'km'));

      final targetField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(targetField.controller!.text, '2.5');
      expect(find.text('km'), findsWidgets);
    });
  });
}
