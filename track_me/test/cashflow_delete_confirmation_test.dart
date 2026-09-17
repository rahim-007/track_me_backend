import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';
import 'package:track_me/features/cashflow/presentation/widgets/history_list.dart';
import 'package:track_me/features/cashflow/providers/cashflow_provider.dart';

class MockCashFlowNotifier extends StateNotifier<CashFlowState>
    implements CashFlowNotifier {
  String? deletedId;

  MockCashFlowNotifier(super.state);

  @override
  Future<void> deleteTransaction(String id) async {
    deletedId = id;
    state = state.copyWith(
      transactions: state.transactions.where((t) => t.id != id).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleTxn = TransactionModel(
    id: 'txn_123',
    kind: TxnKind.outflow,
    category: 'G',
    amount: 450,
    note: 'Dinner at cafe',
    date: '2026-09-08',
    account: CashFlowAccount.bank,
  );

  testWidgets('clicking delete button shows confirmation dialog and does not delete on Cancel', (tester) async {
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

    // Verify transaction is rendered
    expect(find.text('Dinner at cafe'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Verify confirmation dialog is visible
    expect(find.text('Delete Transaction'), findsOneWidget);
    expect(find.textContaining('Are you sure you want to delete this transaction'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed, transaction NOT deleted
    expect(find.text('Delete Transaction'), findsNothing);
    expect(find.text('Dinner at cafe'), findsOneWidget);
    expect(notifier.deletedId, isNull);
  });

  testWidgets('clicking delete and confirming in dialog deletes the transaction', (tester) async {
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

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Tap Delete in dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify delete was called and transaction is gone from list
    expect(notifier.deletedId, equals('txn_123'));
    expect(find.text('Dinner at cafe'), findsNothing);
    expect(find.text('No entries in this period yet.'), findsOneWidget);
  });
}
