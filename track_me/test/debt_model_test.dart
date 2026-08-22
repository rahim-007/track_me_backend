import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/debts/data/models/debt_model.dart';

void main() {
  test('DebtModel.fromJson parses fields and derived totals', () {
    final debt = DebtModel.fromJson({
      'id': 'd1',
      'name': 'Personal Loan',
      'originalAmount': 50000,
      'lenderName': 'Bank',
      'dueDate': '2026-12-31T00:00:00.000Z',
      'installmentAmount': 5000,
      'description': 'Home loan',
      'status': 'ACTIVE',
      'totalPaid': 15000,
      'remainingBalance': 35000,
      'createdAt': '2026-08-01T00:00:00.000Z',
      'payments': [
        {
          'id': 'p1',
          'amount': 15000,
          'paymentDate': '2026-08-10T00:00:00.000Z',
          'note': 'EMI',
        },
      ],
    });

    expect(debt.id, 'd1');
    expect(debt.name, 'Personal Loan');
    expect(debt.originalAmount, 50000);
    expect(debt.lenderName, 'Bank');
    expect(debt.dueDate, DateTime.parse('2026-12-31T00:00:00.000Z'));
    expect(debt.installmentAmount, 5000);
    expect(debt.status, 'ACTIVE');
    expect(debt.isPaid, isFalse);
    expect(debt.totalPaid, 15000);
    expect(debt.remainingBalance, 35000);
    expect(debt.payments, hasLength(1));
    expect(debt.payments.first.amount, 15000);
    expect(debt.payments.first.note, 'EMI');
  });

  test('progress is the fraction of the original amount paid', () {
    final halfPaid = DebtModel.fromJson({
      'id': 'd1',
      'name': 'Loan',
      'originalAmount': 50000,
      'status': 'ACTIVE',
      'totalPaid': 25000,
      'remainingBalance': 25000,
      'createdAt': '2026-08-01T00:00:00.000Z',
    });
    expect(halfPaid.progress, closeTo(0.5, 0.0001));

    final paid = DebtModel.fromJson({
      'id': 'd2',
      'name': 'Loan',
      'originalAmount': 50000,
      'status': 'PAID',
      'totalPaid': 50000,
      'remainingBalance': 0,
      'createdAt': '2026-08-01T00:00:00.000Z',
    });
    expect(paid.isPaid, isTrue);
    expect(paid.progress, 1.0);
  });

  test('fromJson tolerates missing optional fields', () {
    final debt = DebtModel.fromJson({
      'id': 'd3',
      'name': 'Loan',
      'originalAmount': 1000,
      'status': 'ACTIVE',
      'totalPaid': 0,
      'remainingBalance': 1000,
      'createdAt': '2026-08-01T00:00:00.000Z',
    });
    expect(debt.lenderName, isNull);
    expect(debt.dueDate, isNull);
    expect(debt.installmentAmount, isNull);
    expect(debt.description, isNull);
    expect(debt.payments, isEmpty);
  });
}
