import 'package:isar/isar.dart';

part 'budget_local_model.g.dart';

@collection
class BudgetLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String budgetId;

  late int month;
  late int year;
  late double monthlyIncome;
  late double savingsTarget;
  late double spendableBudget;
  late double dailyGoal;
  late int daysInMonth;
  bool isSynced = false;
  late DateTime createdAt;
}
