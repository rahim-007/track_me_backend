import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../../core/local/json_file_cache.dart';
import '../../../core/network/dio_cache_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/widgets/home_widget_service.dart';
import '../data/models/habit_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

typedef HabitsState = AsyncValue<List<HabitModel>>;

// ─── Notifier ────────────────────────────────────────────────────────────────

class HabitsNotifier extends StateNotifier<HabitsState> {
  static const String _cacheName = 'habits_cache';

  /// True while a user mutation is in flight during a load; prevents the fetch
  /// result from clobbering changes made while the request was running.
  bool _dirtySinceLoad = false;

  /// Prevents rapid double-taps/touch bounces from toggling ON and immediately OFF.
  final Map<String, DateTime> _lastToggleTime = {};

  /// Local session toggles: key `${habitId}_$dateStr` -> (isCompleted, at).
  /// Reconciles against server fetches so an in-flight server response never
  /// removes a mark the user just made.
  final Map<String, (bool isCompleted, DateTime at)> _recentLocalToggles = {};

  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    final rawCached = await _readCachedHabits();
    final cached = await _reconcilePendingWidgetToggles(rawCached ?? []);
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
      unawaited(_syncHomeWidgets(cached));
    } else {
      state = const AsyncValue.loading();
    }

    _dirtySinceLoad = false;
    try {
      final client = DioClient();
      final response = await client.dio.get(
        '/habits',
        options: Options(extra: {'noCache': true}),
      );
      final serverList = (response.data['data'] as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (_dirtySinceLoad) return;

      final currentList = state.valueOrNull ?? cached ?? [];
      final tempItems =
          currentList.where((h) => h.id.startsWith('temp_')).toList();

      // Clean up any _recentLocalToggles older than 2 minutes
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      _recentLocalToggles.removeWhere((_, val) => val.$2.isBefore(cutoff));

      // Inspect any in-flight toggle actions queued in SyncQueue
      final pendingSyncActions = SyncQueue.instance.actions
          .where((a) => a.type == SyncActionType.toggleHabit)
          .toList();

      final mergedList = <HabitModel>[];
      for (final serverHabit in serverList) {
        var habit = serverHabit;
        final completedDates = List<String>.from(habit.completedDates);
        final skippedDates = List<String>.from(habit.skippedDates);
        bool changed = false;

        // 1. Reconcile with local session toggles from the last 2 minutes
        _recentLocalToggles.forEach((key, val) {
          final prefix = '${habit.id}_';
          if (key.startsWith(prefix)) {
            final dateStr = key.substring(prefix.length);
            final isCompleted = val.$1;
            if (isCompleted && !completedDates.contains(dateStr)) {
              completedDates.add(dateStr);
              skippedDates.remove(dateStr);
              changed = true;
            } else if (!isCompleted && completedDates.contains(dateStr)) {
              completedDates.remove(dateStr);
              changed = true;
            }
          }
        });

        // 2. Reconcile with pending SyncQueue actions
        for (final action in pendingSyncActions) {
          if (action.method == 'POST' && action.payload is Map) {
            final payload = action.payload as Map;
            if (payload['habitId'] == habit.id && payload['date'] != null) {
              final d = payload['date'].toString();
              if (!completedDates.contains(d)) {
                completedDates.add(d);
                skippedDates.remove(d);
                changed = true;
              }
            }
          } else if (action.method == 'DELETE' &&
              action.endpoint.contains(habit.id)) {
            final segs = action.endpoint.split('/');
            if (segs.length >= 4 && segs[2] == habit.id) {
              final d = segs[3];
              if (completedDates.contains(d)) {
                completedDates.remove(d);
                changed = true;
              }
            }
          }
        }

        if (changed) {
          final streak = calculateHabitStreak(habit.copyWith(
            completedDates: completedDates,
            skippedDates: skippedDates,
          ));
          habit = habit.copyWith(
            completedDates: completedDates,
            skippedDates: skippedDates,
            currentStreak: streak,
          );
        }

        mergedList.add(habit);
      }

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
      final response =
          await client.dio.post('/habits', data: tempHabit.toCreateJson());
      final newHabit =
          HabitModel.fromJson(response.data['data'] as Map<String, dynamic>);

      // Move any locally-scheduled reminder from the temp id to the real one.
      await NotificationService.cancelHabitReminder(tempHabit.id);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _scheduleReminder(
        newHabit,
        isCompletedToday: newHabit.completedDates.contains(todayStr),
      );

      final currentList = state.valueOrNull ?? [];
      final updated =
          currentList.map((h) => h.id == tempHabit.id ? newHabit : h).toList();
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
    } catch (_) {
      // Enqueue in background sync manager for guaranteed delivery
      await SyncManager.instance.enqueue(
        SyncAction(
          type: SyncActionType.createHabit,
          endpoint: '/habits',
          method: 'POST',
          payload: tempHabit.toCreateJson(),
          tempId: tempHabit.id,
        ),
      );
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    _dirtySinceLoad = true;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final client = DioClient();
      final response =
          await client.dio.post('/habits', data: habit.toCreateJson());
      final newHabit =
          HabitModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final updated = [...state.valueOrNull ?? <HabitModel>[], newHabit];
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
      await _scheduleReminder(
        newHabit,
        isCompletedToday: newHabit.completedDates.contains(todayStr),
      );
    } catch (_) {
      // Optimistic update with temp id — still persisted locally so the habit
      // survives a hot restart even while the backend is offline.
      final tempHabit = habit.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updated = [...state.valueOrNull ?? <HabitModel>[], tempHabit];
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
      await _scheduleReminder(
        tempHabit,
        isCompletedToday: tempHabit.completedDates.contains(todayStr),
      );

      // Register with background sync engine
      await SyncManager.instance.enqueue(
        SyncAction(
          type: SyncActionType.createHabit,
          endpoint: '/habits',
          method: 'POST',
          payload: tempHabit.toCreateJson(),
          tempId: tempHabit.id,
        ),
      );
    }
    DioCacheInterceptor().invalidateTag('habits');
  }

  Future<void> updateHabit(HabitModel habit) async {
    _dirtySinceLoad = true;
    DioCacheInterceptor().invalidateTag('habits');

    if (!habit.id.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio
            .patch('/habits/${habit.id}', data: habit.toCreateJson());
      } catch (_) {
        // Enqueue to background sync manager
        await SyncManager.instance.enqueue(
          SyncAction(
            type: SyncActionType.updateHabit,
            endpoint: '/habits/${habit.id}',
            method: 'PATCH',
            payload: habit.toCreateJson(),
          ),
        );
      }
    }

    final updated = (state.valueOrNull ?? <HabitModel>[])
        .map((h) => h.id == habit.id ? habit : h)
        .toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    // Re-arm: cancel the old reminder schedule, then schedule the new one
    // (no-op when the reminder time was removed).
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await NotificationService.cancelHabitReminder(habit.id);
    await _scheduleReminder(
      habit,
      isCompletedToday: habit.completedDates.contains(todayStr),
    );
  }

  Future<void> toggleCompletion(
    HabitModel habit,
    DateTime date, {
    bool debounce = false,
  }) async {
    _dirtySinceLoad = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final toggleKey = '${habit.id}_$dateStr';

    final now = DateTime.now();
    if (debounce) {
      final lastToggle = _lastToggleTime[toggleKey];
      if (lastToggle != null &&
          now.difference(lastToggle).inMilliseconds < 450) {
        debugPrint(
            '[HabitsNotifier] Debounce: ignoring rapid tap on $toggleKey');
        return;
      }
      _lastToggleTime[toggleKey] = now;
    }

    _dirtySinceLoad = true;

    // Invalidate Dio cache for habits tag immediately
    DioCacheInterceptor().invalidateTag('habits');

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

    final newCompletedStatus = !isCompleted;
    _recentLocalToggles[toggleKey] = (newCompletedStatus, now);

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
      final temp = h.copyWith(
        completedDates: newCompleted,
        skippedDates: newSkipped,
      );
      final newHabitStreak = calculateHabitStreak(temp);
      return temp.copyWith(
        currentStreak: newHabitStreak,
        totalCompleted: isCompleted
            ? (h.totalCompleted > 0 ? h.totalCompleted - 1 : 0)
            : h.totalCompleted + 1,
      );
    }).toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    // Maintain the local device-side reminder:
    // If completed TODAY → reschedule with isCompletedToday: true (skips today, arms tomorrow)
    // If un-completed TODAY → reschedule with isCompletedToday: false (arms today if not yet passed)
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr == todayStr) {
      final updatedHabit = updated.firstWhere(
        (h) => h.id == habit.id,
        orElse: () => currentHabit,
      );
      await _scheduleReminder(updatedHabit, isCompletedToday: !isCompleted);
    }

    if (!habit.id.startsWith('temp_')) {
      unawaited(_dispatchToggleApi(habit.id, dateStr, isCompleted));
    }
  }

  Future<void> _dispatchToggleApi(
    String habitId,
    String dateStr,
    bool wasCompleted,
  ) async {
    try {
      final client = DioClient();
      if (wasCompleted) {
        await client.dio.delete('/habit-logs/$habitId/$dateStr');
      } else {
        await client.dio.post('/habit-logs', data: {
          'habitId': habitId,
          'date': dateStr,
        });
      }
    } catch (_) {
      // Enqueue to background sync manager
      await SyncManager.instance.enqueue(
        SyncAction(
          type: SyncActionType.toggleHabit,
          endpoint: wasCompleted
              ? '/habit-logs/$habitId/$dateStr'
              : '/habit-logs',
          method: wasCompleted ? 'DELETE' : 'POST',
          payload:
              wasCompleted ? null : {'habitId': habitId, 'date': dateStr},
        ),
      );
    }
  }

  /// Batch applies widget toggles at once to eliminate staggered one-by-one UI updates.
  Future<void> batchApplyWidgetToggles(
      List<Map<String, dynamic>> toggles) async {
    if (toggles.isEmpty) return;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final currentHabits = state.valueOrNull ?? await _readCachedHabits() ?? [];
    if (currentHabits.isEmpty) return;

    var updated = List<HabitModel>.from(currentHabits);
    bool anyChanged = false;

    for (final item in toggles) {
      final habitId = item['id'] as String?;
      final desiredCompleted = item['completed'] as bool?;
      if (habitId == null || habitId.isEmpty || desiredCompleted == null) {
        continue;
      }

      updated = updated.map((h) {
        if (h.id != habitId) return h;
        final isCompleted = h.completedDates.contains(todayStr);
        if (isCompleted != desiredCompleted) {
          anyChanged = true;
          final newCompleted = List<String>.from(h.completedDates);
          final newSkipped = List<String>.from(h.skippedDates);
          int newStreak = h.currentStreak;
          int newTotal = h.totalCompleted;
          if (desiredCompleted) {
            if (!newCompleted.contains(todayStr)) newCompleted.add(todayStr);
            newSkipped.remove(todayStr);
            newStreak++;
            newTotal++;
          } else {
            newCompleted.remove(todayStr);
            if (newStreak > 0) newStreak--;
            if (newTotal > 0) newTotal--;
          }
          final toggleKey = '${h.id}_$todayStr';
          _recentLocalToggles[toggleKey] = (desiredCompleted, DateTime.now());
          if (!h.id.startsWith('temp_')) {
            unawaited(_dispatchToggleApi(h.id, todayStr, !desiredCompleted));
          }
          return h.copyWith(
            completedDates: newCompleted,
            skippedDates: newSkipped,
            currentStreak: newStreak,
            totalCompleted: newTotal,
          );
        }
        return h;
      }).toList();
    }

    if (anyChanged) {
      _dirtySinceLoad = true;
      state = AsyncValue.data(updated);
      await _cacheHabits(updated);
    }
  }

  Future<void> skipHabit({
    required HabitModel habit,
    required DateTime date,
    required String reason,
  }) async {
    _dirtySinceLoad = true;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final toggleKey = '${habit.id}_$dateStr';
    _recentLocalToggles[toggleKey] = (false, DateTime.now());
    DioCacheInterceptor().invalidateTag('habits');

    // Optimistic update, then persist locally. Skipping is idempotent (never
    // adds the same date twice) and always clears any completion for that day
    // so a habit is in exactly one state per date.
    final updated = (state.valueOrNull ?? <HabitModel>[]).map((h) {
      if (h.id != habit.id) return h;
      final wasCompleted = h.completedDates.contains(dateStr);
      final newSkipped = List<String>.from(h.skippedDates);
      if (!newSkipped.contains(dateStr)) newSkipped.add(dateStr);
      final newCompleted = List<String>.from(h.completedDates)..remove(dateStr);
      int newTotal = h.totalCompleted;
      if (wasCompleted && newTotal > 0) newTotal--;
      final temp = h.copyWith(
        skippedDates: newSkipped,
        completedDates: newCompleted,
        totalCompleted: newTotal,
      );
      final newHabitStreak = calculateHabitStreak(temp);
      return temp.copyWith(currentStreak: newHabitStreak);
    }).toList();
    state = AsyncValue.data(updated);
    await _cacheHabits(updated);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (dateStr == todayStr) {
      final updatedHabit = updated.firstWhere(
        (h) => h.id == habit.id,
        orElse: () => habit,
      );
      await _scheduleReminder(updatedHabit, isCompletedToday: true);
    }

    if (!habit.id.startsWith('temp_')) {
      try {
        final client = DioClient();
        await client.dio.post('/habit-logs/skip', data: {
          'habitId': habit.id,
          'date': dateStr,
          'reason': reason,
        });
      } catch (_) {
        // Enqueue to background sync manager
        await SyncManager.instance.enqueue(
          SyncAction(
            type: SyncActionType.skipHabit,
            endpoint: '/habit-logs/skip',
            method: 'POST',
            payload: {
              'habitId': habit.id,
              'date': dateStr,
              'reason': reason,
            },
          ),
        );
      }
    }
  }

  Future<void> deleteHabit(String habitId) async {
    _dirtySinceLoad = true;
    DioCacheInterceptor().invalidateTag('habits');
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
      } catch (_) {
        // Enqueue to background sync manager
        await SyncManager.instance.enqueue(
          SyncAction(
            type: SyncActionType.deleteHabit,
            endpoint: '/habits/$habitId',
            method: 'DELETE',
          ),
        );
      }
    }
  }

  // ─── Device-side reminders (local fallback for the backend FCM push) ────────

  /// (Re)arm local reminders for every habit that has a reminderTime.
  /// If already completed today, schedules the next instance starting tomorrow
  /// so today's reminder is skipped while tomorrow's remains active.
  Future<void> _rescheduleAllReminders(List<HabitModel> habits) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final habit in habits) {
      final isCompletedToday = habit.completedDates.contains(todayStr);
      await _scheduleReminder(habit, isCompletedToday: isCompletedToday);
    }
  }

  /// Schedule the device-side reminder for [habit] (no-op without a time).
  Future<void> _scheduleReminder(
    HabitModel habit, {
    bool isCompletedToday = false,
  }) async {
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
      skipToday: isCompletedToday,
    );
  }

  // ─── Local cache (offline-first) ─────────────────────────────────────────────

  static Future<void> _cacheHabits(List<HabitModel> habits) async {
    await JsonFileCache.write(
      _cacheName,
      habits.map((h) => h.toJson()).toList(),
    );
    await _syncHomeWidgets(habits);
  }

  static Future<void> _syncHomeWidgets(List<HabitModel> habits) async {
    try {
      final streak = calculateCurrentStreak(habits);
      await HomeWidgetService.instance.syncHabitsData(
        habits: habits,
        overallStreak: streak,
      );
    } catch (_) {}
  }

  static Future<List<HabitModel>?> _readCachedHabits() async {
    return JsonFileCache.read(
      _cacheName,
      (json) => (json as List)
          .map((e) => HabitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<HabitModel>> _reconcilePendingWidgetToggles(
      List<HabitModel> habits) async {
    if (habits.isEmpty) return habits;
    try {
      final pendingStr =
          await HomeWidget.getWidgetData<String>('pending_widget_toggles');
      if (pendingStr == null || pendingStr.isEmpty || pendingStr == '[]') {
        return habits;
      }
      final list = jsonDecode(pendingStr) as List<dynamic>;
      if (list.isEmpty) return habits;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var updated = List<HabitModel>.from(habits);
      bool anyChanged = false;

      for (final item in list) {
        if (item is Map) {
          final habitId = item['id'] as String?;
          final desiredCompleted = item['completed'] as bool?;
          if (habitId == null || habitId.isEmpty) continue;

          updated = updated.map((h) {
            if (h.id != habitId) return h;
            final isCompleted = h.completedDates.contains(todayStr);
            if (desiredCompleted != null && isCompleted != desiredCompleted) {
              anyChanged = true;
              final newCompleted = List<String>.from(h.completedDates);
              final newSkipped = List<String>.from(h.skippedDates);
              int newStreak = h.currentStreak;
              int newTotal = h.totalCompleted;
              if (desiredCompleted) {
                if (!newCompleted.contains(todayStr)) {
                  newCompleted.add(todayStr);
                }
                newSkipped.remove(todayStr);
                newStreak++;
                newTotal++;
              } else {
                newCompleted.remove(todayStr);
                if (newStreak > 0) newStreak--;
                if (newTotal > 0) newTotal--;
              }
              // Record in _recentLocalToggles so in-flight or subsequent server fetch preserves it
              final toggleKey = '${h.id}_$todayStr';
              _recentLocalToggles[toggleKey] =
                  (desiredCompleted, DateTime.now());
              return h.copyWith(
                completedDates: newCompleted,
                skippedDates: newSkipped,
                currentStreak: newStreak,
                totalCompleted: newTotal,
              );
            }
            return h;
          }).toList();
        }
      }

      if (anyChanged) {
        await _cacheHabits(updated);
      }
      return updated;
    } catch (_) {
      return habits;
    }
  }
}

// ─── Helpers & Providers ───────────────────────────────────────────────────────

/// Per-habit streak: counts consecutive *scheduled* days (walking backward
/// from [from], defaulting to today) on which the habit has a completion.
/// Unscheduled days are ignored and never break the streak; a scheduled day
/// that is skipped or missing breaks it. A habit with no repeat day selected
/// is treated as daily.
int calculateHabitStreak(HabitModel habit, {DateTime? from}) {
  if (habit.completedDates.isEmpty && habit.currentStreak == 0) return 0;
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
  // Return the calculated streak or habit.currentStreak if it has historical streak
  return streak > habit.currentStreak ? streak : habit.currentStreak;
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

  final current = calculateCurrentStreak(habits, from: from);
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
        data: (habits) =>
            habits.fold<int>(0, (sum, h) => sum + h.completedDates.length),
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

// ─── Weekly Habit Stats (Single Source of Truth) ─────────────────────────────

class WeeklyHabitStats {
  final int completedCount;
  final int scheduledCount;
  final int percent;

  const WeeklyHabitStats({
    required this.completedCount,
    required this.scheduledCount,
    required this.percent,
  });

  static const empty = WeeklyHabitStats(
    completedCount: 0,
    scheduledCount: 0,
    percent: 0,
  );
}

WeeklyHabitStats calculateWeeklyHabitStats(List<HabitModel> habits,
    {DateTime? now}) {
  if (habits.isEmpty) return WeeklyHabitStats.empty;

  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final diff = today.weekday % 7; // Sunday anchor (matches Habits screen)
  final weekStart = today.subtract(Duration(days: diff));

  int scheduledCount = 0;
  int completedCount = 0;

  for (int i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final day = DateTime(date.year, date.month, date.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final weekdayIndex = date.weekday - 1; // 0 = Monday, 6 = Sunday

    for (final habit in habits) {
      final hasRepeatDay = habit.repeatDays.any((d) => d);
      final isScheduled = !hasRepeatDay ||
          (weekdayIndex >= 0 &&
              weekdayIndex < habit.repeatDays.length &&
              habit.repeatDays[weekdayIndex]);

      if (isScheduled) {
        scheduledCount++;
        if (!day.isAfter(today) && habit.completedDates.contains(dateStr)) {
          completedCount++;
        }
      }
    }
  }

  final percent = scheduledCount > 0
      ? ((completedCount / scheduledCount) * 100).round().clamp(0, 100)
      : 0;

  return WeeklyHabitStats(
    completedCount: completedCount,
    scheduledCount: scheduledCount,
    percent: percent,
  );
}

final weeklyHabitStatsProvider = Provider<WeeklyHabitStats>((ref) {
  return ref.watch(habitsProvider).when(
        data: (habits) => calculateWeeklyHabitStats(habits),
        loading: () => WeeklyHabitStats.empty,
        error: (_, __) => WeeklyHabitStats.empty,
      );
});
