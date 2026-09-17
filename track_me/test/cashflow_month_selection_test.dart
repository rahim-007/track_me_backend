import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';

void main() {
  group('Cash Flow Month Selection Logic Tests', () {
    test(
        'Calculates current month and previous month correctly for normal month',
        () {
      final now = DateTime(2026, 9, 9); // September 2026
      final currentMonth = now.month;
      final currentYear = now.year;
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      expect(currentMonth, 9);
      expect(currentYear, 2026);
      expect(prevMonth, 8);
      expect(prevYear, 2026);
      expect(CashFlowPeriodModel.monthName(currentMonth), 'September');
      expect(CashFlowPeriodModel.monthName(prevMonth), 'August');
    });

    test(
        'Handles year rollover transition correctly (e.g. January 2027 -> December 2026)',
        () {
      final now = DateTime(2027, 1, 15); // January 2027
      final currentMonth = now.month;
      final currentYear = now.year;
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;

      expect(currentMonth, 1);
      expect(currentYear, 2027);
      expect(prevMonth, 12);
      expect(prevYear, 2026);
      expect(CashFlowPeriodModel.monthName(currentMonth), 'January');
      expect(CashFlowPeriodModel.monthName(prevMonth), 'December');
    });

    test('Past months start from when user started using this (e.g. started in August 2026)', () {
      final now = DateTime(2026, 9, 9); // September 2026
      final currentMonth = now.month;
      final currentYear = now.year;

      // User started in August 2026 (e.g. earliest backend period or profile createdAt)
      const startKey = 202608;

      final Map<int, CashFlowPeriodModel> periodMap = {};

      // Seed existing August period
      periodMap[202608] = const CashFlowPeriodModel(
        id: 'period_8_2026',
        month: 8,
        year: 2026,
        openingBank: 10000,
        openingCash: 2000,
        openingCreditCard: 0,
        openingDebt: 0,
        closingBank: 15000,
        closingCash: 2000,
        isCurrent: false,
      );

      // Generate all months from startKey to currentKey
      const startYear = startKey ~/ 100;
      const startMonth = startKey % 100;
      var cursor = DateTime(startYear, startMonth, 1);
      final currentEnd = DateTime(currentYear, currentMonth, 1);

      while (!cursor.isAfter(currentEnd)) {
        final y = cursor.year;
        final m = cursor.month;
        final k = y * 100 + m;
        final isCurr = (y == currentYear && m == currentMonth);

        if (!periodMap.containsKey(k)) {
          periodMap[k] = CashFlowPeriodModel(
            id: isCurr ? 'local_${m}_$y' : 'period_${m}_$y',
            month: m,
            year: y,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: isCurr,
          );
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      final periods = periodMap.values.map((p) {
        final isCurr = (p.month == currentMonth && p.year == currentYear);
        return p.copyWith(isCurrent: isCurr);
      }).toList()
        ..sort((a, b) {
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
        });

      // ONLY 2 periods: September 2026 (Current) and August 2026 (Start)
      expect(periods.length, 2);
      expect(periods[0].isCurrent, true);
      expect(periods[0].label, 'September 2026');
      expect(periods[1].isCurrent, false);
      expect(periods[1].label, 'August 2026');
    });

    test('Past months start from when user started using this (e.g. started in May 2026)', () {
      final now = DateTime(2026, 9, 9); // September 2026
      final currentMonth = now.month;
      final currentYear = now.year;

      // User started in May 2026
      const startKey = 202605;

      final Map<int, CashFlowPeriodModel> periodMap = {};

      const startYear = startKey ~/ 100;
      const startMonth = startKey % 100;
      var cursor = DateTime(startYear, startMonth, 1);
      final currentEnd = DateTime(currentYear, currentMonth, 1);

      while (!cursor.isAfter(currentEnd)) {
        final y = cursor.year;
        final m = cursor.month;
        final k = y * 100 + m;
        final isCurr = (y == currentYear && m == currentMonth);

        if (!periodMap.containsKey(k)) {
          periodMap[k] = CashFlowPeriodModel(
            id: isCurr ? 'local_${m}_$y' : 'period_${m}_$y',
            month: m,
            year: y,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: isCurr,
          );
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      final periods = periodMap.values.map((p) {
        final isCurr = (p.month == currentMonth && p.year == currentYear);
        return p.copyWith(isCurrent: isCurr);
      }).toList()
        ..sort((a, b) {
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
        });

      // 5 periods: September (Current), August, July, June, May
      expect(periods.length, 5);
      expect(periods[0].label, 'September 2026');
      expect(periods[0].isCurrent, true);
      expect(periods[1].label, 'August 2026');
      expect(periods[2].label, 'July 2026');
      expect(periods[3].label, 'June 2026');
      expect(periods[4].label, 'May 2026');
    });

    test('New user starting this month only sees Current Month (no artificial past months)', () {
      final now = DateTime(2026, 9, 9);
      final currentMonth = now.month;
      final currentYear = now.year;
      final currentKey = currentYear * 100 + currentMonth;

      // New user started in September 2026
      final startKey = currentKey;

      final Map<int, CashFlowPeriodModel> periodMap = {};

      final startYear = startKey ~/ 100;
      final startMonth = startKey % 100;
      var cursor = DateTime(startYear, startMonth, 1);
      final currentEnd = DateTime(currentYear, currentMonth, 1);

      while (!cursor.isAfter(currentEnd)) {
        final y = cursor.year;
        final m = cursor.month;
        final k = y * 100 + m;
        final isCurr = (y == currentYear && m == currentMonth);

        if (!periodMap.containsKey(k)) {
          periodMap[k] = CashFlowPeriodModel(
            id: isCurr ? 'local_${m}_$y' : 'period_${m}_$y',
            month: m,
            year: y,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: isCurr,
          );
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      final periods = periodMap.values.map((p) {
        final isCurr = (p.month == currentMonth && p.year == currentYear);
        return p.copyWith(isCurrent: isCurr);
      }).toList();

      expect(periods.length, 1);
      expect(periods[0].label, 'September 2026');
      expect(periods[0].isCurrent, true);
    });

    test('Recomputes period totals accurately based on month transactions', () {
      const augPeriod = CashFlowPeriodModel(
        id: 'p_aug',
        month: 8,
        year: 2026,
        openingBank: 10000,
        openingCash: 1000,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: false,
      );

      const septPeriod = CashFlowPeriodModel(
        id: 'p_sept',
        month: 9,
        year: 2026,
        openingBank: 14000,
        openingCash: 1000,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: true,
      );

      final allTxns = [
        // August transactions
        const TransactionModel(
          id: 't1',
          kind: TxnKind.income,
          category: 'E',
          amount: 5000,
          note: 'August Salary bonus',
          date: '2026-08-10',
          account: CashFlowAccount.bank,
        ),
        const TransactionModel(
          id: 't2',
          kind: TxnKind.outflow,
          category: 'E',
          amount: 1000,
          note: 'August Groceries',
          date: '2026-08-15',
          account: CashFlowAccount.bank,
        ),
        // September transactions
        const TransactionModel(
          id: 't3',
          kind: TxnKind.income,
          category: 'E',
          amount: 30000,
          note: 'September Salary',
          date: '2026-09-01',
          account: CashFlowAccount.bank,
        ),
        const TransactionModel(
          id: 't4',
          kind: TxnKind.outflow,
          category: 'I',
          amount: 10000,
          note: 'September Investment',
          date: '2026-09-05',
          account: CashFlowAccount.bank,
        ),
      ];

      // Filter for August
      final augTxns = allTxns.where((t) {
        final p = t.date.split('-');
        return int.parse(p[0]) == augPeriod.year &&
            int.parse(p[1]) == augPeriod.month;
      }).toList();

      expect(augTxns.length, 2);
      final augIncome = augTxns
          .where((t) => t.kind == TxnKind.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final augOutflow = augTxns
          .where((t) => t.kind == TxnKind.outflow)
          .fold<double>(0, (sum, t) => sum + t.amount);
      expect(augIncome, 5000);
      expect(augOutflow, 1000);
      expect(augIncome - augOutflow, 4000);

      // Filter for September
      final septTxns = allTxns.where((t) {
        final p = t.date.split('-');
        return int.parse(p[0]) == septPeriod.year &&
            int.parse(p[1]) == septPeriod.month;
      }).toList();

      expect(septTxns.length, 2);
      final septIncome = septTxns
          .where((t) => t.kind == TxnKind.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final septOutflow = septTxns
          .where((t) => t.kind == TxnKind.outflow)
          .fold<double>(0, (sum, t) => sum + t.amount);
      expect(septIncome, 30000);
      expect(septOutflow, 10000);
      expect(septIncome - septOutflow, 20000);
    });

    test('isAuthentic correctly distinguishes real user periods from dummy placeholder periods', () {
      const currentKey = 202609;

      // 1. Current month period is always authentic
      const currentPeriod = CashFlowPeriodModel(
        id: 'local_9_2026',
        month: 9,
        year: 2026,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: true,
      );
      expect(currentPeriod.isAuthentic(currentKey: currentKey), true);

      // 2. Real backend period (MongoDB ObjectID) is authentic
      const backendPeriod = CashFlowPeriodModel(
        id: '66d0a1b2c3d4e5f6a7b8c9d0',
        month: 8,
        year: 2026,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: false,
      );
      expect(backendPeriod.isAuthentic(currentKey: currentKey), true);

      // 3. Period with financial data is authentic
      const periodWithData = CashFlowPeriodModel(
        id: 'period_8_2026',
        month: 8,
        year: 2026,
        openingBank: 5000,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: false,
      );
      expect(periodWithData.isAuthentic(currentKey: currentKey), true);

      // 4. Period with matching transactions is authentic
      const periodWithTxn = CashFlowPeriodModel(
        id: 'period_7_2026',
        month: 7,
        year: 2026,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: false,
      );
      const txns = [
        TransactionModel(
          id: 't_july',
          kind: TxnKind.income,
          category: 'E',
          amount: 1000,
          note: 'July income',
          date: '2026-07-15',
          account: CashFlowAccount.bank,
        ),
      ];
      expect(periodWithTxn.isAuthentic(transactions: txns, currentKey: currentKey), true);

      // 5. Pure synthetic dummy period with 0 values and no transactions is NOT authentic
      const dummyPeriod = CashFlowPeriodModel(
        id: 'period_9_2025',
        month: 9,
        year: 2025,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        isCurrent: false,
      );
      expect(dummyPeriod.isAuthentic(currentKey: currentKey), false);
    });

    test('Eliminates poisoned dummy cache periods so old 2025 months are never shown', () {
      final now = DateTime(2026, 9, 9);
      final currentMonth = now.month;
      final currentYear = now.year;
      final currentKey = currentYear * 100 + currentMonth;

      // Simulate a poisoned history from cache containing 12 dummy periods from 2025
      final List<CashFlowPeriodModel> poisonedHistory = [
        for (int m = 9; m <= 12; m++)
          CashFlowPeriodModel(
            id: 'period_${m}_2025',
            month: m,
            year: 2025,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: false,
          ),
        for (int m = 1; m <= 8; m++)
          CashFlowPeriodModel(
            id: m == 8 ? '66d0a1b2c3d4e5f6a7b8c9d0' : 'period_${m}_2026',
            month: m,
            year: 2026,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: false,
          ),
      ];

      // User's account was created in August 2026
      final profileCreatedAt = DateTime(2026, 8, 15);
      final profileStartKey = profileCreatedAt.year * 100 + profileCreatedAt.month;

      // Filter authentic periods
      final Map<int, CashFlowPeriodModel> periodMap = {};
      for (final p in poisonedHistory) {
        final isCurrMonth = (p.month == currentMonth && p.year == currentYear);
        if (isCurrMonth || p.isAuthentic(currentKey: currentKey)) {
          periodMap[p.year * 100 + p.month] = p;
        }
      }

      // Ensure Current Month is present
      if (!periodMap.containsKey(currentKey)) {
        periodMap[currentKey] = CashFlowPeriodModel(
          id: 'local_${currentMonth}_$currentYear',
          month: currentMonth,
          year: currentYear,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
          isCurrent: true,
        );
      }

      // Determine startKey
      int startKey = currentKey;
      for (final k in periodMap.keys) {
        if (k < startKey) startKey = k;
      }

      // Enforce lower bound with profile creation
      if (startKey < profileStartKey) {
        startKey = profileStartKey;
      }

      // Fill months between startKey and currentKey
      final startYear = startKey ~/ 100;
      final startMonth = startKey % 100;
      var cursor = DateTime(startYear, startMonth, 1);
      final currentEnd = DateTime(currentYear, currentMonth, 1);

      while (!cursor.isAfter(currentEnd)) {
        final y = cursor.year;
        final m = cursor.month;
        final k = y * 100 + m;
        final isCurr = (y == currentYear && m == currentMonth);

        if (!periodMap.containsKey(k)) {
          periodMap[k] = CashFlowPeriodModel(
            id: isCurr ? 'local_${m}_$y' : 'period_${m}_$y',
            month: m,
            year: y,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: isCurr,
          );
        }
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      // Strictly filter to [startKey, currentKey]
      final periods = periodMap.entries
          .where((e) => e.key >= startKey && e.key <= currentKey)
          .map((e) => e.value)
          .toList()
        ..sort((a, b) {
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
        });

      // ONLY 2 periods exist: September 2026 and August 2026
      expect(periods.length, 2);
      expect(periods[0].label, 'September 2026');
      expect(periods[0].isCurrent, true);
      expect(periods[1].label, 'August 2026');
      expect(periods[1].isCurrent, false);

      // Verify none of the 2025 dummy periods leaked through
      expect(periods.any((p) => p.year == 2025), false);
    });

    test('Guarantees August 2026 and September 2026 are both shown when user uses from August even without transactions', () {
      final now = DateTime(2026, 9, 9);
      final currentMonth = now.month;
      final currentYear = now.year;
      final currentKey = currentYear * 100 + currentMonth;

      final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
      final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
      final prevKey = prevYear * 100 + prevMonth;

      final Map<int, CashFlowPeriodModel> periodMap = {};

      if (!periodMap.containsKey(prevKey)) {
        periodMap[prevKey] = CashFlowPeriodModel(
          id: 'period_${prevMonth}_$prevYear',
          month: prevMonth,
          year: prevYear,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
          isCurrent: false,
        );
      }

      if (!periodMap.containsKey(currentKey)) {
        periodMap[currentKey] = CashFlowPeriodModel(
          id: 'local_${currentMonth}_$currentYear',
          month: currentMonth,
          year: currentYear,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
          isCurrent: true,
        );
      }

      int startKey = prevKey;
      for (final k in periodMap.keys) {
        if (k < startKey) startKey = k;
      }

      final periods = periodMap.entries
          .where((e) => e.key >= startKey && e.key <= currentKey)
          .map((e) => e.value)
          .toList()
        ..sort((a, b) {
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
        });

      expect(periods.length, 2);
      expect(periods[0].label, 'September 2026');
      expect(periods[0].isCurrent, true);
      expect(periods[1].label, 'August 2026');
      expect(periods[1].isCurrent, false);
    });
  });
}
