class ExtraIncomeModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  ExtraIncomeModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  factory ExtraIncomeModel.fromJson(Map<String, dynamic> json) {
    return ExtraIncomeModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
  }
}
