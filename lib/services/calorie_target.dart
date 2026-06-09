import '../models/user_profile_settings.dart';

// Mifflin-St Jeor BMR for adult women.
double _bmrFemale(UserProfileSettings p) =>
    10 * p.weightKg + 6.25 * p.heightCm - 5 * p.currentAge - 161;

int calculateBmrTdee(UserProfileSettings profile) =>
    (_bmrFemale(profile) * profile.activityFactor).round();

// Lactation supplement: prefer explicit volume × 0.84 kcal/mL (DGE 2025
// derivation; 0.67 kcal/g energy density / 80% synthesis efficiency).
// Fallback to a manual override (milkSupplementKcal) when the user set one,
// then to the share-based estimate as a last resort.
int calculateLactationSupplement(UserProfileSettings p) {
  if (p.numChildrenNursing <= 0) return 0;
  if (p.milkSupplementKcal > 0) return p.milkSupplementKcal;
  final volume = p.dailyMilkVolumeMl > 0
      ? p.dailyMilkVolumeMl
      : UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: p.numChildrenNursing,
          ageGroup: p.currentChildrenAgeGroup,
          sharePercent: p.milkSharePercent,
        );
  return UserProfileSettings.volumeBasedSupplement(volume);
}

int calculatePregnancySupplement(UserProfileSettings p) {
  if (!p.isPregnant) return 0;
  return UserProfileSettings.pregnancySupplementKcal(p.trimester ?? 1);
}

int calculateDailyCalorieTarget(UserProfileSettings profile) =>
    calculateBmrTdee(profile) +
    calculatePregnancySupplement(profile) +
    calculateLactationSupplement(profile);

class MacroTargets {
  final int proteinG;
  final int carbsG;
  final int fatG;
  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

// DGE 2025: lactation 0-6 mo: 1.2 g protein/kg BW. Pregnancy T2 ~0.9 g/kg,
// T3 ~1.0 g/kg. Non-pregnant non-lactating: 0.8 g/kg. Carbs 50% of kcal,
// fat 30% (PAL <1.7) up to 35% (PAL >=1.7).
// Default macro split as percentages of total kcal. Protein is derived from
// body weight (DGE g/kg), Fat from PAL, Carbs is the remainder so the split
// sums to 100 %.
//
// Body-goal override: when the user opted into 'body' or 'both', protein
// rises to 1.5 g/kg in lactation (still safely above DGE baseline) and
// 1.6 g/kg post-weaning/never-pregnant. Pregnancy is excluded - no
// deficit talk in pregnancy at all, so no recomp protein bump either.
// These values are the conventional muscle-preservation range during a
// moderate deficit; ergänzend zur fachlich bestätigten Defizit-Grenze,
// not from the same brief - flagged in the Settings info card.
({int proteinPct, int fatPct, int carbsPct}) autoMacroSplit(
    UserProfileSettings profile, int targetKcal) {
  final lactating = profile.numChildrenNursing > 0;
  double proteinPerKg = 0.8;
  if (lactating) {
    proteinPerKg = 1.2;
  } else if (profile.isPregnant) {
    final t = profile.trimester ?? 1;
    if (t >= 3) {
      proteinPerKg = 1.0;
    } else if (t == 2) {
      proteinPerKg = 0.9;
    }
  }
  if (profile.goal != CoachGoal.nutrients && !profile.isPregnant) {
    proteinPerKg = lactating ? 1.5 : 1.6;
  }
  final proteinG = profile.weightKg * proteinPerKg;
  final proteinKcal = proteinG * 4;
  final proteinPctRaw = targetKcal > 0
      ? (proteinKcal / targetKcal * 100).round().clamp(5, 50)
      : 15;
  final fatPctRaw = profile.activityFactor >= 1.7 ? 35 : 30;
  final carbsPctRaw = (100 - proteinPctRaw - fatPctRaw).clamp(20, 80);
  return (
    proteinPct: proteinPctRaw,
    fatPct: fatPctRaw,
    carbsPct: carbsPctRaw,
  );
}

MacroTargets calculateMacroTargets(UserProfileSettings profile, int targetKcal) {
  final auto = autoMacroSplit(profile, targetKcal);
  final pPct = profile.customProteinPct > 0
      ? profile.customProteinPct
      : auto.proteinPct;
  final fPct = profile.customFatPct > 0
      ? profile.customFatPct
      : auto.fatPct;
  final cPct = (100 - pPct - fPct).clamp(0, 100);
  return MacroTargets(
    proteinG: (targetKcal * pPct / 100 / 4).round(),
    carbsG: (targetKcal * cPct / 100 / 4).round(),
    fatG: (targetKcal * fPct / 100 / 9).round(),
  );
}
