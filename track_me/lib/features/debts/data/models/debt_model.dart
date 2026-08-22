/// A single payment recorded against a debt.
class DebtPaymentModel {
  final String id;
  final double amount;
  final DateTime paymentDate;
  final String? note;

  const DebtPaymentModel({
    required this.id,
    required this.amount,
    required this.paymentDate,
    this.note,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      note: json['note'] as String?,
    );
  }
}

/// A debt / loan with derived totals (totalPaid, remainingBalance) that the
/// backend computes as originalAmount - SUM(payments).
class DebtModel {
  final String id;
  final String name;
  final double originalAmount;
  final String? lenderName;
  final DateTime? dueDate;
  final double? installmentAmount;
  final String? description;
  final String status; // 'ACTIVE' | 'PAID'
  final double totalPaid;
  final double remainingBalance;
  final DateTime createdAt;
  final List<DebtPaymentModel> payments;

  const DebtModel({
    required this.id,
    required this.name,
    required this.originalAmount,
    this.lenderName,
    this.dueDate,
    this.installmentAmount,
    this.description,
    required this.status,
    required this.totalPaid,
    required this.remainingBalance,
    required this.createdAt,
    this.payments = const [],
  });

  bool get isPaid => status == 'PAID';

  /// 0.0 → 1.0 fraction of the original amount paid off.
  double get progress {
    if (originalAmount <= 0) return 0.0;
    return (totalPaid / originalAmount).clamp(0.0, 1.0);
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0.0,
      lenderName: json['lenderName'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      installmentAmount: (json['installmentAmount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      payments: (json['payments'] as List?)
              ?.map((p) => DebtPaymentModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
