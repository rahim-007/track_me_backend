import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';
import 'package:track_me/features/cashflow/presentation/widgets/cashflow_hero_card.dart';

void main() {
  const positivePeriod = CashFlowPeriodModel(
    id: 'p1',
    month: 8,
    year: 2026,
    openingBank: 20000,
    openingCash: 5000,
    openingCreditCard: 0,
    openingDebt: 0,
    totalIncome: 65000,
    totalOutflow: 19800,
    netCashFlow: 45200,
    closingBank: 52000,
    closingCash: 13200,
    closingCreditCard: 0,
  );

  const deficitPeriod = CashFlowPeriodModel(
    id: 'p2',
    month: 8,
    year: 2026,
    openingBank: 10000,
    openingCash: 2000,
    openingCreditCard: 0,
    openingDebt: 0,
    totalIncome: 15000,
    totalOutflow: 27500,
    netCashFlow: -12500,
    closingBank: 0,
    closingCash: 0,
    closingCreditCard: 500,
  );

  testWidgets('CashFlowHeroCard renders positive net cash flow and account metrics in full mode', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashFlowHeroCard(
            period: positivePeriod,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Headers & Badges
    expect(find.text('NET CASH FLOW'), findsOneWidget);
    expect(find.text('Positive'), findsOneWidget);
    expect(find.text('+₹45,200'), findsOneWidget);

    // 2. Income / Outflow
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('+₹65,000'), findsOneWidget);
    expect(find.text('Outflow'), findsOneWidget);
    expect(find.text('-₹19,800'), findsOneWidget);

    // 3. Sub-Accounts
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('₹52,000'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('₹13,200'), findsOneWidget);
    expect(find.text('Credit Card'), findsOneWidget);

    // 4. Tap test
    await tester.tap(find.byType(CashFlowHeroCard));
    expect(tapped, isTrue);
  });

  testWidgets('CashFlowHeroCard renders deficit badge when net is negative', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CashFlowHeroCard(
            period: deficitPeriod,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NET CASH FLOW'), findsOneWidget);
    expect(find.text('Deficit'), findsOneWidget);
    expect(find.text('₹-12,500'), findsOneWidget);
  });

  testWidgets('CashFlowHeroCard renders compact mode cleanly with all key metrics', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashFlowHeroCard(
            period: positivePeriod,
            isCompact: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NET CASH FLOW'), findsOneWidget);
    expect(find.text('Positive'), findsOneWidget);
    expect(find.text('+₹45,200'), findsOneWidget);
    expect(find.text('+₹65,000'), findsOneWidget);
    expect(find.text('-₹19,800'), findsOneWidget);
    expect(find.text('Bank: '), findsOneWidget);
    expect(find.text('₹52,000'), findsOneWidget);
    expect(find.text('Cash: '), findsOneWidget);
    expect(find.text('₹13,200'), findsOneWidget);
    expect(find.text('Card: '), findsOneWidget);
    expect(find.text('₹0'), findsOneWidget);

    // Tap test in compact mode
    await tester.tap(find.byType(CashFlowHeroCard));
    expect(tapped, isTrue);
  });
}
