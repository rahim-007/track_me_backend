import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:track_me/features/expenses/data/models/budget_model.dart';
import 'package:track_me/features/expenses/presentation/screens/expense_setup_wizard.dart';
import 'package:track_me/features/expenses/providers/expenses_provider.dart';

BudgetModel _budget({
  double income = 50000,
  double savings = 10000,
}) {
  return BudgetModel(
    month: 8,
    year: 2026,
    monthlyIncome: income,
    savingsTarget: savings,
    spendableBudget: income - savings,
    dailyGoal: 1333.33,
    daysInMonth: 31,
  );
}

/// Budget that is already loaded when the wizard opens (saved budget exists).
class _ReadyBudgetNotifier extends BudgetNotifier {
  _ReadyBudgetNotifier() {
    state = AsyncValue.data(_budget());
  }

  @override
  Future<void> loadCurrentBudget() async {}
}

/// No saved budget — used for the first-run / invalid-input cases.
class _NoBudgetNotifier extends BudgetNotifier {
  _NoBudgetNotifier() {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> loadCurrentBudget() async {}
}

/// Budget that resolves AFTER the user has started typing (network latency).
class _DelayedBudgetNotifier extends BudgetNotifier {
  _DelayedBudgetNotifier();

  @override
  Future<void> loadCurrentBudget() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    state = AsyncValue.data(_budget());
  }
}

void main() {
  Future<void> pumpWizard(
    WidgetTester tester,
    BudgetNotifier notifier,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [budgetProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: ExpenseSetupWizard()),
      ),
    );
    await tester.pump();
  }

  TextField fieldAt(WidgetTester tester, int index) =>
      tester.widget<TextField>(find.byType(TextField).at(index));

  testWidgets('Edit Budget: income → Continue → Savings Target',
      (tester) async {
    final notifier = _ReadyBudgetNotifier();
    await pumpWizard(tester, notifier);

    expect(find.text('Monthly Income'), findsOneWidget);

    // User enters a new income amount.
    await tester.enterText(find.byType(TextField).first, '60000');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Now on the Savings Target page…
    expect(find.text('How much do you want to save?'), findsOneWidget);
    // …and the entered income was preserved (shown in the live preview).
    expect(find.text('₹60,000'), findsOneWidget);
  });

  testWidgets('Savings Target → Continue moves to the month page',
      (tester) async {
    final notifier = _ReadyBudgetNotifier();
    await pumpWizard(tester, notifier);

    await tester.enterText(find.byType(TextField).first, '60000');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12000');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Select Month'), findsOneWidget);
    // Both values persist into the summary on the month page.
    expect(find.text('₹60,000'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
  });

  testWidgets('invalid income blocks Continue and keeps the income page',
      (tester) async {
    final notifier = _NoBudgetNotifier();
    await pumpWizard(tester, notifier);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Income'), findsOneWidget);
    expect(find.text('Please enter a valid income'), findsOneWidget);
  });

  testWidgets('budget pre-fill never overwrites income the user typed',
      (tester) async {
    final notifier = _DelayedBudgetNotifier();
    await pumpWizard(tester, notifier);

    // User types before the saved budget finishes loading.
    await tester.enterText(find.byType(TextField).first, '60000');
    await tester.pump();

    // Let the budget load land — it must NOT replace the typed value.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(fieldAt(tester, 0).controller!.text, '60000');
  });

  testWidgets('reopening Edit Budget pre-fills saved income and savings',
      (tester) async {
    final notifier = _ReadyBudgetNotifier();
    await pumpWizard(tester, notifier);
    await tester.pumpAndSettle();

    expect(fieldAt(tester, 0).controller!.text, '50000');
    // Savings is only pre-filled once we reach that page; switch to it.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(fieldAt(tester, 0).controller!.text, '10000');
  });

  testWidgets('Savings Target field is focused after Continue', (tester) async {
    final notifier = _ReadyBudgetNotifier();
    await pumpWizard(tester, notifier);

    await tester.enterText(find.byType(TextField).first, '60000');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(fieldAt(tester, 0).focusNode!.hasFocus, isTrue,
        reason: 'Saving Target should be focused/ready for input');
  });
}
