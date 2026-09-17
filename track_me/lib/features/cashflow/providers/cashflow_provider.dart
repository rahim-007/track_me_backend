import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/local/user_local_cache.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/widgets/home_widget_service.dart';
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
  List<TransactionModel> _allTransactions = [];
  int? _startedYear;
  int? _startedMonth;

  CashFlowNotifier() : super(const CashFlowState()) {
    load();
  }

  List<TransactionModel> _transactionsForPeriod(CashFlowPeriodModel period) {
    return _allTransactions.where((t) {
      final parts = t.date.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y == period.year && m == period.month) return true;
      }
      return false;
    }).toList();
  }

  void _mergeTransactions(List<TransactionModel> fetched) {
    final existingMap = {for (final t in _allTransactions) t.id: t};
    for (final t in fetched) {
      existingMap[t.id] = t;
    }
    _allTransactions = existingMap.values.toList();
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
      final currentPeriod = state.current.valueOrNull;
      if (currentPeriod != null) {
        try {
          HomeWidgetService.instance.syncCashFlowData(period: currentPeriod);
        } catch (_) {}
      }
    }

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentKey = currentYear * 100 + currentMonth;

    final profile = await UserLocalCache.instance.getProfile();
    final profileCreatedAt = profile?.createdAt;

    final dio = DioClient().dio;
    final List<CashFlowPeriodModel> remotePeriods = [];
    CashFlowPeriodModel? remoteCurrent;

    // 1. Fetch current period from backend
    try {
      final res = await dio.get('/cashflow/periods/current');
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      final p = CashFlowPeriodModel.fromJson(data, isCurrent: true);
      if (p.month == currentMonth && p.year == currentYear) {
        remoteCurrent = p;
      } else {
        remotePeriods.add(p.copyWith(isCurrent: false));
      }
    } catch (_) {}

    // 2. Fetch history periods from backend
    try {
      final res = await dio.get('/cashflow/periods');
      final list = ((res.data['data'] ?? res.data) as List);
      final fetched = list
          .map((e) => CashFlowPeriodModel.fromJson(
                e as Map<String, dynamic>,
                isCurrent:
                    e['month'] == currentMonth && e['year'] == currentYear,
              ))
          .toList();
      remotePeriods.addAll(fetched);
    } catch (_) {}

    // 3. Fetch debts
    List<DebtEntryModel> debts = state.debts;
    try {
      final res = await dio.get('/cashflow/debts');
      final list = ((res.data['data'] ?? res.data) as List);
      debts = list
          .map((e) => DebtEntryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    // 4. Fetch debt summary
    double yetToReceive = state.yetToReceive;
    double yetToGive = state.yetToGive;
    try {
      final res = await dio.get('/cashflow/debts/summary');
      final summary = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      yetToReceive =
          (summary['yetToReceive'] as num?)?.toDouble() ?? yetToReceive;
      yetToGive = (summary['yetToGive'] as num?)?.toDouble() ?? yetToGive;
    } catch (_) {}

    if (_dirtySinceLoad) return;

    // 5. Determine start date: when the user actually started using this
    final startKey = _determineStartKey(
      currentKey: currentKey,
      remotePeriods: remotePeriods,
      profileCreatedAt: profileCreatedAt,
    );
    _startedYear = startKey ~/ 100;
    _startedMonth = startKey % 100;

    // 6. Build periods: from when the user started using this up to current month
    final periodMap = _buildPeriodMap(
      sourcePeriods: [...state.history, ...remotePeriods],
      currentPeriod: remoteCurrent ?? state.current.valueOrNull,
      startKey: startKey,
      now: now,
    );

    final allPeriods = periodMap.values.map((p) {
      final isCurr = (p.month == currentMonth && p.year == currentYear);
      return p.copyWith(isCurrent: isCurr);
    }).toList();

    allPeriods.sort((a, b) {
      if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
      return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
    });

    final currentPeriod = allPeriods.firstWhere(
      (p) => p.isCurrent,
      orElse: () => allPeriods.first,
    );

    final currentTxns = _transactionsForPeriod(currentPeriod);

    state = CashFlowState(
      current: AsyncValue.data(currentPeriod),
      history: allPeriods,
      transactions: currentTxns.isNotEmpty ? currentTxns : state.transactions,
      debts: debts,
      yetToReceive: yetToReceive,
      yetToGive: yetToGive,
    );
    await _persist();
    if (currentPeriod.id.isNotEmpty && !currentPeriod.id.startsWith('local_')) {
      await _loadTransactions(currentPeriod.id, currentPeriod);
    }
  }

  int _determineStartKey({
    required int currentKey,
    required List<CashFlowPeriodModel> remotePeriods,
    DateTime? profileCreatedAt,
  }) {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevKey = prevYear * 100 + prevMonth;

    // Start with the previous month (August) as the guaranteed starting point
    final List<int> candidates = [prevKey];

    // 1. Real backend periods
    for (final p in remotePeriods) {
      if (p.isAuthentic(currentKey: currentKey)) {
        candidates.add(p.year * 100 + p.month);
      }
    }

    // 2. Existing history periods that are authentic
    for (final p in state.history) {
      if (p.isAuthentic(
          transactions: _allTransactions, currentKey: currentKey)) {
        candidates.add(p.year * 100 + p.month);
      }
    }

    // 3. Current period if authentic
    final c = state.current.valueOrNull;
    if (c != null &&
        c.isAuthentic(
            transactions: _allTransactions, currentKey: currentKey)) {
      candidates.add(c.year * 100 + c.month);
    }

    // 4. Authentic transactions recorded by user
    for (final t in _allTransactions) {
      final parts = t.date.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          candidates.add(y * 100 + m);
        }
      }
    }

    // 5. Account creation date if earlier
    if (profileCreatedAt != null) {
      final profileStartKey =
          profileCreatedAt.year * 100 + profileCreatedAt.month;
      candidates.add(profileStartKey);
    }

    // 6. Explicitly set started period (e.g. from setupFirstPeriod)
    if (_startedYear != null && _startedMonth != null) {
      final explicitKey = _startedYear! * 100 + _startedMonth!;
      candidates.add(explicitKey);
    }

    int earliest = candidates.isNotEmpty
        ? candidates.reduce((a, b) => a < b ? a : b)
        : prevKey;

    // Never in the future
    if (earliest > currentKey) {
      earliest = currentKey;
    }

    return earliest;
  }

  Map<int, CashFlowPeriodModel> _buildPeriodMap({
    required List<CashFlowPeriodModel> sourcePeriods,
    CashFlowPeriodModel? currentPeriod,
    required int startKey,
    required DateTime now,
  }) {
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentKey = currentYear * 100 + currentMonth;

    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
    final prevKey = prevYear * 100 + prevMonth;

    final Map<int, CashFlowPeriodModel> periodMap = {};

    // 1. Seed existing periods from sources (ONLY if between startKey and currentKey)
    for (final p in sourcePeriods) {
      final key = p.year * 100 + p.month;
      if (key >= startKey && key <= currentKey) {
        if (!periodMap.containsKey(key) ||
            p.isAuthentic(
                transactions: _allTransactions, currentKey: currentKey)) {
          periodMap[key] = p;
        }
      }
    }
    if (currentPeriod != null) {
      final cKey = currentPeriod.year * 100 + currentPeriod.month;
      if (cKey >= startKey && cKey <= currentKey) {
        periodMap[cKey] = currentPeriod;
      }
    }

    // 2. Guarantee Previous Month (August) exists
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

    // 3. Guarantee Current Month (September) exists
    if (!periodMap.containsKey(currentKey)) {
      periodMap[currentKey] = CashFlowPeriodModel(
        id: 'local_${currentMonth}_$currentYear',
        month: currentMonth,
        year: currentYear,
        openingBank: 0,
        openingCash: 0,
        openingCreditCard: 0,
        openingDebt: 0,
        closingBank: 0,
        closingCash: 0,
        closingCreditCard: 0,
        isCurrent: true,
      );
    }

    // 3. Guarantee all months from startKey up to currentKey exist
    final startYear = startKey ~/ 100;
    final startMonth = startKey % 100;
    var cursor = DateTime(startYear, startMonth, 1);
    final currentEnd = DateTime(currentYear, currentMonth, 1);

    while (!cursor.isAfter(currentEnd)) {
      final y = cursor.year;
      final m = cursor.month;
      final key = y * 100 + m;
      final isCurr = (y == currentYear && m == currentMonth);

      if (!periodMap.containsKey(key)) {
        periodMap[key] = CashFlowPeriodModel(
          id: isCurr ? 'local_${m}_$y' : 'period_${m}_$y',
          month: m,
          year: y,
          openingBank: 0,
          openingCash: 0,
          openingCreditCard: 0,
          openingDebt: 0,
          closingBank: 0,
          closingCash: 0,
          closingCreditCard: 0,
          isCurrent: isCurr,
        );
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    // Strictly enforce no months before startKey or after currentKey
    periodMap.removeWhere((k, _) => k < startKey || k > currentKey);

    // 4. Compute chronological balance rollover
    final sortedKeys = periodMap.keys.toList()..sort();
    double carryBank = 0;
    double carryCash = 0;
    double carryCredit = 0;
    double carryDebt = 0;
    bool hasPrevious = false;

    for (final k in sortedKeys) {
      var p = periodMap[k]!;
      if (hasPrevious) {
        if (p.openingBank == 0 &&
            p.openingCash == 0 &&
            p.openingCreditCard == 0 &&
            p.openingDebt == 0) {
          p = p.copyWith(
            openingBank: carryBank,
            openingCash: carryCash,
            openingCreditCard: carryCredit,
            openingDebt: carryDebt,
          );
        }
      }
      final txns = _transactionsForPeriod(p);
      final recomputed = _recomputePeriodWithTxns(p, txns);
      periodMap[k] = recomputed;
      carryBank = recomputed.closingBank;
      carryCash = recomputed.closingCash;
      carryCredit = recomputed.closingCreditCard;
      carryDebt = recomputed.openingDebt;
      hasPrevious = true;
    }

    return periodMap;
  }

  Future<void> _loadTransactions(String periodId,
      [CashFlowPeriodModel? targetPeriod]) async {
    try {
      final response = await DioClient().dio.get('/cashflow/transactions',
          queryParameters: {'periodId': periodId});
      final txns = ((response.data['data'] ?? response.data) as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!_dirtySinceLoad) {
        _mergeTransactions(txns);
        final periodToUse = targetPeriod ?? state.current.valueOrNull;
        final periodTxns =
            periodToUse != null ? _transactionsForPeriod(periodToUse) : txns;
        state = state.copyWith(transactions: periodTxns);
        await _persist();
      }
    } catch (_) {}
  }

  /// View a past month's data and transactions (read-only history).
  Future<void> selectPeriod(CashFlowPeriodModel period) async {
    final periodTxns = _transactionsForPeriod(period);
    final recomputed = _recomputePeriodWithTxns(period, periodTxns);
    final exists = state.history.any((p) =>
        p.id == period.id ||
        (p.month == period.month && p.year == period.year));
    final updatedHistory = exists
        ? state.history
            .map((p) => (p.id == period.id ||
                    (p.month == period.month && p.year == period.year))
                ? recomputed
                : p)
            .toList()
        : [...state.history, recomputed];
    state = state.copyWith(
      transactions: periodTxns,
      history: updatedHistory,
    );
    if (period.id.isNotEmpty &&
        !period.id.startsWith('local_') &&
        !period.id.startsWith('period_')) {
      await _loadTransactions(period.id, period);
    }
  }

  /// Back to the live month after browsing history.
  Future<void> backToCurrent() async {
    final current = state.current.valueOrNull;
    if (current != null) {
      final currentTxns = _transactionsForPeriod(current);
      final recomputed = _recomputePeriodWithTxns(current, currentTxns);
      state = state.copyWith(
        current: AsyncValue.data(recomputed),
        transactions: currentTxns,
      );
      if (current.id.isNotEmpty && !current.id.startsWith('local_')) {
        await _loadTransactions(current.id, current);
      }
    }
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
    _startedYear = year;
    _startedMonth = month;
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
    _allTransactions = [txn, ..._allTransactions.where((t) => t.id != txn.id)];
    final currentPeriod = state.current.valueOrNull;
    final currentTxns = currentPeriod != null
        ? _transactionsForPeriod(currentPeriod)
        : [txn, ...state.transactions];
    final updatedCurrent = currentPeriod == null
        ? state.current
        : AsyncValue.data(_recomputePeriodWithTxns(currentPeriod, currentTxns));

    final updatedHistory = state.history.map((p) {
      final pTxns = _transactionsForPeriod(p);
      return _recomputePeriodWithTxns(p, pTxns);
    }).toList();

    // Optimistic insert so the UI reacts instantly, offline included.
    state = state.copyWith(
      current: updatedCurrent,
      history: updatedHistory,
      transactions: currentTxns,
    );
    try {
      final response = await DioClient()
          .dio
          .post('/cashflow/transactions', data: txn.toCreateJson());
      final savedData =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final saved = TransactionModel.fromJson(savedData);
      _allTransactions =
          _allTransactions.map((t) => t.id == txn.id ? saved : t).toList();
      final freshTxns = currentPeriod != null
          ? _transactionsForPeriod(currentPeriod)
          : state.transactions.map((t) => t.id == txn.id ? saved : t).toList();
      final refreshedHistory = state.history.map((p) {
        final pTxns = _transactionsForPeriod(p);
        return _recomputePeriodWithTxns(p, pTxns);
      }).toList();

      state = state.copyWith(
        current: currentPeriod == null
            ? state.current
            : AsyncValue.data(
                _recomputePeriodWithTxns(currentPeriod, freshTxns)),
        history: refreshedHistory,
        transactions: freshTxns,
      );
      await _refreshTotals();
      await _persist();
    } catch (_) {
      // Keep the optimistic entry; totals refresh on next successful sync.
      final temp = txn.copyWith(id: txn.id);
      _allTransactions = [
        temp,
        ..._allTransactions.where((t) => t.id != txn.id)
      ];
      final fallbackTxns = currentPeriod != null
          ? _transactionsForPeriod(currentPeriod)
          : [temp, ...state.transactions.where((t) => t.id != txn.id)];
      final period = state.current.valueOrNull;
      final fallbackHistory = state.history.map((p) {
        final pTxns = _transactionsForPeriod(p);
        return _recomputePeriodWithTxns(p, pTxns);
      }).toList();

      state = state.copyWith(
        current: period == null
            ? state.current
            : AsyncValue.data(_recomputePeriodWithTxns(period, fallbackTxns)),
        history: fallbackHistory,
        transactions: fallbackTxns,
      );
      await _persist();

      // Enqueue to background sync manager
      await SyncManager.instance.enqueue(
        SyncAction(
          type: SyncActionType.createCashFlowTransaction,
          endpoint: '/cashflow/transactions',
          method: 'POST',
          payload: txn.toCreateJson(),
          tempId: txn.id,
        ),
      );
    }
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    _dirtySinceLoad = true;
    _allTransactions =
        _allTransactions.map((t) => t.id == txn.id ? txn : t).toList();
    final beforePeriod = state.current.valueOrNull;
    final updatedTxns = beforePeriod != null
        ? _transactionsForPeriod(beforePeriod)
        : state.transactions.map((t) => t.id == txn.id ? txn : t).toList();
    final updatedCurrent = beforePeriod == null
        ? state.current
        : AsyncValue.data(_recomputePeriodWithTxns(beforePeriod, updatedTxns));
    final updatedHistory = state.history.map((p) {
      final pTxns = _transactionsForPeriod(p);
      return _recomputePeriodWithTxns(p, pTxns);
    }).toList();

    state = state.copyWith(
      current: updatedCurrent,
      history: updatedHistory,
      transactions: updatedTxns,
    );
    await _persist();

    // Check if it is a backend ID
    final isBackendId = txn.id.length == 24 &&
        !txn.id.startsWith('local_') &&
        !txn.id.startsWith('temp_');

    try {
      if (isBackendId) {
        final response = await DioClient().dio.patch(
              '/cashflow/transactions/${txn.id}',
              data: txn.toCreateJson(),
            );
        final savedData =
            (response.data['data'] ?? response.data) as Map<String, dynamic>;
        final saved = TransactionModel.fromJson(savedData);
        _allTransactions =
            _allTransactions.map((t) => t.id == txn.id ? saved : t).toList();
        final refreshedTxns = beforePeriod != null
            ? _transactionsForPeriod(beforePeriod)
            : state.transactions
                .map((t) => t.id == txn.id ? saved : t)
                .toList();
        final refreshedHistory = state.history.map((p) {
          final pTxns = _transactionsForPeriod(p);
          return _recomputePeriodWithTxns(p, pTxns);
        }).toList();

        state = state.copyWith(
          current: beforePeriod == null
              ? state.current
              : AsyncValue.data(
                  _recomputePeriodWithTxns(beforePeriod, refreshedTxns)),
          history: refreshedHistory,
          transactions: refreshedTxns,
        );
      }
      await _refreshTotals();
      await _persist();
    } catch (_) {
      if (isBackendId) {
        await SyncManager.instance.enqueue(
          SyncAction(
            type: SyncActionType.updateCashFlowTransaction,
            endpoint: '/cashflow/transactions/${txn.id}',
            method: 'PATCH',
            payload: txn.toCreateJson(),
          ),
        );
      }
      await _refreshTotals();
      await _persist();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _dirtySinceLoad = true;
    _allTransactions = _allTransactions.where((t) => t.id != id).toList();
    final beforePeriod = state.current.valueOrNull;
    final updatedTxns = beforePeriod != null
        ? _transactionsForPeriod(beforePeriod)
        : state.transactions.where((t) => t.id != id).toList();
    final updatedCurrent = beforePeriod == null
        ? state.current
        : AsyncValue.data(_recomputePeriodWithTxns(beforePeriod, updatedTxns));
    final updatedHistory = state.history.map((p) {
      final pTxns = _transactionsForPeriod(p);
      return _recomputePeriodWithTxns(p, pTxns);
    }).toList();

    // 1. Optimistic delete locally so UI updates instantly
    state = state.copyWith(
      current: updatedCurrent,
      history: updatedHistory,
      transactions: updatedTxns,
    );
    await _persist();

    // 2. If it's a local/temporary ID, it doesn't exist on backend
    final isBackendId =
        id.length == 24 && !id.startsWith('local_') && !id.startsWith('temp_');

    try {
      if (isBackendId) {
        await DioClient().dio.delete('/cashflow/transactions/$id');
      }
      await _refreshTotals();
    } catch (e) {
      if (isBackendId) {
        // Enqueue to background sync manager
        await SyncManager.instance.enqueue(
          SyncAction(
            type: SyncActionType.deleteCashFlowTransaction,
            endpoint: '/cashflow/transactions/$id',
            method: 'DELETE',
          ),
        );
      }
      await _refreshTotals();
    }
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
      debts:
          state.debts.map((d) => d.id == entry.id ? updatedLocal : d).toList(),
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
    await _persist();
    final isBackendId =
        id.length == 24 && !id.startsWith('local_') && !id.startsWith('temp_');
    try {
      if (isBackendId) {
        await DioClient().dio.delete('/cashflow/debts/$id');
      }
      await _refreshDebtSummary();
    } catch (_) {
      await _refreshDebtSummary();
    }
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

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      final currentKey = currentYear * 100 + currentMonth;

      final profile = await UserLocalCache.instance.getProfile();
      final profileCreatedAt = profile?.createdAt;

      final startKey = _determineStartKey(
        currentKey: currentKey,
        remotePeriods: periods,
        profileCreatedAt: profileCreatedAt,
      );
      _startedYear = startKey ~/ 100;
      _startedMonth = startKey % 100;

      final periodMap = _buildPeriodMap(
        sourcePeriods: [...periods, ...state.history],
        currentPeriod: freshCurrent,
        startKey: startKey,
        now: now,
      );

      final allPeriods = periodMap.values.map((p) {
        final isCurr = (p.month == currentMonth && p.year == currentYear);
        return p.copyWith(isCurrent: isCurr);
      }).toList()
        ..sort((a, b) {
          if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
          return (b.year * 100 + b.month).compareTo(a.year * 100 + a.month);
        });

      final effectiveCurrent = allPeriods.firstWhere(
        (p) => p.isCurrent,
        orElse: () => allPeriods.first,
      );
      state = state.copyWith(
        current: AsyncValue.data(effectiveCurrent),
        history: allPeriods,
      );
      await _persist();
    } catch (_) {}
  }

  Future<void> _refreshDebtSummary() async {
    try {
      final response = await DioClient().dio.get('/cashflow/debts/summary');
      final s =
          (response.data['data'] ?? response.data) as Map<String, dynamic>;
      state = state.copyWith(
        yetToReceive: (s['yetToReceive'] as num?)?.toDouble() ?? 0,
        yetToGive: (s['yetToGive'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {}
  }

  CashFlowState _stateFromCacheJson(Map<String, dynamic> json) {
    _startedYear = json['startedYear'] as int?;
    _startedMonth = json['startedMonth'] as int?;

    _allTransactions = ((json['allTransactions'] as List?) ??
            (json['transactions'] as List?) ??
            const [])
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final now = DateTime.now();
    final currentKey = now.year * 100 + now.month;
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevKey = prevYear * 100 + prevMonth;

    // Discard any dummy synthetic periods that have no authentic user activity
    // (preserving current and previous month)
    final cleanHistory = ((json['history'] as List?) ?? const [])
        .map((e) => CashFlowPeriodModel.fromJson(e as Map<String, dynamic>,
            isCurrent: false))
        .where((p) {
          final k = p.year * 100 + p.month;
          if (k == currentKey || k == prevKey) return true;
          return p.isAuthentic(
              transactions: _allTransactions, currentKey: currentKey);
        })
        .toList();

    return CashFlowState(
      current: json['current'] == null
          ? const AsyncValue.loading()
          : AsyncValue.data(
              CashFlowPeriodModel.fromJson(
                (json['current'] as Map<String, dynamic>)..['isCurrent'] = null,
                isCurrent: true,
              ),
            ),
      history: cleanHistory,
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
    if (current != null) {
      try {
        await HomeWidgetService.instance.syncCashFlowData(period: current);
      } catch (_) {}
    }
    await JsonFileCache.write(_cacheName, {
      'current': current?.toJson(),
      'history': state.history.map((p) => p.toJson()).toList(),
      'transactions': state.transactions.map((t) => t.toJson()).toList(),
      'allTransactions': _allTransactions.map((t) => t.toJson()).toList(),
      'debts': state.debts.map(toDebtJson).toList(),
      'yetToReceive': state.yetToReceive,
      'yetToGive': state.yetToGive,
      'startedYear': _startedYear,
      'startedMonth': _startedMonth,
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

final cashFlowProvider =
    StateNotifierProvider<CashFlowNotifier, CashFlowState>((ref) {
  return CashFlowNotifier();
});
