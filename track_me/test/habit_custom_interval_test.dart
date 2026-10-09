import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:track_me/features/habits/presentation/widgets/interval_custom_picker_sheet.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

class _FakeHabitsNotifier extends HabitsNotifier {
  final List<HabitModel> created = [];
  final List<HabitModel> updated = [];

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    created.add(habit);
    state = AsyncValue<List<HabitModel>>.data([...created]);
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    updated.add(habit);
    state = AsyncValue<List<HabitModel>>.data([...updated]);
  }
}

HabitModel intervalHabit({int minutes = 60}) => HabitModel(
      id: 'interval-1',
      name: 'Drink Water',
      category: 'Health',
      emoji: '💧',
      color: '#06B6D4',
      repeatDays: List.filled(7, true),
      isInterval: true,
      intervalMinutes: minutes,
      windowStartTime: '08:00',
      windowEndTime: '22:00',
      targetValue: 4000,
      unit: 'ml',
      rollingInterval: true,
      createdAt: DateTime(2026, 1, 1),
      completedDates: [],
      skippedDates: [],
    );

Future<_FakeHabitsNotifier> pumpApp(
  WidgetTester tester, {
  HabitModel? initialHabit,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntervalCustomPickerSheet tests', () {
    testWidgets('renders CupertinoPickers, presets, and allows selecting custom interval',
        (tester) async {
      int? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await IntervalCustomPickerSheet.show(
                    context: context,
                    initialMinutes: 60,
                    windowStartTime: const TimeOfDay(hour: 8, minute: 0),
                    windowEndTime: const TimeOfDay(hour: 22, minute: 0),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check header, pickers, and presets
      expect(find.text('Customize Reminder Gap'), findsOneWidget);
      expect(find.byType(CupertinoPicker), findsNWidgets(2)); // Hours & Minutes wheels
      expect(find.text('Remind every 1 Hour'), findsOneWidget);

      // Tap preset chip '4h'
      await tester.tap(find.widgetWithText(ChoiceChip, '4h'));
      await tester.pumpAndSettle();

      expect(find.text('Remind every 4 Hours'), findsOneWidget);
      expect(find.textContaining('4 alarms per day'), findsOneWidget);

      // Confirm with 'Set Interval'
      await tester.tap(find.text('Set Interval'));
      await tester.pumpAndSettle();

      expect(selectedResult, 240);
    });

    testWidgets('cancel button dismisses without returning value',
        (tester) async {
      int? selectedResult = 999;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await IntervalCustomPickerSheet.show(
                    context: context,
                    initialMinutes: 120,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNull);
    });
  });

  group('AddHabitDialog 4 Hours & Custom Scroller integration tests', () {
    testWidgets('interval mode displays 4 Hours chip and Custom chip',
        (tester) async {
      await pumpApp(tester, initialHabit: intervalHabit(minutes: 60));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      // Verify all interval chips exist
      expect(find.widgetWithText(ChoiceChip, '30 Mins'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '1 Hour'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '2 Hours'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '3 Hours'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '4 Hours'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Custom'), findsOneWidget);
      expect(find.text('Customize'), findsOneWidget);
    });

    testWidgets('selecting 4 Hours chip updates interval and dynamic rolling gap subtitle',
        (tester) async {
      final notifier =
          await pumpApp(tester, initialHabit: intervalHabit(minutes: 60));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      // Tap 4 Hours chip
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '4 Hours'));
      await tester.tap(find.widgetWithText(ChoiceChip, '4 Hours'));
      await tester.pumpAndSettle();

      // Dynamic subtitle updates to 4h
      expect(
        find.text('Schedules next alarm 4h from actual intake time'),
        findsOneWidget,
      );

      // Save changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(notifier.updated, hasLength(1));
      expect(notifier.updated.single.intervalMinutes, 240);
    });

    testWidgets('habit with 240 minutes pre-selects 4 Hours chip on edit',
        (tester) async {
      await pumpApp(tester, initialHabit: intervalHabit(minutes: 240));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      final fourHoursChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '4 Hours'),
      );
      expect(fourHoursChip.selected, isTrue);
      expect(
        find.text('Schedules next alarm 4h from actual intake time'),
        findsOneWidget,
      );
    });

    testWidgets('habit with custom 300 minutes (5h) pre-selects Custom (5h) chip',
        (tester) async {
      await pumpApp(tester, initialHabit: intervalHabit(minutes: 300));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Custom (5h)'), findsOneWidget);
      final customChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Custom (5h)'),
      );
      expect(customChip.selected, isTrue);
      expect(
        find.text('Schedules next alarm 5h from actual intake time'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Customize opens scroller and selecting 360m updates to Custom (6h)',
        (tester) async {
      final notifier =
          await pumpApp(tester, initialHabit: intervalHabit(minutes: 60));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      // Tap Customize button
      await tester.ensureVisible(find.text('Customize'));
      await tester.tap(find.text('Customize'));
      await tester.pumpAndSettle();

      expect(find.text('Customize Reminder Gap'), findsOneWidget);

      // Select 6h preset in the sheet
      await tester.tap(find.widgetWithText(ChoiceChip, '6h'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Set Interval'));
      await tester.pumpAndSettle();

      // Now dialog shows Custom (6h) as selected
      expect(find.widgetWithText(ChoiceChip, 'Custom (6h)'), findsOneWidget);
      expect(
        find.text('Schedules next alarm 6h from actual intake time'),
        findsOneWidget,
      );

      // Save
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(notifier.updated.single.intervalMinutes, 360);
    });
  });
}
