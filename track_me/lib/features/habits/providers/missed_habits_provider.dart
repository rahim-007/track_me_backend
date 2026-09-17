import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../../core/local/isar_service.dart';
import '../../../core/models/app_settings_model.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/habit_model.dart';
import '../data/models/local/missed_habit_reason_local_model.dart';
import 'habits_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

/// Represents one missed habit plus the user's answer (mutable per card).
///
/// Before asking for a reason we first ask "Did you complete this habit
/// yesterday?":
/// - `didComplete == true`  → the user actually did it → we mark it completed
///   for yesterday and never ask for a reason.
/// - `didComplete == false` → it was genuinely missed → a reason is required.
/// - `didComplete == null`  → not answered yet.
class MissedHabitEntry {
  final HabitModel habit;
  String reason;
  bool? didComplete;

  MissedHabitEntry({required this.habit, this.reason = '', this.didComplete});

  /// Fully resolved once answered, and (when missed) a valid reason is given.
  bool get isValid {
    if (didComplete == null) return false;
    if (didComplete == true) return true; // marked done — no reason needed
    return reason.trim().length >= 5;
  }

  /// Whether this entry was answered "No" and therefore needs a reason.
  bool get needsReason => didComplete == false;
}

// ─── Global flag — set by splash, read by dashboard ──────────────────────────

/// Set to `true` by the splash screen when missed habits are detected.
/// Dashboard reads this and shows the reflection dialog on first frame.
final shouldShowReflectionProvider = StateProvider<bool>((ref) => false);

// ─── Missed habits check ──────────────────────────────────────────────────────

/// Returns the list of habits that were missed yesterday and have not yet had
/// a reason submitted or been marked completed. Returns empty list if nothing needs attention.
final missedYesterdayHabitsProvider = FutureProvider<List<HabitModel>>((ref) async {
  // 1. Read habits reactively first — loads immediately from local cache or memory
  final habitsState = ref.watch(habitsProvider);
  final habits = habitsState.valueOrNull;

  if (habits == null || habits.isEmpty) {
    debugPrint('[MissedHabits] habits list is null or empty');
    return [];
  }

  // 2. Determine yesterday's exact calendar date
  final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
  final yesterdayDateOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

  debugPrint('[MissedHabits] Checking missed habits for yesterday: $yesterdayStr');

  // 3. Fast offline-first check for already reflected habits in local Isar DB (< 1ms)
  final alreadyReflectedIds = <String>{};

  if (IsarService.isAvailable) {
    try {
      final isar = IsarService.instance;
      final localReasons = await isar.missedHabitReasonLocalModels
          .where()
          .missedDateEqualTo(yesterdayStr)
          .findAll();
      for (final r in localReasons) {
        alreadyReflectedIds.add(r.habitId);
      }
      debugPrint('[MissedHabits] Found ${alreadyReflectedIds.length} reflected habit(s) in local Isar');
    } catch (e) {
      debugPrint('[MissedHabits] Failed reading local missed reasons: $e');
    }
  }

  // 4. Background non-blocking sync with backend for reasons submitted on other devices
  unawaited(_syncBackendMissedReasons(ref, yesterdayStr, alreadyReflectedIds));

  // 5. Filter: missed = scheduled for yesterday AND created on/before yesterday AND not completed AND not skipped AND not already reflected
  final dayIndex = yesterday.weekday - 1; // 0=Mon … 6=Sun

  final missed = habits.where((habit) {
    // 5a. Exclude habits created after yesterday (e.g. created today). Use .toLocal() for accurate comparison.
    final localCreatedAt = habit.createdAt.toLocal();
    final createdDateOnly = DateTime(
      localCreatedAt.year,
      localCreatedAt.month,
      localCreatedAt.day,
    );
    final isCreatedAfterYesterday = createdDateOnly.isAfter(yesterdayDateOnly);

    if (isCreatedAfterYesterday) {
      return false;
    }

    // 5b. Schedule check: if no specific repeat day selected, treat as daily
    final hasRepeatDay = habit.repeatDays.any((d) => d);
    final wasScheduled = hasRepeatDay
        ? (dayIndex >= 0 && dayIndex < habit.repeatDays.length && habit.repeatDays[dayIndex])
        : true;

    if (!wasScheduled) {
      return false;
    }

    final isCompleted = habit.completedDates.contains(yesterdayStr);
    final isSkipped = habit.skippedDates.contains(yesterdayStr);
    final isReflected = alreadyReflectedIds.contains(habit.id);

    debugPrint('[MissedHabits] Habit "${habit.name}": createdAt=${habit.createdAt.toLocal()} (afterYesterday=$isCreatedAfterYesterday), scheduled=$wasScheduled, completed=$isCompleted, skipped=$isSkipped, alreadyReflected=$isReflected');

    return !isCompleted && !isSkipped && !isReflected;
  }).toList();

  debugPrint('[MissedHabits] Final missed habits count for $yesterdayStr: ${missed.length}');
  return missed;
});

