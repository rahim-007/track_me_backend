import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/budget_model.dart';
import '../data/models/expense_model.dart';
import '../data/models/dashboard_data.dart';

enum ExpenseFilterType {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension ExpenseFilterTypeExtension on ExpenseFilterType {
  String get apiValue {
    switch (this) {
      case ExpenseFilterType.today: return 'today';
      case ExpenseFilterType.yesterday: return 'yesterday';
      case ExpenseFilterType.thisWeek: return 'thisWeek';
      case ExpenseFilterType.thisMonth: return 'thisMonth';
      case ExpenseFilterType.lastMonth: return 'lastMonth';
      case ExpenseFilterType.custom: return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseFilterType.today: return 'Today';
      case ExpenseFilterType.yesterday: return 'Yesterday';
      case ExpenseFilterType.thisWeek: return 'This Week';
      case ExpenseFilterType.thisMonth: return 'This Month';
      case ExpenseFilterType.lastMonth: return 'Last Month';
      case ExpenseFilterType.custom: return 'Custom';
    }
  }
}

final expenseFilterProvider = StateProvider<ExpenseFilterType>((ref) => ExpenseFilterType.thisMonth);

final expenseCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

// ─── Budget State ────────────────────────────────────────────────────────────

typedef BudgetState = AsyncValue<BudgetModel?>;

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier() : super(const AsyncValue.loading()) {
    loadCurrentBudget();
  }

  Future<void> loadCurrentBudget() async {
    // Sticky loading: keep showing the current budget while refreshing so the
    // screen never flashes a full blank/white spinner during a reload.
    state = const AsyncValue<BudgetModel?>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final response = await client.dio.get('/expenses/budget/current');
      if (!mounted) return;
      if (response.data != null && response.data['data'] != null) {
        state = AsyncValue.data(
          BudgetModel.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      if (!mounted) return;
      state = const AsyncValue.data(null);
    }
  }

  Future<BudgetModel?> saveBudget({
    required double monthlyIncome,
    required double savingsTarget,
    int? month,
    int? year,
  }) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/expenses/budget', data: {
        'monthlyIncome': monthlyIncome,
        'savingsTarget': savingsTarget,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      final budget = BudgetModel.fromJson(response.data['data'] as Map<String, dynamic>);
      if (!mounted) return null;
      state = AsyncValue.data(budget);
      return budget;
    } catch (e) {
      // Optimistic: compute locally
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final days = DateTime(y, m + 1, 0).day;
      // Match the backend: spread the goal over remaining days when the budget
      // is being set up for the current month (e.g. started on Aug 16).
      final remaining = (now.year == y && now.month == m)
          ? (days - now.day + 1).clamp(1, days)
          : days;
      final spendable = monthlyIncome - savingsTarget;
      final budget = BudgetModel(
        month: m,
        year: y,
        monthlyIncome: monthlyIncome,
        savingsTarget: savingsTarget,
        spendableBudget: spendable,
        dailyGoal: remaining > 0 ? spendable / remaining : 0,
        daysInMonth: days,
      );
      if (!mounted) return null;
      state = AsyncValue.data(budget);
      return budget;
    }
  }
}

// ─── Dashboard State ─────────────────────────────────────────────────────────

typedef DashboardState = AsyncValue<DashboardData>;

class ExpenseDashboardNotifier extends StateNotifier<DashboardState> {
  ExpenseDashboardNotifier() : super(const AsyncValue.loading());

  String? _lastFilter;
  String? _lastStartDate;
  String? _lastEndDate;

