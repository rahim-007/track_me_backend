import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/debt_model.dart';

typedef DebtsState = AsyncValue<List<DebtModel>>;

/// Standalone Debt / Loan store. Fully independent of Cash Flow — a debt
/// payment is tracked here only and never feeds expenses/budget calculations.
class DebtsNotifier extends StateNotifier<DebtsState> {
  DebtsNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue<List<DebtModel>>.loading().copyWithPrevious(state);
    try {
      final client = DioClient();
      final response = await client.dio.get('/debts');
      final list = (response.data['data'] as List)
          .map((e) => DebtModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (_) {
      if (!mounted) return;
      state = const AsyncValue.data([]);
    }
  }

  /// @returns true on success, false on failure (nothing changes on failure).
  Future<bool> add({
    required String name,
    required double originalAmount,
    String? lenderName,
    DateTime? dueDate,
    double? installmentAmount,
    String? description,
  }) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/debts', data: {
        'name': name,
        'originalAmount': originalAmount,
        'lenderName': lenderName,
        'dueDate': _dateStr(dueDate),
        'installmentAmount': installmentAmount,
        'description': description,
      });
      final item =
          DebtModel.fromJson(response.data['data'] as Map<String, dynamic>);
      if (!mounted) return false;
      state.whenData((list) {
        state = AsyncValue.data([item, ...list]);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// @returns true on success, false on failure (nothing changes on failure).
  Future<bool> update(
    String id, {
    String? name,
    double? originalAmount,
    String? lenderName,
    DateTime? dueDate,
    double? installmentAmount,
    String? description,
  }) async {
    try {
      final client = DioClient();
      final response = await client.dio.patch('/debts/$id', data: {
        'name': name,
        'originalAmount': originalAmount,
        'lenderName': lenderName,
        'dueDate': _dateStr(dueDate),
        'installmentAmount': installmentAmount,
        'description': description,
      });
      final updated =
          DebtModel.fromJson(response.data['data'] as Map<String, dynamic>);
      _replace(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove(String id) async {
    state.whenData((list) {
      state = AsyncValue.data(list.where((d) => d.id != id).toList());
    });
    try {
      final client = DioClient();
      await client.dio.delete('/debts/$id');
    } catch (_) {}
  }

  /// Record a payment. Returns the updated debt on success, null on failure.
  Future<DebtModel?> recordPayment(
    String id, {
    required double amount,
    DateTime? paymentDate,
    String? note,
  }) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/debts/$id/payments', data: {
        'amount': amount,
        'paymentDate': _dateStr(paymentDate),
        'note': note,
      });
      final updated =
          DebtModel.fromJson(response.data['data'] as Map<String, dynamic>);
      _replace(updated);
      return updated;
    } catch (_) {
      return null;
    }
  }

  /// Latest copy of a debt from the loaded list (or null).
  DebtModel? byId(String id) {
    final list = state.valueOrNull;
    if (list == null) return null;
    for (final d in list) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _replace(DebtModel updated) {
    state.whenData((list) {
      state = AsyncValue.data([
        for (final d in list) d.id == updated.id ? updated : d,
      ]);
    });
  }

  static String? _dateStr(DateTime? date) {
    if (date == null) return null;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}

final debtsProvider = StateNotifierProvider<DebtsNotifier, DebtsState>((ref) {
  final notifier = DebtsNotifier();
  notifier.load();
  return notifier;
});

/// Total outstanding (sum of remaining balances) across active debts — used by
/// the Cash Flow entry card. Purely informational; never feeds calculations.
final debtOutstandingTotalProvider = Provider<double>((ref) {
  return ref.watch(debtsProvider).when(
        data: (list) => list
            .where((d) => !d.isPaid)
            .fold<double>(0.0, (sum, d) => sum + d.remainingBalance),
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

/// Number of active (not fully paid) debts — used by the entry card subtitle.
final activeDebtCountProvider = Provider<int>((ref) {
  return ref.watch(debtsProvider).when(
        data: (list) => list.where((d) => !d.isPaid).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
