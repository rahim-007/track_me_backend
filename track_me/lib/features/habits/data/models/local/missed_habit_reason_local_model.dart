import 'package:isar/isar.dart';

part 'missed_habit_reason_local_model.g.dart';

/// Local Isar collection for storing missed habit reasons offline.
/// Records are synced to the backend when connectivity is available.
@collection
class MissedHabitReasonLocalModel {
  Id id = Isar.autoIncrement;

  late String habitId;
  late String habitName;
  String? habitEmoji;
  late String userId;

  /// Format: 'yyyy-MM-dd'
  @Index()
  late String missedDate;

  late String reason;
  late DateTime createdAt;
  bool isSynced = false;
}
