import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/constants/app_constants.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:track_me/features/habits/providers/habits_provider.dart';

/// Fake notifier that records added habits without touching network/storage.
class _FakeHabitsNotifier extends HabitsNotifier {
  _FakeHabitsNotifier();

  final List<HabitModel> added = [];

  @override
  Future<void> loadHabits() async {
    state = const AsyncValue<List<HabitModel>>.data([]);
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    added.add(habit);
    state = AsyncValue<List<HabitModel>>.data([...added]);
  }
}

void main() {
  Future<_FakeHabitsNotifier> pumpApp(WidgetTester tester) async {
    // Tall surface so the whole dialog is visible without scrolling (widget
    // tests use a wide monospace font).
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
                    builder: (_) => const AddHabitDialog(),
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

  Future<void> selectCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> saveHabit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();
    // Let the success snackbar timer finish so no timers are pending.
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('category options are Health, Wealth, Peace, Others',
      (tester) async {
    expect(
        AppConstants.habitCategories, ['Health', 'Wealth', 'Peace', 'Others']);

    await pumpApp(tester);
    await openDialog(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    for (final label in ['Health', 'Wealth', 'Peace', 'Others']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Fitness'), findsNothing);
    expect(find.text('Learning'), findsNothing);
    expect(find.text('Productivity'), findsNothing);
  });

  testWidgets(
      'Others reveals a custom category field and saves the custom name',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);
    expect(find.text('Custom Category'), findsNothing);

    await selectCategory(tester, 'Others');
    expect(find.text('Custom Category'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Custom Category'),
      'Learning',
    );
    await tester.enterText(find.byType(TextFormField).first, 'Study Daily');
    await saveHabit(tester);

    expect(notifier.added, hasLength(1));
    expect(notifier.added.single.category, 'Learning');
  });

  testWidgets('fixed categories hide the custom field and save as-is',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);
    expect(find.text('Custom Category'), findsNothing);

    await selectCategory(tester, 'Wealth');
    expect(find.text('Custom Category'), findsNothing);

    await selectCategory(tester, 'Others');
    expect(find.text('Custom Category'), findsOneWidget);

    await selectCategory(tester, 'Health');
    expect(find.text('Custom Category'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'Morning Walk');
    await saveHabit(tester);

    expect(notifier.added.single.category, 'Health');
  });

  testWidgets('Others requires a custom category name before saving',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);

    await selectCategory(tester, 'Others');
    await tester.enterText(find.byType(TextFormField).first, 'Study');
    await saveHabit(tester);

    expect(find.text('Enter a category name'), findsOneWidget);
    expect(notifier.added, isEmpty);
  });

  test('model preserves legacy categories and stores custom ones', () {
    HabitModel habit({String category = 'Health'}) => HabitModel(
          id: '1',
          name: 'H',
          category: category,
          emoji: '💪',
          color: '#7C3AED',
          repeatDays: List.filled(7, true),
          reminderTime: null,
          notes: null,
          createdAt: DateTime(2026, 1, 1),
          completedDates: [],
          skippedDates: [],
        );

    // Legacy categories pass through unchanged — never remapped to OTHER.
    expect(habit(category: 'Fitness').toJson()['category'], 'FITNESS');
    expect(
        habit(category: 'Productivity').toJson()['category'], 'PRODUCTIVITY');

    // New fixed categories.
    expect(habit(category: 'Wealth').toJson()['category'], 'WEALTH');
    expect(habit(category: 'Peace').toJson()['category'], 'PEACE');
    expect(habit(category: 'Health').toJson()['category'], 'HEALTH');

    // Custom names typed under "Others".
    expect(habit(category: 'Learning').toJson()['category'], 'LEARNING');
    expect(habit(category: 'Music').toJson()['category'], 'MUSIC');

    // Blank input falls back to OTHER.
    expect(habit(category: '   ').toJson()['category'], 'OTHER');
  });

  test('fromJson title-cases any stored category for display', () {
    Map<String, dynamic> json(String category) => {
          'id': '1',
          'name': 'H',
          'category': category,
          'createdAt': '2026-01-01T00:00:00.000',
        };

    expect(HabitModel.fromJson(json('FITNESS')).category, 'Fitness');
    expect(HabitModel.fromJson(json('WEALTH')).category, 'Wealth');
    expect(HabitModel.fromJson(json('PEACE')).category, 'Peace');
    expect(HabitModel.fromJson(json('MUSIC')).category, 'Music');
  });
}