  Future<void> loadDashboard({String? filter, String? startDate, String? endDate}) async {
    _lastFilter = filter;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    // Sticky loading: keep the previous data visible while refreshing.
    state = const AsyncValue<DashboardData>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final response = await client.dio.get('/expenses/dashboard', queryParameters: {
        'today': todayStr,
        if (filter != null) 'filter': filter,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      });
      final data = DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
      if (!mounted) return;
      state = AsyncValue.data(data);
    } catch (e) {
      if (!mounted) return;
      state = AsyncValue.data(_emptyDashboard());
    }
  }

  /// Reload using the last requested filter. Used after saves/edits so the
  /// screen keeps showing current data instead of a full-screen spinner.
  Future<void> reload() =>
      loadDashboard(filter: _lastFilter, startDate: _lastStartDate, endDate: _lastEndDate);

  DashboardData _emptyDashboard() {
    return DashboardData(
      today: TodayData(
        expenses: [],
        total: 0,
        dailyGoal: 0,
        profitLoss: 0,
        status: 'ON_TRACK',
      ),
      month: MonthData(
        totalExpenses: 0,
        transactionCount: 0,
        remainingBudget: 0,
        currentSavings: 0,
        savingsProgress: 0,
        savingsRate: 0,
        averageDailyExpense: 0,
        monthlyProfit: 0,
        monthlyLoss: 0,
      ),
      recentTransactions: [],
    );
  }
}

// ─── Expenses List State ─────────────────────────────────────────────────────

typedef ExpensesListState = AsyncValue<List<ExpenseModel>>;

class ExpensesListNotifier extends StateNotifier<ExpensesListState> {
  ExpensesListNotifier() : super(const AsyncValue.loading());

  /// Loads transactions from the API.
  ///
  /// By default (no month/year) it fetches ALL transactions for the user,
  /// newest first — this is the single source of truth used by the
  /// "All Transactions" screen and kept in sync with the dashboard.
  /// A month/year can optionally be passed to scope the query to that month.
  Future<void> loadExpenses({int? month, int? year}) async {
    // Sticky loading: keep the current list visible while refreshing.
    state = const AsyncValue<List<ExpenseModel>>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final response = await client.dio.get('/expenses', queryParameters: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      final list = (response.data['data'] as List)
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (_) {
      if (!mounted) return;
      state = const AsyncValue.data([]);
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/expenses', data: expense.toJson());
      final newExpense = ExpenseModel.fromJson(response.data['data'] as Map<String, dynamic>);
      if (!mounted) return;
      state.whenData((expenses) {
        state = AsyncValue.data([newExpense, ...expenses]);
      });
    } catch (_) {
      // Optimistic
      final temp = expense.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      state.whenData((expenses) {
        state = AsyncValue.data([temp, ...expenses]);
      });
    }
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      final client = DioClient();
      await client.dio.patch('/expenses/$id', data: data);
      // Reload to get fresh data
      await loadExpenses();
    } catch (_) {}
  }

  Future<void> deleteExpense(String id) async {
    state.whenData((expenses) {
      state = AsyncValue.data(expenses.where((e) => e.id != id).toList());
    });
    try {
      final client = DioClient();
      await client.dio.delete('/expenses/$id');
    } catch (_) {}
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>(
  (ref) => BudgetNotifier(),
);

final expenseDashboardProvider =
    StateNotifierProvider<ExpenseDashboardNotifier, DashboardState>((ref) {
  final notifier = ExpenseDashboardNotifier();

  // NOTE: we deliberately do NOT watch budgetProvider/expensesListProvider here.
  // Watching them would recreate this notifier on every save and flash a full-
  // screen spinner. Instead the screens call notifier.reload() after changes.
  final filter = ref.watch(expenseFilterProvider);
  final customRange = ref.watch(expenseCustomRangeProvider);
  
  String? startDate;
  String? endDate;
  if (filter == ExpenseFilterType.custom && customRange != null) {
    startDate = '${customRange.start.year}-${customRange.start.month.toString().padLeft(2, '0')}-${customRange.start.day.toString().padLeft(2, '0')}';
    endDate = '${customRange.end.year}-${customRange.end.month.toString().padLeft(2, '0')}-${customRange.end.day.toString().padLeft(2, '0')}';
  }
  
  notifier.loadDashboard(
    filter: filter.apiValue,
    startDate: startDate,
    endDate: endDate,
  );
  
  return notifier;
});

final expensesListProvider =
    StateNotifierProvider<ExpensesListNotifier, ExpensesListState>(
  (ref) => ExpensesListNotifier(),
);

final todayTotalProvider = Provider<double>((ref) {
  return ref.watch(expenseDashboardProvider).when(
        data: (d) => d.today.total,
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

final dailyGoalProvider = Provider<double>((ref) {
  return ref.watch(budgetProvider).when(
        data: (b) => b?.dailyGoal ?? 0.0,
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});
