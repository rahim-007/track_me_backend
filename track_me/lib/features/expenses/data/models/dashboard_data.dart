import 'budget_model.dart';
import 'expense_model.dart';

class DashboardData {
  final BudgetModel? budget;
  final TodayData today;
  final MonthData month;
  final List<ExpenseModel> recentTransactions;

  DashboardData({
    this.budget,
    required this.today,
    required this.month,
    required this.recentTransactions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final budgetJson = json['budget'];
    final todayJson = json['today'] as Map<String, dynamic>? ?? {};
    final monthJson = json['month'] as Map<String, dynamic>? ?? {};
    final txnList = json['recentTransactions'] as List<dynamic>? ?? [];

    return DashboardData(
      budget: budgetJson != null
          ? BudgetModel.fromJson(budgetJson as Map<String, dynamic>)
          : null,
      today: TodayData.fromJson(todayJson),
      month: MonthData.fromJson(monthJson),
      recentTransactions: txnList
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TodayData {
  final List<ExpenseModel> expenses;
  final double total;
  final double dailyGoal;
  final double profitLoss;
  final String status; // PROFIT, LOSS, ON_TRACK

  TodayData({
    required this.expenses,
    required this.total,
    required this.dailyGoal,
    required this.profitLoss,
    required this.status,
  });

  factory TodayData.fromJson(Map<String, dynamic> json) {
    final expList = json['expenses'] as List<dynamic>? ?? [];
    return TodayData(
      expenses: expList
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      dailyGoal: (json['dailyGoal'] as num?)?.toDouble() ?? 0.0,
      profitLoss: (json['profitLoss'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ON_TRACK',
    );
  }
}

class MonthData {
  final double totalExpenses;
  final int transactionCount;
  final double remainingBudget;
  final double currentSavings;
  final double savingsProgress;
  final double savingsRate;
  final double averageDailyExpense;
  final double monthlyProfit;
  final double monthlyLoss;

  MonthData({
    required this.totalExpenses,
    required this.transactionCount,
    required this.remainingBudget,
    required this.currentSavings,
    required this.savingsProgress,
    required this.savingsRate,
    required this.averageDailyExpense,
    required this.monthlyProfit,
    required this.monthlyLoss,
  });

  factory MonthData.fromJson(Map<String, dynamic> json) {
    return MonthData(
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble() ?? 0.0,
      currentSavings: (json['currentSavings'] as num?)?.toDouble() ?? 0.0,
      savingsProgress: (json['savingsProgress'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
      averageDailyExpense: (json['averageDailyExpense'] as num?)?.toDouble() ?? 0.0,
      monthlyProfit: (json['monthlyProfit'] as num?)?.toDouble() ?? 0.0,
      monthlyLoss: (json['monthlyLoss'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
