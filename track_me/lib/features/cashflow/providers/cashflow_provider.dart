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

    try {
      final dio = DioClient().dio;
      final results = await Future.wait([
        dio.get('/cashflow/periods/current'),
        dio.get('/cashflow/periods'),
        dio.get('/cashflow/debts'),
        dio.get('/cashflow/debts/summary'),
      ]);

      if (_dirtySinceLoad) return;
      final current = CashFlowPeriodModel.fromJson(
        results[0].data['data'] as Map<String, dynamic>,
        isCurrent: true,
      );
      final periods = ((results[1].data['data'] ?? results[1].data) as List)
          .map((e) => CashFlowPeriodModel.fromJson(
                e as Map<String, dynamic>,
                isCurrent:
                    e['month'] == current.month && e['year'] == current.year,
              ))
          .toList();
      // The current-period read may have just opened the new month; refresh
      // the list so it includes it even if /periods ran first.
      if (!periods.any((p) => p.id == current.id)) {
        periods.add(current);
      }
      final debts = ((results[2].data['data'] ?? results[2].data) as List)
          .map((e) => DebtEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final summary =
          (results[3].data['data'] ?? results[3].data) as Map<String, dynamic>;

      final next = CashFlowState(
        current: AsyncValue.data(current),
        history: periods,
        transactions: state.transactions,
        debts: debts,
        yetToReceive: (summary['yetToReceive'] as num?)?.toDouble() ?? 0,
        yetToGive: (summary['yetToGive'] as num?)?.toDouble() ?? 0,
      );
      state = next;
      await _persist();
      await _loadTransactions(current.id);
    } catch (e) {
      // Network/parse failure. Cached data (if any) is already applied;
      // otherwise surface an error so the UI can show a retry button
      // instead of spinning forever.
      if (!_dirtySinceLoad && state.current.valueOrNull == null) {
        state = CashFlowState(
          current: AsyncValue.error(e, StackTrace.current),
          history: state.history,
          transactions: state.transactions,
          debts: state.debts,
          yetToReceive: state.yetToReceive,
          yetToGive: state.yetToGive,
        );
      }
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
    final optimisticPeriod = CashFlowPeriodModel(
      id: existingCurrent?.id ?? 'period_${month}_$year',
      month: month,
      year: year,
      openingBank: bank,
      openingCash: cash,
      openingCreditCard: creditCard,
      openingDebt: debt,
      closingBank: bank,
      isCurrent: true,
    );
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
    // Optimistic insert so the UI reacts instantly, offline included.
    state = state.copyWith(
      transactions: [txn, ...state.transactions],
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
      state = state.copyWith(transactions: updated);
      await _refreshTotals();
      await _persist();
    } catch (_) {
      // Keep the optimistic entry; totals refresh on next successful sync.
      final temp = txn.copyWith(id: txn.id);
      state = state.copyWith(transactions: [
        temp,
        ...state.transactions.where((t) => t.id != txn.id),
      ]);
      await _persist();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _dirtySinceLoad = true;
    final before = state.transactions;
    state = state.copyWith(
        transactions: before.where((t) => t.id != id).toList());
    try {
      await DioClient().dio.delete('/cashflow/transactions/$id');
      await _refreshTotals();
    } catch (_) {
      state = state.copyWith(transactions: before);
    }
    await _persist();
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
      final response = await DioClient().dio.get('/cashflow/periods/current');
      final fresh = CashFlowPeriodModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
        isCurrent: true,
      );
      state = state.copyWith(
        current: AsyncValue.data(fresh),
        history: state.history
            .map((p) => p.isCurrent ? fresh : p)
            .toList(),
      );
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind == TxnKind.income ? 'INCOME' : 'OUTFLOW',
        'category': category,
        'amount': amount,
        'note': note,
        'date': date,
      };
}

final cashFlowProvider =
    StateNotifierProvider<CashFlowNotifier, CashFlowState>((ref) {
  return CashFlowNotifier();
});
