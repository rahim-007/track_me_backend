import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/cashflow_models.dart';

/// Aggregated UI state for the Cash Flow tab.
class CashFlowState {
  final AsyncValue<CashFlowPeriodModel> current;
  final List<CashFlowPeriodModel> history;
  /// Transactions of the period being viewed (current or a past one).
  final List<TransactionModel> transactions;
  final List<DebtEntryModel> debts;
  final double yetToReceive;
  final double yetToGive;

  const CashFlowState({
    this.current = const AsyncValue.loading(),
    this.history = const [],
    this.transactions = const [],
    this.debts = const [],
    this.yetToReceive = 0,
    this.yetToGive = 0,
  });

  CashFlowState copyWith({
    AsyncValue<CashFlowPeriodModel>? current,
    List<CashFlowPeriodModel>? history,
    List<TransactionModel>? transactions,
    List<DebtEntryModel>? debts,
    double? yetToReceive,
    double? yetToGive,
  }) {
    return CashFlowState(
      current: current ?? this.current,
      history: history ?? this.history,
      transactions: transactions ?? this.transactions,
      debts: debts ?? this.debts,
      yetToReceive: yetToReceive ?? this.yetToReceive,
      yetToGive: yetToGive ?? this.yetToGive,
    );
  }
}

/// Offline-first notifier mirroring the goals/habits pattern: optimistic local
/// state + JSON file cache, reconciled with the backend when reachable.
class CashFlowNotifier extends StateNotifier<CashFlowState> {
  static const String _cacheName = 'cashflow_cache';

  bool _dirtySinceLoad = false;

  CashFlowNotifier() : super(const CashFlowState()) {
    load();
  }

