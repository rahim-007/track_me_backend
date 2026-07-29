import 'package:isar/isar.dart';

part 'habit_local_model.g.dart';

@collection
class HabitLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String habitId;

  late String name;
  late String category;
  String? emoji;
  String? color;
  String? reminderTime;
  bool isSynced = false;
  late DateTime createdAt;
  late DateTime updatedAt;
}
