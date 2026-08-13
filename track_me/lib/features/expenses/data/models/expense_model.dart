import 'expense_category.dart';
import 'payment_method.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? time;
  final String? notes;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.time,
    this.notes,
    required this.createdAt,
  });

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? time,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromApi(json['category'] as String? ?? 'OTHER'),
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String? ?? 'CASH'),
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category.apiValue,
      'paymentMethod': paymentMethod.apiValue,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'time': time,
      'notes': notes,
    };
  }
}
