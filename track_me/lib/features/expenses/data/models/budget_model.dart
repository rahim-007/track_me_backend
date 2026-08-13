class BudgetModel {
  final String? id;
  final int month;
  final int year;
  final double monthlyIncome;
  final double savingsTarget;
  final double spendableBudget;
  final double dailyGoal;
  final int daysInMonth;
  final DateTime? createdAt;

  BudgetModel({
    this.id,
    required this.month,
    required this.year,
    required this.monthlyIncome,
    required this.savingsTarget,
    required this.spendableBudget,
    required this.dailyGoal,
    required this.daysInMonth,
    this.createdAt,
  });

  BudgetModel copyWith({
    String? id,
    int? month,
    int? year,
    double? monthlyIncome,
    double? savingsTarget,
    double? spendableBudget,
    double? dailyGoal,
    int? daysInMonth,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsTarget: savingsTarget ?? this.savingsTarget,
      spendableBudget: spendableBudget ?? this.spendableBudget,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String?,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
      savingsTarget: (json['savingsTarget'] as num).toDouble(),
      spendableBudget: (json['spendableBudget'] as num).toDouble(),
      dailyGoal: (json['dailyGoal'] as num).toDouble(),
      daysInMonth: (json['daysInMonth'] as num).toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'savingsTarget': savingsTarget,
      'month': month,
      'year': year,
    };
  }
}
