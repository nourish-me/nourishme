import '../models/user_profile_settings.dart';

double _bmrFemale(UserProfileSettings p) =>
    10 * p.weightKg + 6.25 * p.heightCm - 5 * p.ageYears - 161;

int calculateBmrTdee(UserProfileSettings profile) =>
    (_bmrFemale(profile) * profile.activityFactor).round();

int calculateDailyCalorieTarget(UserProfileSettings profile) =>
    calculateBmrTdee(profile) + profile.milkSupplementKcal;
