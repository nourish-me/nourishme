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
  // effectiveMilkSharePercent collapses the per-child override (Mehrlinge
  // case where each twin gets a different share) into the single value
  // estimatedDailyVolumeMl expects. Defaults to milkSharePercent when no
  // override is set.
  final volume = p.dailyMilkVolumeMl > 0
      ? p.dailyMilkVolumeMl
      : UserProfileSettings.estimatedDailyVolumeMl(
          numChildren: p.numChildrenNursing,
          ageGroup: p.currentChildrenAgeGroup,
          sharePercent: p.effectiveMilkSharePercent,
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
  // Protein g/kg (phase + goal) on the BMI-25-capped reference weight lives in
  // proteinTargetGrams / its helpers below — one source of truth shared with
  // the coach's stated protein goal (CoachSessionManager).
  final proteinG = _proteinReferenceWeight(profile) * _proteinPerKg(profile);
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

// --- Protein target: single source of truth ---------------------------------

// DGE g protein per kg body weight for the user's phase and goal. Baseline 0.8;
// lactation 1.2; pregnancy T2 0.9 / T3 1.0; body-composition goal raises to
// 1.5 (lactation) / 1.6 (otherwise). Pregnancy is never bumped for a goal.
double _proteinPerKg(UserProfileSettings profile) {
  final lactating = profile.numChildrenNursing > 0;
  double perKg = 0.8;
  if (lactating) {
    perKg = 1.2;
  } else if (profile.isPregnant) {
    final t = profile.trimester ?? 1;
    if (t >= 3) {
      perKg = 1.0;
    } else if (t == 2) {
      perKg = 0.9;
    }
  }
  if (profile.goal != CoachGoal.nutrients && !profile.isPregnant) {
    perKg = lactating ? 1.5 : 1.6;
  }
  return perKg;
}

// Reference body weight for the protein target. DGE 2025 Referenzwerte Protein,
// Fussnote a: at overweight (BMI > 25) protein need is derived from normal
// weight, not actual weight. Without this cap the app over-targets protein at
// BMI > 25 (e.g. 90 kg / 165 cm, BMI 33: 90 × 1.2 = 108 g from actual weight;
// correct: weight at BMI 25 = 25 × 1.65 × 1.65 ≈ 68 kg → 68 × 1.2 ≈ 82 g).
double _proteinReferenceWeight(UserProfileSettings profile) {
  final heightM = profile.heightCm / 100;
  final normalWeightAtBmi25 = heightM > 0 ? 25 * heightM * heightM : 0.0;
  return profile.weightKg > normalWeightAtBmi25 && normalWeightAtBmi25 > 0
      ? normalWeightAtBmi25
      : profile.weightKg;
}

/// Canonical daily protein target in grams: DGE g/kg for the phase/goal applied
/// to the BMI-25-capped reference weight. Single source of truth for both the
/// macro split (autoMacroSplit) and the coach's stated protein goal. Previously
/// the coach used a naive weight × 1.2 that ignored the cap and the phase,
/// over-targeting protein for overweight users.
int proteinTargetGrams(UserProfileSettings profile) =>
    (_proteinReferenceWeight(profile) * _proteinPerKg(profile)).round();
