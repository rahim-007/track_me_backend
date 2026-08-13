import 'package:isar/isar.dart';

part 'expense_local_model.g.dart';

@collection
class ExpenseLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String expenseId;

  late String title;
  late double amount;
  late String category;
  late String paymentMethod;
  late DateTime date;
  String? time;
  String? notes;
  bool isSynced = false;
  late DateTime createdAt;
}
