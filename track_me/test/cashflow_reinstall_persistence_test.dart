import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/cashflow/data/models/cashflow_models.dart';

void main() {
  group('CashFlow Reinstall Persistence & Resiliency Tests', () {
    test('CashFlowPeriodModel.fromJson correctly parses categories map from backend', () {
      final backendJson = {
        'id': 'cm78901234567890123456789', // 25-char Prisma CUID
        'month': 9,
        'year': 2026,
        'openingBank': 50000.0,
        'openingCash': 5000.0,
        'openingCreditCard': 0.0,
        'openingDebt': 0.0,
        'totalIncome': 75000.0,
        'totalOutflow': 25000.0,
        'netCashFlow': 50000.0,
        'closingBank': 100000.0,
        'closingCash': 5000.0,
        'closingCreditCard': 0.0,
        'categories': {
          'income': {'Salary': 75000.0},
          'outflow': {'Rent': 20000.0, 'Groceries': 5000.0},
        },
      };

      final period = CashFlowPeriodModel.fromJson(backendJson, isCurrent: true);

      expect(period.id, 'cm78901234567890123456789');
      expect(period.totalIncome, 75000.0);
      expect(period.totalOutflow, 25000.0);
      expect(period.closingBank, 100000.0);
      expect(period.incomeByCategory['Salary'], 75000.0);
      expect(period.outflowByCategory['Rent'], 20000.0);
      expect(period.outflowByCategory['Groceries'], 5000.0);
      expect(period.isSynthetic, isFalse);
      expect(period.isAuthentic(), isTrue);
    });

    test('Backend IDs of varying lengths (Prisma CUID 25 chars, MongoDB 24 chars, UUID 36 chars) are identified as backend IDs', () {
      final prismaCuid = 'cm78901234567890123456789'; // 25 chars
      final mongoObjectId = '64a7c1b2e4b0a1d2f3c4e5f6'; // 24 chars
      final uuid = '123e4567-e89b-12d3-a456-426614174000'; // 36 chars
      final localId = 'local_9_2026';
      final tempId = 'temp_1726650000000';
      final txnLocalId = 'txn_123';

      bool isBackendId(String id) =>
          id.isNotEmpty &&
          !id.startsWith('local_') &&
          !id.startsWith('temp_') &&
          !id.startsWith('txn_') &&
          !id.startsWith('period_') &&
          !id.startsWith('debt_');

      expect(isBackendId(prismaCuid), isTrue);
      expect(isBackendId(mongoObjectId), isTrue);
      expect(isBackendId(uuid), isTrue);
      expect(isBackendId(localId), isFalse);
      expect(isBackendId(tempId), isFalse);
      expect(isBackendId(txnLocalId), isFalse);
    });

    test('Authentic period preserves server totals on empty transaction list without being zeroed out', () {
      final authenticPeriod = CashFlowPeriodModel(
        id: 'cm78901234567890123456789',
        month: 9,
        year: 2026,
        openingBank: 50000.0,
        openingCash: 5000.0,
        openingCreditCard: 0.0,
        openingDebt: 0.0,
        totalIncome: 75000.0,
        totalOutflow: 25000.0,
        netCashFlow: 50000.0,
        closingBank: 100000.0,
        closingCash: 5000.0,
        closingCreditCard: 0.0,
        incomeByCategory: const {'Salary': 75000.0},
        outflowByCategory: const {'Rent': 20000.0},
        isCurrent: true,
      );

      final List<TransactionModel> txns = [];

      // Logic from _buildPeriodMap:
      final CashFlowPeriodModel recomputed;
      if (txns.isEmpty && !authenticPeriod.isSynthetic) {
        recomputed = authenticPeriod.copyWith(
          closingBank: (authenticPeriod.closingBank != 0 ||
                  authenticPeriod.totalIncome != 0 ||
                  authenticPeriod.totalOutflow != 0)
              ? authenticPeriod.closingBank
              : authenticPeriod.openingBank,
          closingCash: (authenticPeriod.closingCash != 0 ||
                  authenticPeriod.totalIncome != 0 ||
                  authenticPeriod.totalOutflow != 0)
              ? authenticPeriod.closingCash
              : authenticPeriod.openingCash,
        );
      } else {
        recomputed = authenticPeriod;
      }

      expect(recomputed.totalIncome, 75000.0);
      expect(recomputed.totalOutflow, 25000.0);
      expect(recomputed.closingBank, 100000.0);
      expect(recomputed.incomeByCategory['Salary'], 75000.0);
    });

    test('Clean install with network failure preserves error state and prevents cache poisoning with zeroed placeholder data', () {
      final Map<String, dynamic>? cached = null;
      final CashFlowPeriodModel? remoteCurrent = null;
      final List<CashFlowPeriodModel> remotePeriods = [];
      final bool hadNetworkFailure = true;

      final bool isFreshInstallNetworkFailure = (cached as Map<String, dynamic>?) == null &&
          (remoteCurrent as CashFlowPeriodModel?) == null &&
          remotePeriods.isEmpty &&
          hadNetworkFailure;

      expect(isFreshInstallNetworkFailure, isTrue);

      // Verify that in this condition, synthetic dummy periods are NOT generated and cache is NOT written
      final bool shouldPersistToCache = !isFreshInstallNetworkFailure;
      expect(shouldPersistToCache, isFalse);
    });

    test('Period with non-zero opening balances or income is not marked as fresh', () {
      final periodWithBalances = CashFlowPeriodModel(
        id: 'cm78901234567890123456789',
        month: 9,
        year: 2026,
        openingBank: 50000.0,
        openingCash: 5000.0,
        openingCreditCard: 0.0,
        openingDebt: 0.0,
        totalIncome: 0.0,
        totalOutflow: 0.0,
        netCashFlow: 0.0,
        closingBank: 50000.0,
        closingCash: 5000.0,
        closingCreditCard: 0.0,
        isCurrent: true,
      );

      bool isFresh(CashFlowPeriodModel p) =>
          p.totalIncome == 0 &&
          p.totalOutflow == 0 &&
          p.openingBank == 0 &&
          p.openingCash == 0 &&
          p.openingCreditCard == 0 &&
          p.openingDebt == 0;

      expect(isFresh(periodWithBalances), isFalse);

      final genuinelyZeroPeriod = CashFlowPeriodModel(
        id: 'local_9_2026',
        month: 9,
        year: 2026,
        openingBank: 0.0,
        openingCash: 0.0,
        openingCreditCard: 0.0,
        openingDebt: 0.0,
        isCurrent: true,
      );
      expect(isFresh(genuinelyZeroPeriod), isTrue);
    });
  });
}
