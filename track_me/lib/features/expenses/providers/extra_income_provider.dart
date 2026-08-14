import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/extra_income_model.dart';

typedef ExtraIncomeState = AsyncValue<List<ExtraIncomeModel>>;

/// Standalone extra-income store. Fully independent of the expense budget,
/// income, savings and P&L calculations — it only tracks its own entries.
class ExtraIncomeNotifier extends StateNotifier<ExtraIncomeState> {
  ExtraIncomeNotifier() : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue<List<ExtraIncomeModel>>.loading()
        .copyWithPrevious(state);
    try {
      final client = DioClient();
      final response = await client.dio.get('/extra-income');
      final list = (response.data['data'] as List)
          .map((e) => ExtraIncomeModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (_) {
      if (!mounted) return;
      state = const AsyncValue.data([]);
    }
  }

  Future<void> add({
    required String title,
    required double amount,
    required DateTime date,
  }) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/extra-income', data: {
        'title': title,
        'amount': amount,
        'date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      });
      final item =
          ExtraIncomeModel.fromJson(response.data['data'] as Map<String, dynamic>);
      if (!mounted) return;
      state.whenData((list) {
        state = AsyncValue.data([item, ...list]);
      });
    } catch (_) {
      // Optimistic: show a temp entry so the screen never flashes a spinner.
      final temp = ExtraIncomeModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        amount: amount,
        date: date,
        createdAt: DateTime.now(),
      );
      if (!mounted) return;
      state.whenData((list) {
        state = AsyncValue.data([temp, ...list]);
      });
    }
  }

  Future<void> remove(String id) async {
    state.whenData((list) {
      state = AsyncValue.data(list.where((e) => e.id != id).toList());
    });
    try {
      final client = DioClient();
      await client.dio.delete('/extra-income/$id');
    } catch (_) {}
  }
}

final extraIncomeProvider =
    StateNotifierProvider<ExtraIncomeNotifier, ExtraIncomeState>((ref) {
  final notifier = ExtraIncomeNotifier();
  notifier.load();
  return notifier;
});

/// Total extra income across all entries (for the summary card).
final extraIncomeTotalProvider = Provider<double>((ref) {
  return ref.watch(extraIncomeProvider).when(
        data: (list) => list.fold<double>(0.0, (sum, e) => sum + e.amount),
        loading: () => 0.0,
        error: (_, __) => 0.0,
      );
});

/// Number of extra-income entries (for the summary card).
final extraIncomeCountProvider = Provider<int>((ref) {
  return ref.watch(extraIncomeProvider).when(
        data: (list) => list.length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