/// Non-blocking sync to fetch external reasons from backend without stalling the UI.
Future<void> _syncBackendMissedReasons(
  Ref ref,
  String dateStr,
  Set<String> localReflectedIds,
) async {
  try {
    final client = DioClient();
    final response = await client.dio.get(
      '/missed-reasons',
      queryParameters: {'date': dateStr},
    );
    final data = response.data;
    if (data is List) {
      var hasNewReasons = false;
      for (final item in data) {
        if (item is Map && item['habitId'] != null) {
          final hId = item['habitId'].toString();
          if (!localReflectedIds.contains(hId)) {
            localReflectedIds.add(hId);
            hasNewReasons = true;
          }
        }
      }
      if (hasNewReasons) {
        debugPrint('[MissedHabits] Found new reflected habits from backend, refreshing...');
        ref.invalidateSelf();
      }
    }
  } catch (e) {
    debugPrint('[MissedHabits] Backend missed-reasons sync skipped/failed ($e)');
  }
}

// ─── Save reasons notifier ────────────────────────────────────────────────────

class MissedReasonsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MissedReasonsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Resolve the reflection: habits answered "Yes" are marked completed for
  /// yesterday; habits answered "No" get a reason saved locally + synced.
  Future<bool> saveReasons({
    required List<MissedHabitEntry> entries,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    try {
      // Split the user's answers: "yes" → actually completed (no reason),
      // "no" → genuinely missed (reason required).
      final completedEntries =
          entries.where((e) => e.didComplete == true).toList();
      final missedEntries =
          entries.where((e) => e.didComplete == false).toList();

      // ── 1. Mark "yes" habits as completed yesterday ──
      // Uses the same optimistic + backend-sync path the habit grid uses, so
      // streaks / dashboard reflect the completion immediately.
      for (final entry in completedEntries) {
        await _ref
            .read(habitsProvider.notifier)
            .toggleCompletion(entry.habit, yesterday);
      }

      // ── 2. Save reasons for genuinely missed habits (offline-first) ──
      if (missedEntries.isNotEmpty) {
        await _saveReasonsLocal(missedEntries, yesterdayStr, userId);
        await _syncToBackend(missedEntries, yesterdayStr);
      }

      // ── 3. Mark reflection as done to prevent re-showing today ──
      await _markReflectionDone(yesterdayStr);

      // ── 4. Invalidate providers so UI updates immediately ──
      _ref.invalidate(missedYesterdayHabitsProvider);
      _ref.invalidate(habitsProvider);
      _ref.invalidate(missedReasonsForDateProvider(yesterdayStr));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Persist missed-habit reasons to Isar (local, offline-first).
  Future<void> _saveReasonsLocal(
    List<MissedHabitEntry> entries,
    String yesterdayStr,
    String userId,
  ) async {
    if (!IsarService.isAvailable) return;
    final isar = IsarService.instance;

    // Fetch all existing records for yesterday using indexed where() query
    final allForDate = await isar.missedHabitReasonLocalModels
        .where()
        .missedDateEqualTo(yesterdayStr)
        .findAll();

    await isar.writeTxn(() async {
      for (final entry in entries) {
        // Find existing record for this habit via in-memory filter
        final existing = allForDate
            .where((r) => r.habitId == entry.habit.id)
            .firstOrNull;

        if (existing != null) {
          existing.reason = entry.reason.trim();
          existing.isSynced = false;
          await isar.missedHabitReasonLocalModels.put(existing);
        } else {
          final model = MissedHabitReasonLocalModel()
            ..habitId = entry.habit.id
            ..habitName = entry.habit.name
            ..habitEmoji = entry.habit.emoji
            ..userId = userId
            ..missedDate = yesterdayStr
            ..reason = entry.reason.trim()
            ..createdAt = DateTime.now()
            ..isSynced = false;
          await isar.missedHabitReasonLocalModels.put(model);
        }
      }
    });
  }

  /// Record that today's reflection is done so it doesn't re-show today.
  Future<void> _markReflectionDone(String yesterdayStr) async {
    if (!IsarService.isAvailable) return;
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final settings = await isar.appSettingsModels.get(1) ?? AppSettingsModel();
      settings.lastReflectionDate = yesterdayStr;
      await isar.appSettingsModels.put(settings);
    });
  }

  /// Backend sync. Marks local records as synced on success.
  Future<void> _syncToBackend(List<MissedHabitEntry> entries, String yesterdayStr) async {
    try {
      final client = DioClient();
      final payload = entries
          .map((e) => {
                'habitId': e.habit.id,
                'missedDate': yesterdayStr,
                'reason': e.reason.trim(),
              })
          .toList();
      final res = await client.dio.post('/missed-reasons', data: payload);
      debugPrint('[MissedHabits] Synced reasons to backend: ${res.statusCode}');

      // Mark as synced in Isar
      if (IsarService.isAvailable) {
        final isar = IsarService.instance;
        final allForDate = await isar.missedHabitReasonLocalModels
            .where()
            .missedDateEqualTo(yesterdayStr)
            .findAll();
        final unsynced = allForDate.where((r) => !r.isSynced).toList();
        if (unsynced.isNotEmpty) {
          await isar.writeTxn(() async {
            for (final r in unsynced) {
              r.isSynced = true;
              await isar.missedHabitReasonLocalModels.put(r);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[MissedHabits] Sync failed: $e');
      // Silently fail — will retry on next launch if not synced
    }
  }
}

final missedReasonsNotifierProvider =
    StateNotifierProvider<MissedReasonsNotifier, AsyncValue<void>>(
  (ref) => MissedReasonsNotifier(ref),
);

/// Maps habitId -> reason for a specific date (e.g. yesterday).
final missedReasonsForDateProvider =
    FutureProvider.family<Map<String, String>, String>((ref, dateStr) async {
  final result = <String, String>{};

  if (IsarService.isAvailable) {
    try {
      final isar = IsarService.instance;
      final local = await isar.missedHabitReasonLocalModels
          .where()
          .missedDateEqualTo(dateStr)
          .findAll();
      for (final r in local) {
        result[r.habitId] = r.reason;
      }
    } catch (_) {}
  }

  try {
    final client = DioClient();
    final response = await client.dio.get(
      '/missed-reasons',
      queryParameters: {'date': dateStr},
    );
    final data = response.data;
    if (data is List) {
      for (final item in data) {
        if (item is Map && item['habitId'] != null && item['reason'] != null) {
          result[item['habitId'].toString()] = item['reason'].toString();
        }
      }
    }
  } catch (e) {
    debugPrint('[MissedReasonsProvider] dio fetch error: $e');
  }
  debugPrint('[MissedReasonsProvider] dateStr=$dateStr, result=$result');
  return result;
});
