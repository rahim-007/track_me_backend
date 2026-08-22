import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/data/models/local/user_local_model.dart';
import '../../features/habits/data/models/local/habit_local_model.dart';
import '../../features/habits/data/models/local/missed_habit_reason_local_model.dart';
import '../../features/goals/data/models/local/goal_local_model.dart';
import '../../features/onboarding/data/models/onboarding_pref_model.dart';
import '../models/app_settings_model.dart';
import '../../features/expenses/data/models/local/budget_local_model.dart';
import '../../features/expenses/data/models/local/expense_local_model.dart';

class IsarService {
  IsarService._();

  static Isar? _isar;

  /// Whether Isar is available on this platform.
  static bool get isAvailable => _isar != null && _isar!.isOpen;

  /// In-flight open future so concurrent callers share a single attempt
  /// instead of racing to open the same database twice.
  static Future<void>? _initFuture;

  static Isar get instance {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Isar is not initialized. Call IsarService.initialize() first.');
    }
    return _isar!;
  }

  /// Opens the database once. Safe to call many times: if the database is
  /// already open it completes immediately, and concurrent callers share the
  /// same in-flight future. A failed attempt resets so it can be retried.
  static Future<void> initialize() {
    if (_isar != null && _isar!.isOpen) return Future.value();
    final pending = _initFuture;
    if (pending != null) return pending;

    final future = _open().catchError((Object e) {
      // Allow a retry after a transient failure, then rethrow so the awaiting
      // caller can log it and degrade gracefully (callers guard isAvailable).
      _initFuture = null;
      debugPrint('IsarService: init failed — $e');
      throw e;
    });
    _initFuture = future;
    return future;
  }

  static Future<void> _open() async {
    // Isar v3 does not support Web — skip initialization
    if (kIsWeb) {
      debugPrint('IsarService: Skipping Isar on Web (not supported)');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final schemas = [
      UserLocalModelSchema,
      HabitLocalModelSchema,
      MissedHabitReasonLocalModelSchema,
      GoalLocalModelSchema,
      OnboardingPrefModelSchema,
      AppSettingsModelSchema,
      BudgetLocalModelSchema,
      ExpenseLocalModelSchema,
    ];

    _isar = await Isar.open(
      schemas,
      directory: dir.path,
      name: 'track_me_db_v3',
    );
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  static Future<void> clearAll() async {
    await _isar?.writeTxn(() async {
      await _isar?.clear();
    });
  }
}
