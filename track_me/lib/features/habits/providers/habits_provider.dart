import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/notifications/notification_service.dart';
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

      // (Re)arm device-side reminders for every habit that has one —
      // idempotent (same ids overwrite) and heals habits created before local
      // reminders existed.
      unawaited(_rescheduleAllReminders(mergedList));

      for (final temp in tempItems) {
        _syncTempHabit(temp);
      }
    } catch (e, st) {
      if (_dirtySinceLoad) return;
      if (cached != null && cached.isNotEmpty) {
        state = AsyncValue.data(cached);
        unawaited(_rescheduleAllReminders(cached));
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

      // Move any locally-scheduled reminder from the temp id to the real one.
      await NotificationService.cancelHabitReminder(tempHabit.id);
      await _scheduleReminder(newHabit);

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
      await _scheduleReminder(newHabit);
    } catch (_) {
      // Optimistic update with temp id — still persisted locally so the habit
      // survives a hot restart even while the backend is offline.
      final tempHabit = habit.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updated = [...state.valueOrNull ?? <HabitModel>[], tempHabit];
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
      await _scheduleReminder(tempHabit);
    }
  }

  /// Save edits to an existing habit: PATCHes the backend (when it has a real
  /// id), updates local state/cache, and re-arms the device reminder — old
  /// slots are cancelled and a fresh schedule is created for the new time (or
  /// nothing when the reminder was removed).
  Future<void> updateHabit(HabitModel habit) async {
    _dirtySinceLoad = true;

    if (!habit.id.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio.patch('/habits/${habit.id}', data: habit.toCreateJson());
      } catch (_) {
        // Keep the optimistic state — the edit still lands locally and will be
        // re-pushed on the next sync.
      }
    }

    final updated = (state.valueOrNull ?? <HabitModel>[])
        .map((h) => h.id == habit.id ? habit : h)
        .toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    // Re-arm: cancel the old reminder schedule, then schedule the new one
    // (no-op when the reminder time was removed).
    await NotificationService.cancelHabitReminder(habit.id);
    await _scheduleReminder(habit);
  }

  Future<void> toggleCompletion(HabitModel habit, DateTime date) async {
    _dirtySinceLoad = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Resolve against the current state copy so stale caller data can never
    // bypass the guards below.
    var currentHabit = habit;
    for (final h in state.valueOrNull ?? <HabitModel>[]) {
      if (h.id == habit.id) {
        currentHabit = h;
        break;
      }
    }
    final isCompleted = currentHabit.completedDates.contains(dateStr);

    // A skipped habit must never flip to Completed from a status tap — a
    // habit is in exactly one state (Pending / Completed / Skipped) per day.
    if (!isCompleted && currentHabit.skippedDates.contains(dateStr)) return;

    // Optimistic update, then persist locally so completions survive restarts.
    final updated = (state.valueOrNull ?? <HabitModel>[]).map((h) {
      if (h.id != habit.id) return h;
      final newCompleted = List<String>.from(h.completedDates);
      final newSkipped = List<String>.from(h.skippedDates);
      if (isCompleted) {
        newCompleted.remove(dateStr); // undo existing completion
      } else {
        if (!newCompleted.contains(dateStr)) newCompleted.add(dateStr);
        newSkipped.remove(dateStr); // completing clears any skip for that day
      }
      return h.copyWith(completedDates: newCompleted, skippedDates: newSkipped);
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

    // Optimistic update, then persist locally. Skipping is idempotent (never
    // adds the same date twice) and always clears any completion for that day
    // so a habit is in exactly one state per date.
    final updated = (state.valueOrNull ?? <HabitModel>[]).map((h) {
      if (h.id != habit.id) return h;
      final newSkipped = List<String>.from(h.skippedDates);
      if (!newSkipped.contains(dateStr)) newSkipped.add(dateStr);
      final newCompleted = List<String>.from(h.completedDates)..remove(dateStr);
      return h.copyWith(skippedDates: newSkipped, completedDates: newCompleted);
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
    // Remove any scheduled local reminder for this habit.
    await NotificationService.cancelHabitReminder(habitId);
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

  // ─── Device-side reminders (local fallback for the backend FCM push) ────────

  /// (Re)arm local reminders for every habit that has a reminderTime.
  Future<void> _rescheduleAllReminders(List<HabitModel> habits) async {
    for (final habit in habits) {
      await _scheduleReminder(habit);
    }
  }

  /// Schedule the device-side reminder for [habit] (no-op without a time).
  Future<void> _scheduleReminder(HabitModel habit) async {
    final reminderTime = habit.reminderTime;
    if (reminderTime == null || reminderTime.isEmpty) return;
    final parts = reminderTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    await NotificationService.requestPermissions();
    await NotificationService.scheduleHabitReminder(
      habitId: habit.id,
      habitName: habit.name,
      hour: hour,
      minute: minute,
      repeatDays: habit.repeatDays,
    );
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

/// Per-habit streak: counts consecutive *scheduled* days (walking backward
/// from [from], defaulting to today) on which the habit has a completion.
/// Unscheduled days are ignored and never break the streak; a scheduled day
/// that is skipped or missing breaks it. A habit with no repeat day selected
/// is treated as daily.
int calculateHabitStreak(HabitModel habit, {DateTime? from}) {
  if (habit.completedDates.isEmpty) return 0;
  final completed = habit.completedDates.toSet();
  final hasRepeatDay = habit.repeatDays.any((d) => d);
  final now = from ?? DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);

  int streak = 0;
  DateTime day = now;
  for (int i = 0; i < 366; i++) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekdayIndex = day.weekday - 1; // 0 = Monday
    final isScheduled = hasRepeatDay
        ? (weekdayIndex >= 0 &&
            weekdayIndex < habit.repeatDays.length &&
            habit.repeatDays[weekdayIndex])
        : true;
    if (!isScheduled) {
      day = day.subtract(const Duration(days: 1));
      continue;
    }
    if (completed.contains(dateStr)) {
      streak++;
    } else {
      // Today is in progress (grace period) — keep the streak from yesterday
      if (dateStr == todayStr) {
        day = day.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

int calculateCurrentStreak(List<HabitModel> habits, {DateTime? from}) {
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

  final now = from ?? DateTime.now();
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
      // A habit with no repeat day selected is treated as daily.
      final hasRepeatDay = h.repeatDays.any((d) => d);
      final isScheduled = !hasRepeatDay ||
          (repeatDaysIndex >= 0 &&
              repeatDaysIndex < h.repeatDays.length &&
              h.repeatDays[repeatDaysIndex]);
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

int calculateLongestStreak(List<HabitModel> habits, {DateTime? from}) {
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

  final now = from ?? DateTime.now();
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
      // A habit with no repeat day selected is treated as daily.
      final hasRepeatDay = h.repeatDays.any((d) => d);
      final isScheduled = !hasRepeatDay ||
          (repeatDaysIndex >= 0 &&
              repeatDaysIndex < h.repeatDays.length &&
              h.repeatDays[repeatDaysIndex]);
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
