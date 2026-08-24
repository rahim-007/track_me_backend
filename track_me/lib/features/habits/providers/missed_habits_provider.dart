import 'dart:async';
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

/// Represents one missed habit plus the user's typed reason (mutable per card).
class MissedHabitEntry {
  final HabitModel habit;
  String reason;

  MissedHabitEntry({required this.habit, this.reason = ''});

  bool get isValid => reason.trim().length >= 5;
}

// ─── Global flag — set by splash, read by dashboard ──────────────────────────

/// Set to `true` by the splash screen when missed habits are detected.
/// Dashboard reads this and shows the reflection dialog on first frame.
final shouldShowReflectionProvider = StateProvider<bool>((ref) => false);

// ─── Missed habits check ──────────────────────────────────────────────────────

/// Returns the list of habits that were missed yesterday and have not yet had
/// a reason submitted. Returns empty list if nothing needs attention.
final missedYesterdayHabitsProvider = FutureProvider<List<HabitModel>>((ref) async {
  // 1. Determine yesterday's date string
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

  // 2. Check if we already submitted reasons for yesterday (local Isar gate)
  if (IsarService.isAvailable) {
    final isar = IsarService.instance;
    final settings = await isar.appSettingsModels.get(1);
    if (settings?.lastReflectionDate == yesterdayStr) {
      return []; // Already handled today — skip popup
    }
  }

  // 3. Check backend API gate to see if reasons were already submitted for yesterday
  try {
    final client = DioClient();
    final response = await client.dio.get(
      '/missed-reasons/check',
      queryParameters: {'date': yesterdayStr},
    );
    final data = response.data;
    bool hasSubmitted = false;
    if (data is Map<String, dynamic>) {
      if (data['data'] != null && data['data'] is bool) {
        hasSubmitted = data['data'] as bool;
      } else if (data['hasSubmitted'] != null) {
        hasSubmitted = data['hasSubmitted'] as bool;
      }
    } else if (data is bool) {
      hasSubmitted = data;
    }

    if (hasSubmitted) {
      // Save locally to Isar as well so offline checks work next time
      if (IsarService.isAvailable) {
        final isar = IsarService.instance;
        await isar.writeTxn(() async {
          final settings = await isar.appSettingsModels.get(1) ?? AppSettingsModel();
          settings.lastReflectionDate = yesterdayStr;
          await isar.appSettingsModels.put(settings);
        });
      }
      return [];
    }
  } catch (_) {
    // Offline or request failure — proceed with local habit checks
  }

  // 4. Fetch habits list reactively
  final habitsState = ref.watch(habitsProvider);

  return habitsState.when(
    data: (habits) {
      if (habits.isEmpty) return [];

      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day);

      // 5. Filter: missed = created on or before yesterday AND not completed AND not skipped for yesterday
      return habits.where((habit) {
        // Exclude habits created after yesterday (e.g. created today)
        final createdAtDate = DateTime(
          habit.createdAt.year,
          habit.createdAt.month,
          habit.createdAt.day,
        );
        if (createdAtDate.isAfter(yesterdayStart)) {
          return false;
        }

        final isCompleted = habit.completedDates.contains(yesterdayStr);
        final isSkipped = habit.skippedDates.contains(yesterdayStr);
        final dayIndex = yesterday.weekday - 1; // 0=Mon … 6=Sun
        final wasScheduled = habit.repeatDays.length > dayIndex
            ? habit.repeatDays[dayIndex]
            : true;
        return wasScheduled && !isCompleted && !isSkipped;
      }).toList();
    },
    loading: () => Completer<List<HabitModel>>().future, // Suspend the future provider until data is loaded
    error: (err, stack) => [], // If it fails, fallback to empty list
  );
});

// ─── Save reasons notifier ────────────────────────────────────────────────────

class MissedReasonsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MissedReasonsNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Save all reasons locally and sync to backend.
  Future<bool> saveReasons({
    required List<MissedHabitEntry> entries,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

    try {
      // ── 1. Save to Isar (local, offline-first) ──
      if (IsarService.isAvailable) {
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

        // ── 2. Mark reflection as done to prevent re-showing today ──
        await isar.writeTxn(() async {
          final settings = await isar.appSettingsModels.get(1) ?? AppSettingsModel();
          settings.lastReflectionDate = yesterdayStr;
          await isar.appSettingsModels.put(settings);
        });
      }

      // ── 3. Sync to backend ──
      await _syncToBackend(entries, yesterdayStr);

      // ── 4. Invalidate provider so Riverpod updates immediately ──
      _ref.invalidate(missedYesterdayHabitsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
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
      await client.dio.post('/missed-reasons', data: payload);

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
    } catch (_) {
      // Silently fail — will retry on next launch if not synced
    }
  }
}

final missedReasonsNotifierProvider =
    StateNotifierProvider<MissedReasonsNotifier, AsyncValue<void>>(
  (ref) => MissedReasonsNotifier(ref),
);
