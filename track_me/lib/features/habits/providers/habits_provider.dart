import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_client.dart';
import '../data/models/habit_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

typedef HabitsState = AsyncValue<List<HabitModel>>;

// ─── Notifier ────────────────────────────────────────────────────────────────

class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final client = DioClient();
      final response = await client.dio.get('/habits');
      final list = (response.data as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      // Fallback to local mock data for offline/dev
      state = AsyncValue.data(_mockHabits());
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/habits', data: habit.toJson());
      final newHabit = HabitModel.fromJson(response.data as Map<String, dynamic>);
      state.whenData((habits) {
        state = AsyncValue.data([...habits, newHabit]);
      });
    } catch (_) {
      // Optimistic update with temp id
      final tempHabit = habit.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      state.whenData((habits) {
        state = AsyncValue.data([...habits, tempHabit]);
      });
    }
  }

  Future<void> toggleCompletion(HabitModel habit, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final isCompleted = habit.completedDates.contains(dateStr);

    // Optimistic update
    state.whenData((habits) {
      final updated = habits.map((h) {
        if (h.id != habit.id) return h;
        final newCompleted = List<String>.from(h.completedDates);
        if (isCompleted) {
          newCompleted.remove(dateStr);
        } else {
          newCompleted.add(dateStr);
        }
        return h.copyWith(completedDates: newCompleted);
      }).toList();
      state = AsyncValue.data(updated);
    });

    try {
      final client = DioClient();
      if (isCompleted) {
        await client.dio.delete('/habit-logs/${habit.id}/$dateStr');
      } else {
        await client.dio.post('/habit-logs', data: {
          'habitId': habit.id,
          'date': dateStr,
        });
      }
    } catch (_) {
      // Keep optimistic state
    }
  }

  Future<void> skipHabit({
    required HabitModel habit,
    required DateTime date,
    required String reason,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Optimistic update
    state.whenData((habits) {
      final updated = habits.map((h) {
        if (h.id != habit.id) return h;
        final newSkipped = List<String>.from(h.skippedDates)..add(dateStr);
        return h.copyWith(skippedDates: newSkipped);
      }).toList();
      state = AsyncValue.data(updated);
    });

    try {
      final client = DioClient();
      await client.dio.post('/habit-logs/skip', data: {
        'habitId': habit.id,
        'date': dateStr,
        'reason': reason,
      });
    } catch (_) {
      // Keep optimistic state
    }
  }

  Future<void> deleteHabit(String habitId) async {
    state.whenData((habits) {
      state = AsyncValue.data(habits.where((h) => h.id != habitId).toList());
    });
    try {
      final client = DioClient();
      await client.dio.delete('/habits/$habitId');
    } catch (_) {}
  }

  List<HabitModel> _mockHabits() => [
        HabitModel(
          id: '1',
          name: 'Morning Run',
          category: 'Fitness',
          emoji: '🏃',
          color: '#7C3AED',
          repeatDays: List.filled(7, true),
          reminderTime: '07:00',
          createdAt: DateTime.now(),
          completedDates: [
            DateFormat('yyyy-MM-dd').format(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
          skippedDates: [],
        ),
        HabitModel(
          id: '2',
          name: 'Read 30 mins',
          category: 'Learning',
          emoji: '📚',
          color: '#3B82F6',
          repeatDays: List.filled(7, true),
          reminderTime: '21:00',
          createdAt: DateTime.now(),
          completedDates: [],
          skippedDates: [],
        ),
        HabitModel(
          id: '3',
          name: 'Meditate',
          category: 'Mindfulness',
          emoji: '🧘',
          color: '#10B981',
          repeatDays: List.filled(7, true),
          createdAt: DateTime.now(),
          completedDates: [
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
          ],
          skippedDates: [],
        ),
      ];
}

// ─── Providers ───────────────────────────────────────────────────────────────

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>(
  (ref) => HabitsNotifier(),
);

final todayHabitsProvider = Provider<AsyncValue<List<HabitModel>>>((ref) {
  return ref.watch(habitsProvider);
});

final completedHabitsCountProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).when(
    data: (habits) => habits.where((h) => h.isCompletedToday).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final currentStreakProvider = Provider<int>((ref) {
  // TODO: compute actual streak from completed dates
  return 7;
});
