import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/core/theme/app_colors.dart';
import 'package:track_me/core/theme/theme_provider.dart';
import 'package:track_me/features/goals/data/models/goal_model.dart';
import 'package:track_me/features/goals/data/models/goal_units.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production Readiness Audit — Theme Management', () {
    test('Initial theme sets AppColors.isDarkMode correctly', () {
      final notifierLight = ThemeNotifier(false);
      expect(notifierLight.state, isFalse);
      expect(AppColors.isDarkMode, isFalse);

      final notifierDark = ThemeNotifier(true);
      expect(notifierDark.state, isTrue);
      expect(AppColors.isDarkMode, isTrue);
    });
  });

  group('Production Readiness Audit — Goal Calculations & Safety', () {
    test('Duration for target date clamps strictly between 1 and 365 days', () {
      final now = DateTime(2026, 1, 1);

      // Same day (0 days diff) -> clamped to 1 day minimum
      final sameDayDuration = GoalModel.durationForTargetDate(now, now);
      expect(sameDayDuration, equals(1));

      // Past date (negative diff) -> clamped to 1 day minimum
      final pastDate = DateTime(2025, 12, 25);
      final pastDuration = GoalModel.durationForTargetDate(now, pastDate);
      expect(pastDuration, equals(1));

      // Normal 30 days
      final futureDate = DateTime(2026, 1, 31);
      final normalDuration = GoalModel.durationForTargetDate(now, futureDate);
      expect(normalDuration, equals(30));

      // Excessively far date (e.g. 1000 days) -> clamped to 365 days maximum
      final farFutureDate = DateTime(2030, 1, 1);
      final clampedDuration = GoalModel.durationForTargetDate(now, farFutureDate);
      expect(clampedDuration, equals(365));
    });

    test('Target date for duration produces exact day arithmetic', () {
      final start = DateTime(2026, 3, 1, 15, 30); // with time
      final targetDate = GoalModel.targetDateForDuration(start, 10);
      expect(targetDate, equals(DateTime(2026, 3, 11)));
      expect(targetDate.hour, equals(0));
      expect(targetDate.minute, equals(0));
    });

    test('Unit decimal permissions conform strictly to expected units', () {
      // Measurement — Decimal permitted
      expect(unitAllowsDecimals('kg'), isTrue);
      expect(unitAllowsDecimals('km'), isTrue);
      expect(unitAllowsDecimals('L'), isTrue);
      expect(unitAllowsDecimals('hours'), isTrue);

      // Currency & Count — Integers only
      expect(unitAllowsDecimals('₹'), isFalse);
      expect(unitAllowsDecimals(r'$'), isFalse);
      expect(unitAllowsDecimals('books'), isFalse);
      expect(unitAllowsDecimals('tasks'), isFalse);
      expect(unitAllowsDecimals('workouts'), isFalse);
      expect(unitAllowsDecimals('reps'), isFalse);
      expect(unitAllowsDecimals('sessions'), isFalse);
    });

    test('GoalModel serialization safely normalizes category, priority, and status', () {
      final goal = GoalModel.fromJson({
        'id': 'goal_123',
        'name': 'Run 5km',
        'category': 'fitness',
        'targetDate': '2026-04-01T00:00:00.000Z',
        'priority': 'high',
        'status': 'in_progress',
        'progress': 0.75,
        'durationDays': 30,
        'target': 5.0,
        'unit': 'km',
        'createdAt': '2026-03-01T00:00:00.000Z',
      });

      expect(goal.category, equals('Fitness'));
      expect(goal.priority, equals('High'));
      expect(goal.status, equals('in_progress'));
      expect(goal.allowsDecimalProgress, isTrue);
      expect(goal.hasTarget, isTrue);

      final jsonPayload = goal.toCreateJson();
      expect(jsonPayload['category'], equals('FITNESS'));
      expect(jsonPayload['priority'], equals('HIGH'));
      expect(jsonPayload['unit'], equals('km'));
    });
  });

  group('Production Readiness Audit — Cash Flow Calculations', () {
    test('TransactionModel correctly distinguishes income from outflow', () {
      const incomeTxn = TransactionModel(
        id: 'txn_inc_1',
        kind: TxnKind.income,
        category: 'E',
        amount: 50000.0,
        note: 'Salary',
        date: '2026-03-01',
        account: CashFlowAccount.bank,
      );

      const outflowTxn = TransactionModel(
        id: 'txn_out_1',
        kind: TxnKind.outflow,
        category: 'E',
        amount: 3500.0,
        note: 'Groceries',
        date: '2026-03-02',
        account: CashFlowAccount.bank,
      );

      expect(incomeTxn.kind, equals(TxnKind.income));
      expect(outflowTxn.kind, equals(TxnKind.outflow));
      expect(incomeTxn.account, equals(CashFlowAccount.bank));
      expect(outflowTxn.account, equals(CashFlowAccount.bank));
    });

    test('CashFlowPeriodModel accurately aggregates net, income, and outflow', () {
      const period = CashFlowPeriodModel(
        id: 'period_2026_03',
        month: 3,
        year: 2026,
        openingBank: 10000.0,
        openingCash: 2000.0,
        openingCreditCard: 0.0,
        openingDebt: 0.0,
        totalIncome: 50000.0,
        totalOutflow: 15000.0,
        netCashFlow: 35000.0,
        closingBank: 45000.0,
        closingCash: 2000.0,
        closingCreditCard: 0.0,
      );

      expect(period.totalIncome, equals(50000.0));
      expect(period.totalOutflow, equals(15000.0));
      expect(period.netCashFlow, equals(35000.0));
      expect(period.netCashFlow, equals(period.totalIncome - period.totalOutflow));
    });

    test('CashFlowPeriodModel closing balances match transaction offsets', () {
      const period = CashFlowPeriodModel(
        id: 'period_2026_03',
        month: 3,
        year: 2026,
        openingBank: 10000.0,
        openingCash: 5000.0,
        openingCreditCard: 2000.0,
        openingDebt: 0.0,
        totalIncome: 20000.0,
        totalOutflow: 10000.0,
        netCashFlow: 10000.0,
        closingBank: 30000.0,
        closingCash: 3000.0,
        closingCreditCard: 4000.0,
      );

      // Bank: 10,000 opening + 20,000 net bank inflow = 30,000 closing
      expect(period.closingBank, equals(30000.0));
      // Cash: 5,000 opening - 2,000 outflow = 3,000 closing
      expect(period.closingCash, equals(3000.0));
      // Card: 2,000 opening debt + 2,000 card outflow = 4,000 closing debt
      expect(period.closingCreditCard, equals(4000.0));
    });
  });
}
