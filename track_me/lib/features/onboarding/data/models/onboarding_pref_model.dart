import 'package:isar/isar.dart';

part 'onboarding_pref_model.g.dart';

@collection
class OnboardingPrefModel {
  Id id = 1; // Single record using fixed id

  bool isCompleted = false;
  DateTime? completedAt;
}
