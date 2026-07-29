import 'package:isar/isar.dart';

part 'goal_local_model.g.dart';

@collection
class GoalLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String goalId;

  late String name;
  late String category;
  late DateTime targetDate;
  late String priority;
  late String status;
  late double progress;
  bool isSynced = false;
  late DateTime createdAt;
}
