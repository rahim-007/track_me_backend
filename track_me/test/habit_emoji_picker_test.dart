import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/core/theme/app_colors.dart';
import 'package:track_me/features/habits/data/models/habit_model.dart';
import 'package:track_me/features/habits/presentation/widgets/add_habit_dialog.dart';
import 'package:track_me/features/habits/presentation/widgets/habit_emoji_picker_sheet.dart';
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
  Future<_FakeHabitsNotifier> pumpApp(
    WidgetTester tester, {
    Size? size,
  }) async {
    // Tall surface so the whole dialog (including the Save button) is visible
    // without scrolling; widget tests use a wide monospace font.
    await tester.binding.setSurfaceSize(size ?? const Size(800, 1200));
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

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('habit_emoji_selector')));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'opens the full picker, selects an emoji, and saves it with the habit',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);

    // Default emoji is shown in the selector.
    expect(find.text('💪'), findsOneWidget);
    expect(find.text('😀'), findsNothing);

    // Tap the selector to open the full picker.
    await openPicker(tester);
    expect(find.text('Choose an Emoji'), findsOneWidget);
    // Smileys category is selected by default and shows the standard set.
    expect(find.text('😀'), findsOneWidget);

    // Pick an emoji — the sheet closes and the form shows the selection.
    await tester.tap(find.text('😀'));
    await tester.pumpAndSettle();
    expect(find.text('Choose an Emoji'), findsNothing);
    expect(find.text('😀'), findsOneWidget);

    // Fill in the name and save (the dialog scrolls, so reveal the button first).
    await tester.enterText(find.byType(TextFormField).first, 'Morning Run');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();
    // Let the success snackbar timer finish so no timers are pending.
    await tester.pump(const Duration(seconds: 5));

    expect(notifier.added, hasLength(1));
    expect(notifier.added.single.name, 'Morning Run');
    expect(notifier.added.single.emoji, '😀');
  });

  testWidgets('search filters the emoji set and the user can change the emoji',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);
    await openPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('emoji_search_field')),
      'fire',
    );
    await tester.pumpAndSettle();

    // Only matching emojis remain; category chips are hidden while searching.
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('Smileys'), findsNothing);

    await tester.tap(find.text('🔥'));
    await tester.pumpAndSettle();
    expect(find.text('🔥'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Run');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(notifier.added.single.emoji, '🔥');
  });

  testWidgets('previously used preset emojis are still selectable',
      (tester) async {
    final notifier = await pumpApp(tester);
    await openDialog(tester);
    await openPicker(tester);

    // '💧' was the first preset emoji in the old hardcoded list.
    await tester.enterText(
      find.byKey(const ValueKey('emoji_search_field')),
      'droplet',
    );
    await tester.pumpAndSettle();
    expect(find.text('💧'), findsOneWidget);

    await tester.tap(find.text('💧'));
    await tester.pumpAndSettle();
    expect(find.text('💧'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Hydrate');
    await tester.ensureVisible(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Habit'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(notifier.added.single.emoji, '💧');
  });

  testWidgets('picker renders without overflow across screen sizes and themes',
      (tester) async {
    const sizes = [Size(320, 480), Size(360, 640), Size(412, 915)];

    for (final dark in [false, true]) {
      AppColors.isDarkMode = dark;
      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Dispose the previous tree so its open bottom sheet route is gone.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => HabitEmojiPickerSheet.show(context),
                    child: const Text('Open picker'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open picker'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'picker overflowed at $size dark=$dark');

        // Type into the search field (keyboard open path).
        await tester.enterText(
          find.byKey(const ValueKey('emoji_search_field')),
          'star',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'search overflowed at $size dark=$dark');
      }
    }

    AppColors.isDarkMode = false;
  });
}
