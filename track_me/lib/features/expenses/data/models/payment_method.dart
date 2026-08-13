import 'package:flutter/material.dart';

enum PaymentMethod {
  cash,
  upi,
  creditCard,
  debitCard,
  bankTransfer;

  String get label {
    switch (this) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.creditCard: return 'Credit Card';
      case PaymentMethod.debitCard: return 'Debit Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash: return Icons.money_rounded;
      case PaymentMethod.upi: return Icons.phone_android_rounded;
      case PaymentMethod.creditCard: return Icons.credit_card_rounded;
      case PaymentMethod.debitCard: return Icons.credit_card_outlined;
      case PaymentMethod.bankTransfer: return Icons.account_balance_rounded;
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash: return 'CASH';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.creditCard: return 'CREDIT_CARD';
      case PaymentMethod.debitCard: return 'DEBIT_CARD';
      case PaymentMethod.bankTransfer: return 'BANK_TRANSFER';
    }
  }

  static PaymentMethod fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'CASH': return PaymentMethod.cash;
      case 'UPI': return PaymentMethod.upi;
      case 'CREDIT_CARD': return PaymentMethod.creditCard;
      case 'DEBIT_CARD': return PaymentMethod.debitCard;
      case 'BANK_TRANSFER': return PaymentMethod.bankTransfer;
      default: return PaymentMethod.cash;
    }
  }
}
