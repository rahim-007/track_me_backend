import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';
import 'package:track_me/features/cashflow/presentation/widgets/history_list.dart';
import 'package:track_me/features/cashflow/providers/cashflow_provider.dart';

class MockCashFlowNotifier extends StateNotifier<CashFlowState>
    implements CashFlowNotifier {
  TransactionModel? updatedTxn;

  MockCashFlowNotifier(super.state);

  @override
  Future<void> updateTransaction(TransactionModel txn) async {
    updatedTxn = txn;
    state = state.copyWith(
      transactions: state.transactions.map((t) => t.id == txn.id ? txn : t).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleTxn = TransactionModel(
    id: 'txn_edit_99',
    kind: TxnKind.income,
    category: 'E',
    amount: 5000,
    note: 'Monthly salary',
    date: '2026-09-01',
    account: CashFlowAccount.bank,
  );

  testWidgets('renders edit button and tapping edit icon opens pre-filled AddEntrySheet', (tester) async {
    final notifier = MockCashFlowNotifier(const CashFlowState(
      transactions: [sampleTxn],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashFlowProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryList(readOnly: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify transaction and edit icon are visible
    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Tap edit button
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Verify Edit Transaction sheet opened with pre-filled values
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget); // Amount text field prefilled
    expect(find.text('Monthly salary'), findsNWidgets(2)); // in list tile & in note field
  });

  testWidgets('tapping the transaction card opens the pre-filled Edit sheet and saving updates state', (tester) async {
    final notifier = MockCashFlowNotifier(const CashFlowState(
      transactions: [sampleTxn],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashFlowProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryList(readOnly: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the transaction card row
    await tester.tap(find.text('Monthly salary'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsOneWidget);

    // Change the amount to 7500
    final amountFinder = find.widgetWithText(TextField, '5000');
    expect(amountFinder, findsOneWidget);
    await tester.enterText(amountFinder, '7500');

    // Change the note
    final noteFinder = find.widgetWithText(TextField, 'Monthly salary');
    expect(noteFinder, findsOneWidget);
    await tester.enterText(noteFinder, 'Bonus included salary');

    // Scroll Save Changes button into view and tap
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Verify updateTransaction was called with the same ID (no duplicate created!)
    expect(notifier.updatedTxn, isNotNull);
    expect(notifier.updatedTxn!.id, equals('txn_edit_99'));
    expect(notifier.updatedTxn!.amount, equals(7500));
    expect(notifier.updatedTxn!.note, equals('Bonus included salary'));

    // Verify updated transaction displays in the list and only one transaction exists
    expect(find.text('Bonus included salary'), findsOneWidget);
    expect(notifier.state.transactions.length, equals(1));
  });

  testWidgets('in read-only mode, edit and delete buttons are not shown and tap does not open sheet', (tester) async {
    final notifier = MockCashFlowNotifier(const CashFlowState(
      transactions: [sampleTxn],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashFlowProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HistoryList(readOnly: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly salary'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // Tapping the card should do nothing
    await tester.tap(find.text('Monthly salary'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Transaction'), findsNothing);
  });
}
