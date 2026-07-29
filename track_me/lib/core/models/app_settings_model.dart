import 'package:isar/isar.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = 1; // Single settings record

  String themeMode = 'light';
  String language = 'en';
  bool notificationsEnabled = true;
  bool habitRemindersEnabled = true;
  bool goalRemindersEnabled = true;
  bool weeklyReportEnabled = true;
}
