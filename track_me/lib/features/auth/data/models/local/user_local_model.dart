import 'package:isar/isar.dart';

part 'user_local_model.g.dart';

@collection
class UserLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;

  late String name;
  late String email;
  String? avatarUrl;
  DateTime? lastSyncedAt;
}