  Future<void> load() async {
    _dirtySinceLoad = false;

    // Show cached data instantly (offline-first), then reconcile.
    final cached = await JsonFileCache.read<Map<String, dynamic>>(
      _cacheName,
      (json) => json as Map<String, dynamic>,
    );
    if (cached != null && !_dirtySinceLoad) {
      state = _stateFromCacheJson(cached);
    }

    final now = DateTime.now();
    CashFlowPeriodModel? current;
    List<CashFlowPeriodModel> periods = [];
    List<DebtEntryModel> debts = state.debts;
    double yetToReceive = state.yetToReceive;
    double yetToGive = state.yetToGive;

    final dio = DioClient().dio;

    // 1. Fetch current period (fallback to local month if 500/network error)
    try {
      final res = await dio.get('/cashflow/periods/current');
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      current = CashFlowPeriodModel.fromJson(data, isCurrent: true);
    } catch (_) {
      current = state.current.valueOrNull ??
          CashFlowPeriodModel(
            id: 'local_${now.month}_${now.year}',
            month: now.month,
            year: now.year,
            openingBank: 0,
            openingCash: 0,
            openingCreditCard: 0,
            openingDebt: 0,
            isCurrent: true,
          );
    }

    // 2. Fetch history periods
    try {
      final res = await dio.get('/cashflow/periods');
      final list = ((res.data['data'] ?? res.data) as List);
      periods = list
          .map((e) => CashFlowPeriodModel.fromJson(
                e as Map<String, dynamic>,
                isCurrent: e['month'] == current!.month &&
                    e['year'] == current.year,
              ))
          .toList();
    } catch (_) {
      periods = state.history.isNotEmpty ? state.history : [current];
    }

    if (!periods.any((p) => p.id == current!.id)) {
      periods.add(current);
    }

    // 3. Fetch debts
    try {
      final res = await dio.get('/cashflow/debts');
      final list = ((res.data['data'] ?? res.data) as List);
      debts = list
          .map((e) => DebtEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    // 4. Fetch debt summary
    try {
      final res = await dio.get('/cashflow/debts/summary');
      final summary = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      yetToReceive = (summary['yetToReceive'] as num?)?.toDouble() ?? yetToReceive;
      yetToGive = (summary['yetToGive'] as num?)?.toDouble() ?? yetToGive;
    } catch (_) {}

    if (_dirtySinceLoad) return;

    state = CashFlowState(
      current: AsyncValue.data(current),
      history: periods,
      transactions: state.transactions,
      debts: debts,
      yetToReceive: yetToReceive,
      yetToGive: yetToGive,
    );
    await _persist();
    if (current.id.isNotEmpty && !current.id.startsWith('local_')) {
      await _loadTransactions(current.id);
    }
  }

  Future<void> _loadTransactions(String periodId) async {
    try {
      final response = await DioClient()
          .dio
          .get('/cashflow/transactions', queryParameters: {'periodId': periodId});
      final txns = ((response.data['data'] ?? response.data) as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!_dirtySinceLoad) {
        state = state.copyWith(transactions: txns);
        await _persist();
      }
    } catch (_) {}
  }

  /// View a past month's transactions (read-only history).
  Future<void> selectPeriod(CashFlowPeriodModel period) async {
    if (period.isCurrent) return;
    state = state.copyWith(transactions: const []);
    await _loadTransactions(period.id);
  }

  /// Back to the live month after browsing history.
  Future<void> backToCurrent() async {
    final current = state.current.valueOrNull;
    if (current != null) await _loadTransactions(current.id);
  }

  Future<void> setupFirstPeriod({
    required int month,
    required int year,
    required double bank,
    required double cash,
    required double creditCard,
    required double debt,
  }) async {
    _dirtySinceLoad = true;
    final existingCurrent = state.current.valueOrNull;
    final initialPeriod = CashFlowPeriodModel(
      id: existingCurrent?.id ?? 'period_${month}_$year',
      month: month,
      year: year,
      openingBank: bank,
      openingCash: cash,
      openingCreditCard: creditCard,
      openingDebt: debt,
      closingBank: bank,
      closingCash: cash,
      closingCreditCard: creditCard,
      isCurrent: true,
    );
    final optimisticPeriod =
        _recomputePeriodWithTxns(initialPeriod, state.transactions);
    state = state.copyWith(current: AsyncValue.data(optimisticPeriod));
    await _persist();

    try {
      final response = await DioClient().dio.post('/cashflow/periods', data: {
        'month': month,
        'year': year,
        'openingBank': bank,
        'openingCash': cash,
        'openingCreditCard': creditCard,
        'openingDebt': debt,
      });
      final periodData =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final period = CashFlowPeriodModel.fromJson(
        periodData,
        isCurrent: true,
      );
      state = state.copyWith(current: AsyncValue.data(period));
      await _persist();
    } catch (_) {}
  }

  Future<void> updateOpeningBalances({
    required String periodId,
    required Map<String, double> balances,
  }) async {
    _dirtySinceLoad = true;
    try {
      await DioClient()
          .dio
          .patch('/cashflow/periods/$periodId/balances', data: balances);
    } finally {
      await load();
    }
  }

  Future<void> addTransaction(TransactionModel txn) async {
    _dirtySinceLoad = true;
    final newTxns = [txn, ...state.transactions];
    final currentPeriod = state.current.valueOrNull;
    final updatedCurrent = currentPeriod == null
        ? state.current
        : AsyncValue.data(_recomputePeriodWithTxns(currentPeriod, newTxns));

    // Optimistic insert so the UI reacts instantly, offline included.
    state = state.copyWith(
      current: updatedCurrent,
      transactions: newTxns,
    );
    try {
      final response = await DioClient()
          .dio
          .post('/cashflow/transactions', data: txn.toCreateJson());
      final savedData =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final saved = TransactionModel.fromJson(savedData);
      final updated = state.transactions
          .map((t) => t.id == txn.id ? saved : t)
          .toList();
      state = state.copyWith(
        current: currentPeriod == null
            ? state.current
            : AsyncValue.data(_recomputePeriodWithTxns(currentPeriod, updated)),
        transactions: updated,
      );
      await _refreshTotals();
      await _persist();
    } catch (_) {
      // Keep the optimistic entry; totals refresh on next successful sync.
      final temp = txn.copyWith(id: txn.id);
      final fallbackTxns = [
        temp,
        ...state.transactions.where((t) => t.id != txn.id),
      ];
      final period = state.current.valueOrNull;
      state = state.copyWith(
        current: period == null ? state.current : AsyncValue.data(_recomputePeriodWithTxns(period, fallbackTxns)),
        transactions: fallbackTxns,
      );
      await _persist();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _dirtySinceLoad = true;
    final beforeTxns = state.transactions;
    final beforePeriod = state.current.valueOrNull;
    final updatedTxns = beforeTxns.where((t) => t.id != id).toList();

    state = state.copyWith(
      current: beforePeriod == null ? state.current : AsyncValue.data(_recomputePeriodWithTxns(beforePeriod, updatedTxns)),
      transactions: updatedTxns,
    );
    try {
      await DioClient().dio.delete('/cashflow/transactions/$id');
      await _refreshTotals();
    } catch (_) {
      state = state.copyWith(
        current: beforePeriod == null ? state.current : AsyncValue.data(beforePeriod),
        transactions: beforeTxns,
      );
    }
    await _persist();
  }

  CashFlowPeriodModel _recomputePeriodWithTxns(
    CashFlowPeriodModel period,
    List<TransactionModel> txns,
  ) {
    double bankDelta = 0;
    double cashDelta = 0;
    double creditCardDelta = 0;
    double totalIncome = 0;
    double totalOutflow = 0;
    final Map<String, double> incomeCat = {};
    final Map<String, double> outflowCat = {};

    for (final t in txns) {
      if (t.kind == TxnKind.income) {
        totalIncome += t.amount;
        incomeCat[t.category] = (incomeCat[t.category] ?? 0) + t.amount;
        if (t.account == CashFlowAccount.cash) {
          cashDelta += t.amount;
        } else {
          bankDelta += t.amount;
        }
      } else if (t.kind == TxnKind.outflow) {
        totalOutflow += t.amount;
        outflowCat[t.category] = (outflowCat[t.category] ?? 0) + t.amount;
        if (t.account == CashFlowAccount.cash) {
          cashDelta -= t.amount;
        } else if (t.account == CashFlowAccount.creditCard) {
          creditCardDelta += t.amount; // debt increases
        } else {
          bankDelta -= t.amount;
        }

        // Debt Repayment (category D) paid from Bank or Cash reduces Credit Card debt owed
        if (t.category == 'D' && t.account != CashFlowAccount.creditCard) {
          creditCardDelta -= t.amount;
        }
      }
    }

    final net = totalIncome - totalOutflow;

    return CashFlowPeriodModel(
      id: period.id,
      month: period.month,
      year: period.year,
      openingBank: period.openingBank,
      openingCash: period.openingCash,
      openingCreditCard: period.openingCreditCard,
      openingDebt: period.openingDebt,
      totalIncome: totalIncome,
      totalOutflow: totalOutflow,
      netCashFlow: net,
      closingBank: period.openingBank + bankDelta,
      closingCash: period.openingCash + cashDelta,
      closingCreditCard: period.openingCreditCard + creditCardDelta,
      incomeByCategory: incomeCat,
      outflowByCategory: outflowCat,
      isCurrent: period.isCurrent,
    );
  }

  Future<void> addDebt(DebtEntryModel entry) async {
    _dirtySinceLoad = true;
    state = state.copyWith(debts: [entry, ...state.debts]);
    try {
      final response = await DioClient()
          .dio
          .post('/cashflow/debts', data: entry.toCreateJson());
      final savedData =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final saved = DebtEntryModel.fromJson(savedData);
      final updated =
          state.debts.map((d) => d.id == entry.id ? saved : d).toList();
      state = state.copyWith(debts: updated);
      await _refreshDebtSummary();
      await _persist();
    } catch (_) {
      await _persist();
    }
  }

  Future<void> setDebtSettled(DebtEntryModel entry, bool settled) async {
    _dirtySinceLoad = true;
    final updatedLocal = DebtEntryModel(
      id: entry.id,
      theyOweMe: entry.theyOweMe,
      person: entry.person,
      amount: entry.amount,
      note: entry.note,
      date: entry.date,
      settled: settled,
    );
    state = state.copyWith(
      debts: state.debts.map((d) => d.id == entry.id ? updatedLocal : d).toList(),
    );
    try {
      final response = await DioClient()
          .dio
          .patch('/cashflow/debts/${entry.id}', data: {'settled': settled});
      final savedData =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final updated = DebtEntryModel.fromJson(savedData);
      state = state.copyWith(
        debts: state.debts.map((d) => d.id == entry.id ? updated : d).toList(),
      );
      await _refreshDebtSummary();
      await _persist();
    } catch (_) {
      await _persist();
    }
  }

  Future<void> deleteDebt(String id) async {
    _dirtySinceLoad = true;
    final before = state.debts;
    state = state.copyWith(debts: before.where((d) => d.id != id).toList());
    try {
      await DioClient().dio.delete('/cashflow/debts/$id');
      await _refreshDebtSummary();
    } catch (_) {
      state = state.copyWith(debts: before);
    }
    await _persist();
  }

  Future<void> _refreshTotals() async {
    try {
      final dio = DioClient().dio;
      final results = await Future.wait([
        dio.get('/cashflow/periods/current'),
        dio.get('/cashflow/periods'),
      ]);
      final currentData =
          (results[0].data['data'] ?? results[0].data) as Map<String, dynamic>;
      final freshCurrent = CashFlowPeriodModel.fromJson(
        currentData,
        isCurrent: true,
      );
      final periods = ((results[1].data['data'] ?? results[1].data) as List)
          .map((e) => CashFlowPeriodModel.fromJson(
                e as Map<String, dynamic>,
                isCurrent: e['month'] == freshCurrent.month &&
                    e['year'] == freshCurrent.year,
              ))
          .toList();
      state = state.copyWith(
        current: AsyncValue.data(freshCurrent),
        history: periods,
      );
      await _persist();
    } catch (_) {}
  }

  Future<void> _refreshDebtSummary() async {
    try {
      final response = await DioClient().dio.get('/cashflow/debts/summary');
      final s = (response.data['data'] ?? response.data) as Map<String, dynamic>;
      state = state.copyWith(
        yetToReceive: (s['yetToReceive'] as num?)?.toDouble() ?? 0,
        yetToGive: (s['yetToGive'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {}
  }

  CashFlowState _stateFromCacheJson(Map<String, dynamic> json) {
    return CashFlowState(
      current: json['current'] == null
          ? const AsyncValue.loading()
          : AsyncValue.data(
              CashFlowPeriodModel.fromJson(
                (json['current'] as Map<String, dynamic>)
                  ..['isCurrent'] = null,
                isCurrent: true,
              ),
            ),
      history: ((json['history'] as List?) ?? const [])
          .map((e) => CashFlowPeriodModel.fromJson(
                e as Map<String, dynamic>, isCurrent: false))
          .toList(),
      transactions: ((json['transactions'] as List?) ?? const [])
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      debts: ((json['debts'] as List?) ?? const [])
          .map((e) => DebtEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      yetToReceive: (json['yetToReceive'] as num?)?.toDouble() ?? 0,
      yetToGive: (json['yetToGive'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> _persist() async {
    final current = state.current.valueOrNull;
    await JsonFileCache.write(_cacheName, {
      'current': current?.toJson(),
      'history': state.history.map((p) => p.toJson()).toList(),
      'transactions': state.transactions.map((t) => t.toJson()).toList(),
      'debts': state.debts.map(toDebtJson).toList(),
      'yetToReceive': state.yetToReceive,
      'yetToGive': state.yetToGive,
    });
  }

  static Map<String, dynamic> toDebtJson(DebtEntryModel d) => {
        'id': d.id,
        'direction': d.theyOweMe ? 'RECEIVE' : 'GIVE',
        'person': d.person,
        'amount': d.amount,
        'note': d.note,
        'date': d.date,
        'settled': d.settled,
      };
}

extension on TransactionModel {
  TransactionModel copyWith({String? id}) =>
      TransactionModel(
        id: id ?? this.id,
        kind: kind,
        category: category,
        amount: amount,
        note: note,
        date: date,
        account: account,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind == TxnKind.income ? 'INCOME' : 'OUTFLOW',
        'category': category,
        'amount': amount,
        'note': note,
        'date': date,
        'account': account.apiValue,
      };
}

final cashFlowProvider =
    StateNotifierProvider<CashFlowNotifier, CashFlowState>((ref) {
  return CashFlowNotifier();
});
