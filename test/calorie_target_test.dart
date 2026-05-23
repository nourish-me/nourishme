import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/user_profile_settings.dart';
import 'package:nurturetrack/services/calorie_target.dart';

// Locks the calorie/macro math against the constants Vanessa's domain
// research established (DGE 2025, Mifflin-St Jeor, EFSA volume-based
// lactation). If anyone tweaks the formula by accident these go red.
void main() {
  group('Mifflin-St Jeor BMR + activity (calculateBmrTdee)', () {
    test('sedentary 30y/165cm/65kg woman', () {
      final p = _profile(
        birthYearsBack: 30,
        heightCm: 165,
        weightKg: 65,
        activityFactor: 1.2,
      );
      // BMR = 10*65 + 6.25*165 - 5*30 - 161 = 650 + 1031.25 - 150 - 161
      //     = 1370.25
      // TDEE = 1370.25 * 1.2 = 1644.3 → rounds to 1644
      expect(calculateBmrTdee(p), 1644);
    });

    test('moderately active 35y/170cm/70kg woman', () {
      final p = _profile(
        birthYearsBack: 35,
        heightCm: 170,
        weightKg: 70,
        activityFactor: 1.375,
      );
      // BMR = 700 + 1062.5 - 175 - 161 = 1426.5
      // TDEE = 1426.5 * 1.375 = 1961.4375 → 1961
      expect(calculateBmrTdee(p), 1961);
    });

    test('uses currentAge derived from birthdate when present', () {
      final now = DateTime.now();
      final p = UserProfileSettings(
        ageYears: 999, // intentionally wrong; should be ignored
        birthdate: DateTime(now.year - 28, now.month, now.day - 1),
        heightCm: 165,
        weightKg: 60,
        activityFactor: 1.2,
        numChildrenNursing: 0,
        milkSharePercent: 0,
        childrenAgeGroup: 0,
      );
      // BMR for age 28 = 600 + 1031.25 - 140 - 161 = 1330.25
      // TDEE = 1330.25 * 1.2 = 1596.3 → 1596
      expect(calculateBmrTdee(p), 1596);
    });
  });

  group('Pregnancy supplement (calculatePregnancySupplement)', () {
    test('not pregnant → 0', () {
      expect(calculatePregnancySupplement(_pregnant(isPregnant: false)), 0);
    });
    test('T1 → 0 (DGE: no kcal supplement in first trimester)', () {
      expect(calculatePregnancySupplement(_pregnant(trimester: 1)), 0);
    });
    test('T2 → +250 kcal', () {
      expect(calculatePregnancySupplement(_pregnant(trimester: 2)), 250);
    });
    test('T3 → +500 kcal', () {
      expect(calculatePregnancySupplement(_pregnant(trimester: 3)), 500);
    });
  });

  group('Lactation supplement (calculateLactationSupplement)', () {
    test('no children nursing → 0', () {
      final p = _profile(numChildrenNursing: 0, dailyMilkVolumeMl: 0);
      expect(calculateLactationSupplement(p), 0);
    });

    test('explicit milkSupplementKcal override wins', () {
      final p = _profile(
        numChildrenNursing: 1,
        dailyMilkVolumeMl: 780,
        milkSupplementKcal: 666,
      );
      expect(calculateLactationSupplement(p), 666);
    });

    test('volume-based: 780 ml × 0.84 = 655 kcal', () {
      final p = _profile(
        numChildrenNursing: 1,
        dailyMilkVolumeMl: 780,
      );
      expect(calculateLactationSupplement(p), 655);
    });

    test('twins exclusive 0-6mo: 1500 ml × 0.84 = 1260 kcal', () {
      final p = _profile(
        numChildrenNursing: 2,
        dailyMilkVolumeMl: 1500,
      );
      expect(calculateLactationSupplement(p), 1260);
    });

    test('falls back to estimated volume when dailyMilkVolumeMl == 0', () {
      // estimatedDailyVolumeMl(1, ageGroup 0, sharePercent 100) = 780
      // supplement = 780 * 0.84 = 655
      final p = _profile(
        numChildrenNursing: 1,
        childrenAgeGroup: 0,
        milkSharePercent: 100,
        dailyMilkVolumeMl: 0,
      );
      expect(calculateLactationSupplement(p), 655);
    });
  });

  group('Daily kcal target = BMR·PAL + pregnancy + lactation', () {
    test('twin-mother test case (Vanessa-shaped)', () {
      final p = UserProfileSettings(
        ageYears: 34,
        birthdate: null,
        heightCm: 167,
        weightKg: 56,
        activityFactor: 1.375,
        numChildrenNursing: 2,
        dailyMilkVolumeMl: 1500,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
      );
      // BMR = 560 + 1043.75 - 170 - 161 = 1272.75
      // TDEE = 1272.75 * 1.375 = 1750.03125 → 1750
      // Lactation = 1500 * 0.84 = 1260
      // Total = 1750 + 0 + 1260 = 3010
      expect(calculateBmrTdee(p), 1750);
      expect(calculateLactationSupplement(p), 1260);
      expect(calculateDailyCalorieTarget(p), 3010);
    });
  });

  group('Macro split (calculateMacroTargets, DGE defaults)', () {
    test('lactating woman: protein at 1.2 g/kg', () {
      final p = _profile(
        numChildrenNursing: 1,
        weightKg: 60,
        activityFactor: 1.375,
      );
      // protein_g = 60 * 1.2 = 72 g → kcal 288 → 12 % of 2400 = 288, ok
      // Pick a clean target: 2500 kcal
      final m = calculateMacroTargets(p, 2500);
      // protein 72g should be near 12 % → 300 kcal → 75g (rounding)
      expect(m.proteinG, inInclusiveRange(70, 76));
      // fat at 30 % = 750 kcal / 9 = 83 g
      expect(m.fatG, inInclusiveRange(82, 84));
      // carbs the remainder
      expect(m.proteinG + m.carbsG + m.fatG, greaterThan(0));
    });

    test('pregnant T3 woman: protein at 1.0 g/kg', () {
      final p = _pregnant(trimester: 3).copyWith(weightKg: 65);
      final m = calculateMacroTargets(p, 2200);
      // protein_g = 65 g
      expect(m.proteinG, inInclusiveRange(63, 67));
    });

    test('custom protein override wins over auto split', () {
      final p = _profile(
        numChildrenNursing: 1,
        weightKg: 60,
        customProteinPct: 25,
      );
      final m = calculateMacroTargets(p, 2000);
      // protein_g = 2000 * 0.25 / 4 = 125
      expect(m.proteinG, 125);
    });
  });

  group('JSON roundtrip (UserProfileSettings)', () {
    test('round-trips lossless including birthdate', () {
      final original = UserProfileSettings(
        ageYears: 34,
        birthdate: DateTime(1992, 2, 14),
        heightCm: 167,
        weightKg: 56.5,
        activityFactor: 1.375,
        isPregnant: false,
        trimester: null,
        numChildrenNursing: 2,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
        dailyMilkVolumeMl: 1500,
        milkSupplementKcal: 0,
        customProteinPct: 0,
        customFatPct: 0,
      );
      final json = original.toJson();
      final back = UserProfileSettings.fromJson(json);
      expect(back.ageYears, original.ageYears);
      expect(back.birthdate, original.birthdate);
      expect(back.heightCm, original.heightCm);
      expect(back.weightKg, original.weightKg);
      expect(back.activityFactor, original.activityFactor);
      expect(back.numChildrenNursing, original.numChildrenNursing);
      expect(back.dailyMilkVolumeMl, original.dailyMilkVolumeMl);
    });

    test('fromJson tolerates missing birthdate (legacy entries)', () {
      final json = {
        'ageYears': 30,
        'heightCm': 165.0,
        'weightKg': 60.0,
        'activityFactor': 1.375,
        'numChildrenNursing': 1,
        'milkSharePercent': 100,
        'childrenAgeGroup': 0,
        'dailyMilkVolumeMl': 0,
      };
      final p = UserProfileSettings.fromJson(json);
      expect(p.birthdate, isNull);
      expect(p.currentAge, 30);
    });
  });
}

