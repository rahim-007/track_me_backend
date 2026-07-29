import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/goal_model.dart';

typedef GoalsState = AsyncValue<List<GoalModel>>;

class GoalsNotifier extends StateNotifier<GoalsState> {
  GoalsNotifier() : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final client = DioClient();
      final response = await client.dio.get('/goals');
      final list = (response.data as List)
          .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (_) {
      state = AsyncValue.data(_mockGoals());
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/goals', data: goal.toJson());
      final newGoal = GoalModel.fromJson(response.data as Map<String, dynamic>);
      state.whenData((goals) {
        state = AsyncValue.data([...goals, newGoal]);
      });
    } catch (_) {
      final tempGoal = goal.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      state.whenData((goals) {
        state = AsyncValue.data([...goals, tempGoal]);
      });
    }
  }

  Future<void> updateProgress(String goalId, double progress) async {
    state.whenData((goals) {
      final updated = goals.map((g) {
        if (g.id != goalId) return g;
        return g.copyWith(
          progress: progress,
          status: progress >= 1.0 ? 'completed' : 'in_progress',
        );
      }).toList();
      state = AsyncValue.data(updated);
    });
    try {
      final client = DioClient();
      await client.dio.patch('/goals/$goalId/progress', data: {
        'progress': progress,
      });
    } catch (_) {}
  }

  Future<void> deleteGoal(String goalId) async {
    state.whenData((goals) {
      state = AsyncValue.data(goals.where((g) => g.id != goalId).toList());
    });
    try {
      final client = DioClient();
      await client.dio.delete('/goals/$goalId');
    } catch (_) {}
  }

  List<GoalModel> _mockGoals() => [
        GoalModel(
          id: '1',
          name: 'Run a Marathon',
          category: 'Fitness',
          targetDate: DateTime.now().add(const Duration(days: 90)),
          priority: 'High',
          status: 'in_progress',
          progress: 0.35,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        GoalModel(
          id: '2',
          name: 'Learn Flutter',
          category: 'Education',
          targetDate: DateTime.now().add(const Duration(days: 60)),
          priority: 'High',
          status: 'in_progress',
          progress: 0.70,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        GoalModel(
          id: '3',
          name: 'Save \$5000',
          category: 'Finance',
          targetDate: DateTime.now().add(const Duration(days: 180)),
          priority: 'Medium',
          status: 'in_progress',
          progress: 0.20,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        GoalModel(
          id: '4',
          name: 'Read 24 Books',
          category: 'Personal',
          targetDate: DateTime(DateTime.now().year, 12, 31),
          priority: 'Low',
          status: 'in_progress',
          progress: 0.50,
          createdAt: DateTime(DateTime.now().year, 1, 1),
        ),
      ];
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>(
  (ref) => GoalsNotifier(),
);

final activeGoalsProvider = Provider<AsyncValue<List<GoalModel>>>((ref) {
  return ref.watch(goalsProvider).whenData(
    (goals) => goals.where((g) => g.status != 'completed').toList(),
  );
});
