import '../config/user_profile.dart';

/// Mifflin-St Jeor BMR for women plus activity factor plus breastfeeding supplement.
int calculateDailyCalorieTarget() {
  final bmr = 10 * UserProfile.weightKg +
      6.25 * UserProfile.heightCm -
      5 * UserProfile.ageYears -
      161;
  final tdee = bmr * UserProfile.activityFactor;
  final target = tdee + UserProfile.breastfeedingSupplementKcal;
  return target.round();
}