// -------- helpers --------

UserProfileSettings _profile({
  int birthYearsBack = 30,
  double heightCm = 165,
  double weightKg = 60,
  double activityFactor = 1.375,
  int numChildrenNursing = 0,
  int dailyMilkVolumeMl = 0,
  int milkSupplementKcal = 0,
  int milkSharePercent = 100,
  int childrenAgeGroup = 0,
  int customProteinPct = 0,
  int customFatPct = 0,
}) {
  return UserProfileSettings(
    ageYears: birthYearsBack,
    birthdate: null,
    heightCm: heightCm,
    weightKg: weightKg,
    activityFactor: activityFactor,
    numChildrenNursing: numChildrenNursing,
    milkSharePercent: milkSharePercent,
    childrenAgeGroup: childrenAgeGroup,
    dailyMilkVolumeMl: dailyMilkVolumeMl,
    milkSupplementKcal: milkSupplementKcal,
    customProteinPct: customProteinPct,
    customFatPct: customFatPct,
  );
}

UserProfileSettings _pregnant({bool isPregnant = true, int trimester = 1}) {
  return UserProfileSettings(
    ageYears: 30,
    birthdate: null,
    heightCm: 165,
    weightKg: 60,
    activityFactor: 1.375,
    isPregnant: isPregnant,
    trimester: trimester,
    numChildrenNursing: 0,
    milkSharePercent: 0,
    childrenAgeGroup: 0,
  );
}
