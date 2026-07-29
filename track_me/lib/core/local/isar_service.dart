import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/data/models/local/user_local_model.dart';
import '../../features/habits/data/models/local/habit_local_model.dart';
import '../../features/goals/data/models/local/goal_local_model.dart';
import '../../features/onboarding/data/models/onboarding_pref_model.dart';
import '../models/app_settings_model.dart';

class IsarService {
  IsarService._();

  static Isar? _isar;

  static Isar get instance {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Isar is not initialized. Call IsarService.initialize() first.');
    }
    return _isar!;
  }

  static Future<void> initialize() async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserLocalModelSchema,
        HabitLocalModelSchema,
        GoalLocalModelSchema,
        OnboardingPrefModelSchema,
        AppSettingsModelSchema,
      ],
      directory: dir.path,
      name: 'track_me_db',
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
