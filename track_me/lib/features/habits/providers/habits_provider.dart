import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/habit_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

typedef HabitsState = AsyncValue<List<HabitModel>>;

// ─── Notifier ────────────────────────────────────────────────────────────────

class HabitsNotifier extends StateNotifier<HabitsState> {
  static const String _cacheName = 'habits_cache';

  /// True while a user mutation is in flight during a load; prevents the fetch
  /// result from clobbering changes made while the request was running.
  bool _dirtySinceLoad = false;

  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    final cached = await _readCachedHabits();
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    _dirtySinceLoad = false;
    try {
      final client = DioClient();
      final response = await client.dio.get('/habits');
      final serverList = (response.data['data'] as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_dirtySinceLoad) return;

      final currentList = state.valueOrNull ?? cached ?? [];
      final tempItems = currentList.where((h) => h.id.startsWith('temp_')).toList();

      final mergedList = <HabitModel>[...serverList];
      for (final temp in tempItems) {
        if (!mergedList.any((h) => h.id == temp.id || h.name == temp.name)) {
          mergedList.add(temp);
        }
      }

      await _cacheHabits(mergedList);
      state = AsyncValue.data(mergedList);

      for (final temp in tempItems) {
        _syncTempHabit(temp);
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

  Future<void> _syncTempHabit(HabitModel tempHabit) async {
    try {
      final client = DioClient();
      final response = await client.dio.post('/habits', data: tempHabit.toCreateJson());
      final newHabit = HabitModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final currentList = state.valueOrNull ?? [];
      final updated = currentList.map((h) => h.id == tempHabit.id ? newHabit : h).toList();
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
    } catch (_) {}
  }

  Future<void> addHabit(HabitModel habit) async {
    _dirtySinceLoad = true;
    try {
      final client = DioClient();
      final response = await client.dio.post('/habits', data: habit.toCreateJson());
      final newHabit =
          HabitModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final updated = [...state.valueOrNull ?? <HabitModel>[], newHabit];
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
    } catch (_) {
      // Optimistic update with temp id — still persisted locally so the habit
      // survives a hot restart even while the backend is offline.
      final tempHabit = habit.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updated = [...state.valueOrNull ?? <HabitModel>[], tempHabit];
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
    }
  }

  Future<void> toggleCompletion(HabitModel habit, DateTime date) async {
    _dirtySinceLoad = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final isCompleted = habit.completedDates.contains(dateStr);

    // Optimistic update, then persist locally so completions survive restarts.
    final updated = (state.valueOrNull ?? <HabitModel>[]).map((h) {
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
    await _cacheHabits(updated);

    if (!habit.id.startsWith('temp_')) {
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
  }

  Future<void> skipHabit({
    required HabitModel habit,
    required DateTime date,
    required String reason,
  }) async {
    _dirtySinceLoad = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Optimistic update, then persist locally.
    final updated = (state.valueOrNull ?? <HabitModel>[]).map((h) {
      if (h.id != habit.id) return h;
      final newSkipped = List<String>.from(h.skippedDates)..add(dateStr);
      return h.copyWith(skippedDates: newSkipped);
    }).toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    if (!habit.id.startsWith('temp_')) {
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
  }

  Future<void> deleteHabit(String habitId) async {
    _dirtySinceLoad = true;
    final updated = (state.valueOrNull ?? <HabitModel>[])
        .where((h) => h.id != habitId)
        .toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    if (!habitId.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio.delete('/habits/$habitId');
      } catch (_) {}
    }
  }

  // ─── Local cache (offline-first) ─────────────────────────────────────────────

  static Future<void> _cacheHabits(List<HabitModel> habits) async {
    await JsonFileCache.write(
      _cacheName,
      habits.map((h) => h.toJson()).toList(),
    );
  }

  static Future<List<HabitModel>?> _readCachedHabits() async {
    return JsonFileCache.read(
      _cacheName,
      (json) => (json as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Helpers & Providers ───────────────────────────────────────────────────────

int calculateCurrentStreak(List<HabitModel> habits) {
  if (habits.isEmpty) return 0;

  // O(1) membership lookups instead of O(n) list scans in the inner loops
  final completedSets = <String, Set<String>>{
    for (final h in habits) h.id: h.completedDates.toSet(),
  };

  String getLocalDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime earliestDate = habits.first.createdAt;
  for (final h in habits) {
    if (h.createdAt.isBefore(earliestDate)) {
      earliestDate = h.createdAt;
    }
  }

  final now = DateTime.now();
  final todayStr = getLocalDateStr(now);
  final earliestStr = getLocalDateStr(earliestDate);

  final dateStrings = <String>[];
  DateTime checkDate = DateTime(now.year, now.month, now.day);
  String checkStr = getLocalDateStr(checkDate);

  while (checkStr.compareTo(earliestStr) >= 0) {
    dateStrings.add(checkStr);
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = getLocalDateStr(checkDate);
  }

  if (dateStrings.isEmpty) return 0;

  int currentStreak = 0;
  for (final dateStr in dateStrings) {
    final parts = dateStr.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    final dateObj = DateTime(y, m, d);

    final weekday = dateObj.weekday; // 1 = Monday, 7 = Sunday
    final repeatDaysIndex = weekday - 1;

    final scheduledHabits = habits.where((h) {
      final createdStr = getLocalDateStr(h.createdAt);
      final isScheduled = (repeatDaysIndex >= 0 && repeatDaysIndex < h.repeatDays.length)
          ? h.repeatDays[repeatDaysIndex]
          : true;
      return isScheduled && createdStr.compareTo(dateStr) <= 0;
    }).toList();

    if (scheduledHabits.isEmpty) {
      continue;
    }

    bool allDone = true;
    for (final h in scheduledHabits) {
      if (!completedSets[h.id]!.contains(dateStr)) {
        allDone = false;
        break;
      }
    }

    if (allDone) {
      currentStreak++;
    } else {
      if (dateStr == todayStr) {
        continue;
      } else {
        break;
      }
    }
  }

  return currentStreak;
}

int calculateLongestStreak(List<HabitModel> habits) {
  if (habits.isEmpty) return 0;

  // O(1) membership lookups instead of O(n) list scans in the inner loops
  final completedSets = <String, Set<String>>{
    for (final h in habits) h.id: h.completedDates.toSet(),
  };

  String getLocalDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime earliestDate = habits.first.createdAt;
  for (final h in habits) {
    if (h.createdAt.isBefore(earliestDate)) {
      earliestDate = h.createdAt;
    }
  }

  final now = DateTime.now();
  final todayStr = getLocalDateStr(now);
  final earliestStr = getLocalDateStr(earliestDate);

  final dateStrings = <String>[];
  DateTime checkDate = DateTime(now.year, now.month, now.day);
  String checkStr = getLocalDateStr(checkDate);

  while (checkStr.compareTo(earliestStr) >= 0) {
    dateStrings.add(checkStr);
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = getLocalDateStr(checkDate);
  }

  int longestStreak = 0;
  int tempStreak = 0;
  final chronologicalDates = dateStrings.reversed.toList();

  for (final dateStr in chronologicalDates) {
    final parts = dateStr.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    final dateObj = DateTime(y, m, d);

    final weekday = dateObj.weekday;
    final repeatDaysIndex = weekday - 1;

    final scheduledHabits = habits.where((h) {
      final createdStr = getLocalDateStr(h.createdAt);
      final isScheduled = (repeatDaysIndex >= 0 && repeatDaysIndex < h.repeatDays.length)
          ? h.repeatDays[repeatDaysIndex]
          : true;
      return isScheduled && createdStr.compareTo(dateStr) <= 0;
    }).toList();

    if (scheduledHabits.isEmpty) {
      continue;
    }

    bool allDone = true;
    for (final h in scheduledHabits) {
      if (!completedSets[h.id]!.contains(dateStr)) {
        allDone = false;
        break;
      }
    }

    if (allDone) {
      tempStreak++;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
    } else {
      if (dateStr == todayStr) {
        // ignore
      } else {
        tempStreak = 0;
      }
    }
  }

  final current = calculateCurrentStreak(habits);
  if (current > longestStreak) {
    longestStreak = current;
  }

  return longestStreak;
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>(
  (ref) => HabitsNotifier(),
);

final todayHabitsProvider = Provider<AsyncValue<List<HabitModel>>>((ref) {
  return ref.watch(habitsProvider);
});

final completedHabitsCountProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).when(
        data: (habits) => habits.fold<int>(0, (sum, h) => sum + h.completedDates.length),
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).when(
        data: (habits) => calculateCurrentStreak(habits),
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final longestStreakProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).when(
        data: (habits) => calculateLongestStreak(habits),
        loading: () => 0,
        error: (_, __) => 0,
      );
});

final totalHabitsCountProvider = Provider<int>((ref) {
  return ref.watch(habitsProvider).when(
        data: (habits) => habits.length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
