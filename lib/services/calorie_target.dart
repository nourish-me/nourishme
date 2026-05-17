import '../models/user_profile_settings.dart';

/// Mifflin-St Jeor BMR for women plus activity factor plus milk-supply supplement.
int calculateDailyCalorieTarget(UserProfileSettings profile) {
  final bmr = 10 * profile.weightKg +
      6.25 * profile.heightCm -
      5 * profile.ageYears -
      161;
  final tdee = bmr * profile.activityFactor;
  final target = tdee + profile.milkSupplementKcal;
  return target.round();
}
