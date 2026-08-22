import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/goal_model.dart';

typedef GoalsState = AsyncValue<List<GoalModel>>;

class GoalsNotifier extends StateNotifier<GoalsState> {
  static const String _cacheName = 'goals_cache';

  /// True while a user mutation is in flight during a load; prevents the fetch
  /// result from clobbering changes made while the request was running.
  bool _dirtySinceLoad = false;

  GoalsNotifier() : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    final cached = await _readCachedGoals();
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    _dirtySinceLoad = false;
    try {
      final client = DioClient();
      final response = await client.dio.get('/goals');
      final serverList = (response.data['data'] as List)
          .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_dirtySinceLoad) return;

      final currentList = state.valueOrNull ?? cached ?? [];
      final tempItems = currentList.where((g) => g.id.startsWith('temp_')).toList();

      final mergedList = <GoalModel>[...serverList];
      for (final temp in tempItems) {
        if (!mergedList.any((g) => g.id == temp.id || g.name == temp.name)) {
          mergedList.add(temp);
        }
      }

      await _cacheGoals(mergedList);
      state = AsyncValue.data(mergedList);

      for (final temp in tempItems) {
        _syncTempGoal(temp);
      }
    } catch (e, st) {
      if (_dirtySinceLoad) return;
      if (cached != null && cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _syncTempGoal(GoalModel tempGoal) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/goals', data: tempGoal.toCreateJson());
      final newGoal = GoalModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final currentList = state.valueOrNull ?? [];
      final updated = currentList.map((g) => g.id == tempGoal.id ? newGoal : g).toList();
      state = AsyncValue.data(updated);
      await _cacheGoals(updated);
    } catch (_) {}
  }

  Future<void> addGoal(GoalModel goal) async {
    _dirtySinceLoad = true;
    try {
      final client = DioClient();
      final response = await client.dio.post('/goals', data: goal.toCreateJson());
      final newGoal =
          GoalModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final updated = [...state.valueOrNull ?? <GoalModel>[], newGoal];
      state = AsyncValue.data(updated);
      await _cacheGoals(updated);
    } catch (_) {
      // Optimistic update with temp id — still persisted locally so the goal
      // survives a hot restart even while the backend is offline.
      final tempGoal = goal.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updated = [...state.valueOrNull ?? <GoalModel>[], tempGoal];
      state = AsyncValue.data(updated);
      await _cacheGoals(updated);
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    _dirtySinceLoad = true;
    final updated = (state.valueOrNull ?? <GoalModel>[])
        .map((g) => g.id == goal.id ? goal : g)
        .toList();
    state = AsyncValue.data(updated);
    await _cacheGoals(updated);

    if (!goal.id.startsWith('temp_')) {
      try {
        final client = DioClient();
        final response = await client.dio.patch(
          '/goals/${goal.id}',
          data: goal.toUpdateJson(),
        );
        // Reconcile with the server's copy (returns the updated goal).
        final serverGoal = GoalModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        final reconciled = (state.valueOrNull ?? <GoalModel>[])
            .map((g) => g.id == goal.id ? serverGoal : g)
            .toList();
        state = AsyncValue.data(reconciled);
        await _cacheGoals(reconciled);
      } catch (_) {
        // Keep the optimistic local update; the backend keeps its old values
        // until the next sync.
      }
    }
  }

  Future<void> updateProgress(String goalId, double progress) async {
    _dirtySinceLoad = true;
    final updated = (state.valueOrNull ?? <GoalModel>[]).map((g) {
      if (g.id != goalId) return g;
      return g.copyWith(
        progress: progress,
        status: progress >= 1.0 ? 'completed' : 'in_progress',
      );
    }).toList();
    state = AsyncValue.data(updated);
    await _cacheGoals(updated);

    if (!goalId.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio.patch('/goals/$goalId/progress', data: {
          'progress': progress,
        });
      } catch (_) {}
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _dirtySinceLoad = true;
    final updated = (state.valueOrNull ?? <GoalModel>[])
        .where((g) => g.id != goalId)
        .toList();
    state = AsyncValue.data(updated);
    await _cacheGoals(updated);

    if (!goalId.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio.delete('/goals/$goalId');
      } catch (_) {}
    }
  }

  // ─── Local cache (offline-first) ─────────────────────────────────────────────

  static Future<void> _cacheGoals(List<GoalModel> goals) async {
    await JsonFileCache.write(
      _cacheName,
      goals.map((g) => g.toJson()).toList(),
    );
  }

  static Future<List<GoalModel>?> _readCachedGoals() async {
    return JsonFileCache.read(
      _cacheName,
      (json) => (json as List)
          .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>(
  (ref) => GoalsNotifier(),
);

final activeGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  return ref.watch(goalsProvider).whenData(
        (goals) => goals.where((g) => g.status != 'completed' && g.status != 'archived' && g.status != 'cancelled').toList(),
      );
});

final activeGoalsCountProvider = Provider<int>((ref) {
  return ref.watch(goalsProvider).when(
        data: (goals) => goals.where((g) => g.status != 'completed' && g.status != 'archived' && g.status != 'cancelled').length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final totalGoalsCountProvider = Provider<int>((ref) {
  return ref.watch(goalsProvider).when(
        data: (goals) => goals.length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final completedGoalsCountProvider = Provider<int>((ref) {
  return ref.watch(goalsProvider).when(
        data: (goals) => goals.where((g) => g.status == 'completed').length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
