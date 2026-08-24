/// Models for the rebuilt Cash Flow Tracker.
///
/// A [CashFlowPeriodModel] is one calendar month of the user's money life. It
/// carries the four opening balances; closing balances are always computed
/// from transactions (server and client agree on this rule). Transactions are
/// reset every month; debt ledger entries ([DebtEntryModel]) are continuous.
library;

enum TxnKind { income, outflow }

/// Which account pocket a transaction posts to (INCOME) or from (OUTFLOW).
/// [bank]       = bank account — default / backward-compat when null.
/// [cash]       = physical cash in hand.
/// [creditCard] = credit card (outflows increase debt).
enum CashFlowAccount {
  bank('BANK', '🏦 Bank'),
  cash('CASH', '💵 Cash'),
  creditCard('CREDIT_CARD', '💳 Credit Card');

  final String apiValue;
  final String label;
  const CashFlowAccount(this.apiValue, this.label);

  static CashFlowAccount fromApi(String? value) {
    switch (value) {
      case 'CASH':
        return CashFlowAccount.cash;
      case 'CREDIT_CARD':
        return CashFlowAccount.creditCard;
      // null or 'BANK' → BANK (backward compat)
      default:
        return CashFlowAccount.bank;
    }
  }
}

/// Income categories — ESBI quadrant + Gift.
enum IncomeCategory {
  E('E', 'Employee', 'Salary from a job'),
  S('S', 'Self-Employed', 'Freelance & consulting'),
  B('B', 'Business', 'Business ownership income'),
  I('I', 'Investor', 'Interest, dividends, returns'),
  G('G', 'Gift', 'Received, no return expected');

  final String letter;
  final String label;
  final String description;
  const IncomeCategory(this.letter, this.label, this.description);
}

/// Outflow categories — ESDI + Donation.
// The 'DO' letter is fixed by the product spec (Donation), not a typo.
// ignore: constant_identifier_names
enum OutflowCategory {
  E('E', 'Expense', 'Day-to-day spending'),
  S('S', 'Savings', 'Money set aside'),
  D('D', 'Debt Repayment', 'Paying down what you owe'),
  I('I', 'Investing', 'Buying assets'),
  // The 'DO' letter is fixed by the product spec (Donation), not a typo.
  // ignore: constant_identifier_names
  DO('DO', 'Donation', 'Given, no return expected');

  final String letter;
  final String label;
  final String description;
  const OutflowCategory(this.letter, this.label, this.description);
}

class CashFlowPeriodModel {
  final String id;
  final int month;
  final int year;
  final double openingBank;
  final double openingCash;
  final double openingCreditCard;
  final double openingDebt;

  // Derived server-side (computed, never stored).
  final double totalIncome;
  final double totalOutflow;
  final double netCashFlow;
  final double closingBank;
  final double closingCash;
  final double closingCreditCard;
  final Map<String, double> incomeByCategory;
  final Map<String, double> outflowByCategory;
  final bool isCurrent;

  const CashFlowPeriodModel({
    required this.id,
    required this.month,
    required this.year,
    required this.openingBank,
    required this.openingCash,
    required this.openingCreditCard,
    required this.openingDebt,
    this.totalIncome = 0,
    this.totalOutflow = 0,
    this.netCashFlow = 0,
    this.closingBank = 0,
    this.closingCash = 0,
    this.closingCreditCard = 0,
    this.incomeByCategory = const {},
    this.outflowByCategory = const {},
    this.isCurrent = false,
  });

  factory CashFlowPeriodModel.fromJson(
    Map<String, dynamic> json, {
    required bool isCurrent,
  }) {
    return CashFlowPeriodModel(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      openingBank: (json['openingBank'] as num?)?.toDouble() ?? 0,
      openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0,
      openingCreditCard: (json['openingCreditCard'] as num?)?.toDouble() ?? 0,
      openingDebt: (json['openingDebt'] as num?)?.toDouble() ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
      totalOutflow: (json['totalOutflow'] as num?)?.toDouble() ?? 0,
      netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0,
      closingBank: (json['closingBank'] as num?)?.toDouble() ??
          (json['openingBank'] as num?)?.toDouble() ??
          0,
      // closingCash is now returned from the backend.
      // Fall back to openingCash for cached/legacy data that predates this field.
      closingCash: (json['closingCash'] as num?)?.toDouble() ??
          (json['openingCash'] as num?)?.toDouble() ??
          0,
      closingCreditCard: (json['closingCreditCard'] as num?)?.toDouble() ??
          (json['openingCreditCard'] as num?)?.toDouble() ??
          0,
      incomeByCategory:
          ((json['incomeByCategory'] as Map<String, dynamic>?) ?? const {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
      outflowByCategory:
          ((json['outflowByCategory'] as Map<String, dynamic>?) ?? const {})
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
      isCurrent: isCurrent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month,
        'year': year,
        'openingBank': openingBank,
        'openingCash': openingCash,
        'openingCreditCard': openingCreditCard,
        'openingDebt': openingDebt,
        'totalIncome': totalIncome,
        'totalOutflow': totalOutflow,
        'netCashFlow': netCashFlow,
        'closingBank': closingBank,
        'closingCash': closingCash,
        'closingCreditCard': closingCreditCard,
        'incomeByCategory': incomeByCategory,
        'outflowByCategory': outflowByCategory,
      };

  String get label => '${_monthName(month)} $year';

  static String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m - 1];
}

class TransactionModel {
  final String id;
  final TxnKind kind;
  final String category; // letter: E/S/B/I/G or E/S/D/I/DO
  final double amount;
  final String note;
  /// YYYY-MM-DD
  final String date;
  /// Which account pocket this entry posts to (income) or from (outflow).
  /// Defaults to [CashFlowAccount.bank] for legacy transactions without the field.
  final CashFlowAccount account;

  const TransactionModel({
    required this.id,
    required this.kind,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    this.account = CashFlowAccount.bank,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      kind: json['kind'] == 'INCOME' ? TxnKind.income : TxnKind.outflow,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      date: (json['date'] as String?)?.split('T').first ?? '',
      account: CashFlowAccount.fromApi(json['account'] as String?),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'kind': kind == TxnKind.income ? 'INCOME' : 'OUTFLOW',
        'category': category,
        'amount': amount,
        if (note.isNotEmpty) 'note': note,
        'date': date,
        'account': account.apiValue,
      };
}

class DebtEntryModel {
  final String id;
  /// GIVE = I owe them; RECEIVE = they owe me.
  final bool theyOweMe;
  final String person;
  final double amount;
  final String note;
  /// YYYY-MM-DD
  final String date;
  final bool settled;
  final String? settledAt;

  const DebtEntryModel({
    required this.id,
    required this.theyOweMe,
    required this.person,
    required this.amount,
    required this.note,
    required this.date,
    required this.settled,
    this.settledAt,
  });

  factory DebtEntryModel.fromJson(Map<String, dynamic> json) {
    return DebtEntryModel(
      id: json['id'] as String,
      theyOweMe: json['direction'] == 'RECEIVE',
      person: json['person'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: (json['note'] as String?) ?? '',
      date: (json['date'] as String?)?.split('T').first ?? '',
      settled: json['settled'] as bool? ?? false,
      settledAt: json['settledAt'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'direction': theyOweMe ? 'RECEIVE' : 'GIVE',
        'person': person,
        'amount': amount,
        if (note.isNotEmpty) 'note': note,
        'date': date,
      };
}
