/// User profile for calorie target calculation. Edit values below to match yourself.
class UserProfile {
  // TODO: fill in your real values
  static const int ageYears = 30;
  static const double heightCm = 170.0;
  static const double weightKg = 65.0;

  // Mifflin-St Jeor activity factor: 1.2 sedentary, 1.375 light, 1.55 moderate, 1.725 active.
  static const double activityFactor = 1.375;

  // Twins, exclusively breastfed: ~500 kcal per baby per day.
  static const int breastfeedingSupplementKcal = 1000;
}
