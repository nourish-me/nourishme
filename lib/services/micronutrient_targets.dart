import '../models/meal_entry.dart';
import '../models/user_profile_settings.dart';

// Daily reference values for the tracked micronutrients, per phase.
//
// Source priority: DGE 2025 (D-A-CH Referenzwerte, 3rd ed., Sept 2025)
// for everything that has a DGE value. Choline is the one exception —
// DGE/D-A-CH has no value, so we use the EFSA Adequate Intake. See
// BETA_DASHBOARDS.md and the Deep Research brief for the full
// rationale and source links.
//
// Reminder: when the DGE Erratum (May 2026) revises any of these,
// update here AND verify the parsePrompt's "5 % of daily target"
// skip threshold still makes sense for the new value.

class MicronutrientTarget {
  final String key; // matches MicronutrientKey constants
  final double value;
  final String unitLabel; // 'µg' or 'mg', for display only
  final String source; // 'DGE 2025' / 'EFSA AI' — shown in detail modal

  const MicronutrientTarget({
    required this.key,
    required this.value,
    required this.unitLabel,
    required this.source,
  });
}

class MicronutrientTargets {
  // Returns the daily target for [key] given the user's phase. Returns
  // null when the nutrient isn't tracked in this phase (e.g. asking
  // for choline targets is fine in any phase since we have EFSA AIs,
  // but asking for nutrients we don't reference returns null).
  //
  // Phase-bucket math: pregnancy uses the user's trimester; lactation
  // uses one flat value (DGE doesn't split lactation by infant age,
  // see Deep Research note). Non-pregnant, non-lactating users get
  // the baseline adult-woman values.
  static MicronutrientTarget? forKey(String key, UserProfileSettings p) {
    final phase = _classifyPhase(p);
    final byPhase = _table[key];
    if (byPhase == null) return null;
    return byPhase[phase];
  }

  // All tracked nutrients with their target for the given user's phase.
  // Convenience for the Settings list + the daily-aggregation provider.
  static Map<String, MicronutrientTarget> allFor(UserProfileSettings p) {
    final phase = _classifyPhase(p);
    final out = <String, MicronutrientTarget>{};
    for (final entry in _table.entries) {
      final target = entry.value[phase];
      if (target != null) out[entry.key] = target;
    }
    return out;
  }

  static _Phase _classifyPhase(UserProfileSettings p) {
    if (p.isPregnant) {
      switch (p.trimester ?? 1) {
        case 2:
          return _Phase.pregnancyT2;
        case 3:
          return _Phase.pregnancyT3;
        default:
          return _Phase.pregnancyT1;
      }
    }
    if (p.numChildrenNursing > 0) return _Phase.lactation;
    return _Phase.baseline;
  }

  // Phase columns. DGE doesn't split lactation by infant age, so we use
  // one lactation column; the Deep Research notes the differences are
  // about milk-dependency framing in the UI, not about the numbers.
  static final Map<String, Map<_Phase, MicronutrientTarget>> _table = {
    MicronutrientKey.folateUg: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.folateUg, value: 300, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.folateUg, value: 550, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.folateUg, value: 550, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.folateUg, value: 550, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.folateUg, value: 450, unitLabel: 'µg', source: 'DGE 2025'),
    },
    MicronutrientKey.ironMg: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.ironMg, value: 16, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.ironMg, value: 27, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.ironMg, value: 27, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.ironMg, value: 27, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.ironMg, value: 16, unitLabel: 'mg', source: 'DGE 2025'),
    },
    MicronutrientKey.iodineUg: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.iodineUg, value: 150, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.iodineUg, value: 220, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.iodineUg, value: 220, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.iodineUg, value: 220, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.iodineUg, value: 230, unitLabel: 'µg', source: 'DGE 2025'),
    },
    MicronutrientKey.vitaminDUg: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.vitaminDUg, value: 20, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.vitaminDUg, value: 20, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.vitaminDUg, value: 20, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.vitaminDUg, value: 20, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.vitaminDUg, value: 20, unitLabel: 'µg', source: 'DGE 2025'),
    },
    MicronutrientKey.dhaMg: {
      // DGE's DHA recommendation is +200 mg/day on top of baseline for
      // pregnancy and lactation; baseline itself has no specific number,
      // so the "target" here is the +200 supplement-equivalent ceiling
      // for non-pregnant women too (defensible for tracking purposes).
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.dhaMg, value: 200, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.dhaMg, value: 200, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.dhaMg, value: 200, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.dhaMg, value: 200, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.dhaMg, value: 200, unitLabel: 'mg', source: 'DGE 2025'),
    },
    MicronutrientKey.b12Ug: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.b12Ug, value: 4.0, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.b12Ug, value: 4.5, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.b12Ug, value: 4.5, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.b12Ug, value: 4.5, unitLabel: 'µg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.b12Ug, value: 5.5, unitLabel: 'µg', source: 'DGE 2025'),
    },
    MicronutrientKey.calciumMg: {
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.calciumMg, value: 1000, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.calciumMg, value: 1000, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.calciumMg, value: 1000, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.calciumMg, value: 1000, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.calciumMg, value: 1000, unitLabel: 'mg', source: 'DGE 2025'),
    },
    MicronutrientKey.cholineMg: {
      // No DGE / D-A-CH value exists. EFSA Adequate Intake (2016).
      // The donut UI should signal this is an awareness nutrient, not a
      // hard target — see the design brief and the Cholin section there.
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.cholineMg, value: 400, unitLabel: 'mg', source: 'EFSA AI'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.cholineMg, value: 480, unitLabel: 'mg', source: 'EFSA AI'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.cholineMg, value: 480, unitLabel: 'mg', source: 'EFSA AI'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.cholineMg, value: 480, unitLabel: 'mg', source: 'EFSA AI'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.cholineMg, value: 520, unitLabel: 'mg', source: 'EFSA AI'),
    },
    MicronutrientKey.zincMg: {
      // DGE Zn depends on phytate intake; using the medium-phytate adult
      // figure as a reasonable default. Pregnancy increment applies from
      // T2 onward per DGE.
      _Phase.baseline: const MicronutrientTarget(
          key: MicronutrientKey.zincMg, value: 8, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT1: const MicronutrientTarget(
          key: MicronutrientKey.zincMg, value: 8, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT2: const MicronutrientTarget(
          key: MicronutrientKey.zincMg, value: 11, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.pregnancyT3: const MicronutrientTarget(
          key: MicronutrientKey.zincMg, value: 11, unitLabel: 'mg', source: 'DGE 2025'),
      _Phase.lactation: const MicronutrientTarget(
          key: MicronutrientKey.zincMg, value: 11, unitLabel: 'mg', source: 'DGE 2025'),
    },
  };
}

enum _Phase { baseline, pregnancyT1, pregnancyT2, pregnancyT3, lactation }

// The 2-3 micronutrients shown by default in the always-visible diary
// strip, per phase + diet. Backed by the Deep Research brief — these
// are the deficiency-weighted picks where (a) Germany has a real
// supply gap and (b) daily food choices can move the number.
//
// Vegan/vegetarian lactation users swap the third slot to B12, which
// is milk-dependent and a real deficiency risk on plant-based diets.
//
// Choline is intentionally NOT in any default top-3. It's available
// for the user to opt into via Settings, where it renders with the
// "awareness" treatment (dashed ring, italic label).
class MicronutrientDefaults {
  static List<String> forProfile(UserProfileSettings p) {
    if (p.isPregnant) {
      switch (p.trimester ?? 1) {
        case 2:
          return const [
            MicronutrientKey.ironMg,
            MicronutrientKey.iodineUg,
            MicronutrientKey.dhaMg,
          ];
        case 3:
          return const [
            MicronutrientKey.ironMg,
            MicronutrientKey.dhaMg,
            MicronutrientKey.iodineUg,
          ];
        default:
          return const [
            MicronutrientKey.folateUg,
            MicronutrientKey.iodineUg,
            MicronutrientKey.vitaminDUg,
          ];
      }
    }
    if (p.numChildrenNursing > 0) {
      final isPlantBased = p.dietStyle == DietStyle.vegan ||
          p.dietStyle == DietStyle.vegetarian;
      // 0-6mo vs 6-12mo: at 6+mo, mother's iron repletion rises in
      // priority (menses returns + cumulatively depleted stores), so
      // iron displaces vitamin D in the omnivore default. Vegan users
      // get B12 in both because milk-dependent infant B12 deficiency
      // can be severe.
      final ageGroup = p.currentChildrenAgeGroup;
      if (ageGroup == 0) {
        return isPlantBased
            ? const [
                MicronutrientKey.iodineUg,
                MicronutrientKey.dhaMg,
                MicronutrientKey.b12Ug,
              ]
            : const [
                MicronutrientKey.iodineUg,
                MicronutrientKey.dhaMg,
                MicronutrientKey.vitaminDUg,
              ];
      }
      return isPlantBased
          ? const [
              MicronutrientKey.iodineUg,
              MicronutrientKey.dhaMg,
              MicronutrientKey.b12Ug,
            ]
          : const [
              MicronutrientKey.iodineUg,
              MicronutrientKey.dhaMg,
              MicronutrientKey.ironMg,
            ];
    }
    // Neither pregnant nor lactating: strip hides itself entirely.
    return const [];
  }

  // True when this slot was swapped due to the user's diet (vegan B12 in
  // lactation). UI uses this to render the leaf glyph on the cell label.
  static bool isDietAdaptedSlot(String key, UserProfileSettings p) {
    if (!p.isPregnant && p.numChildrenNursing > 0) {
      final isPlantBased = p.dietStyle == DietStyle.vegan ||
          p.dietStyle == DietStyle.vegetarian;
      if (isPlantBased && key == MicronutrientKey.b12Ug) return true;
    }
    return false;
  }

  // Stable mono caption shown above the donuts. Driven by the same phase
  // classification the donut defaults use, so updating one keeps the
  // other in sync. Localized in the caller (de strings here are the
  // German source; EN passes through unchanged for now since this is a
  // mono caption with technical-feeling content).
  static String captionDe(UserProfileSettings p) {
    if (p.isPregnant) {
      switch (p.trimester ?? 1) {
        case 2:
          return 'T2 · SCHWANGERSCHAFT';
        case 3:
          return 'T3 · SCHWANGERSCHAFT';
        default:
          return 'T1 · SCHWANGERSCHAFT';
      }
    }
    if (p.numChildrenNursing > 0) {
      return p.currentChildrenAgeGroup == 0
          ? 'STILLZEIT · 0–6 MO'
          : 'STILLZEIT · 6–12 MO';
    }
    return '';
  }

  static String captionEn(UserProfileSettings p) {
    if (p.isPregnant) {
      switch (p.trimester ?? 1) {
        case 2:
          return 'T2 · PREGNANCY';
        case 3:
          return 'T3 · PREGNANCY';
        default:
          return 'T1 · PREGNANCY';
      }
    }
    if (p.numChildrenNursing > 0) {
      return p.currentChildrenAgeGroup == 0
          ? 'LACTATION · 0–6 MO'
          : 'LACTATION · 6–12 MO';
    }
    return '';
  }
}

// Display metadata for a tracked nutrient — short label + unit + whether
// to render with the "awareness" treatment (no DGE target). Drives the
// MicronutrientCell labels.
class MicronutrientDisplay {
  final String shortNameDe;
  final String shortNameEn;
  final String unitLabel;
  final bool awareness; // dashed ring + italic label + info tag
  final bool hasUpperLimit; // can render "over" state

  const MicronutrientDisplay({
    required this.shortNameDe,
    required this.shortNameEn,
    required this.unitLabel,
    this.awareness = false,
    this.hasUpperLimit = false,
  });

  String nameForLocale(String locale) =>
      locale.toLowerCase().startsWith('de') ? shortNameDe : shortNameEn;

  static const _table = <String, MicronutrientDisplay>{
    MicronutrientKey.folateUg: MicronutrientDisplay(
        shortNameDe: 'Folat', shortNameEn: 'Folate', unitLabel: 'µg'),
    MicronutrientKey.ironMg: MicronutrientDisplay(
        shortNameDe: 'Eisen',
        shortNameEn: 'Iron',
        unitLabel: 'mg',
        hasUpperLimit: true),
    MicronutrientKey.iodineUg: MicronutrientDisplay(
        shortNameDe: 'Jod', shortNameEn: 'Iodine', unitLabel: 'µg'),
    MicronutrientKey.vitaminDUg: MicronutrientDisplay(
        shortNameDe: 'Vit D', shortNameEn: 'Vit D', unitLabel: 'µg'),
    MicronutrientKey.dhaMg: MicronutrientDisplay(
        shortNameDe: 'DHA', shortNameEn: 'DHA', unitLabel: 'mg'),
    MicronutrientKey.b12Ug: MicronutrientDisplay(
        shortNameDe: 'B12', shortNameEn: 'B12', unitLabel: 'µg'),
    MicronutrientKey.calciumMg: MicronutrientDisplay(
        shortNameDe: 'Kalzium', shortNameEn: 'Calcium', unitLabel: 'mg'),
    MicronutrientKey.cholineMg: MicronutrientDisplay(
        shortNameDe: 'Cholin',
        shortNameEn: 'Choline',
        unitLabel: 'mg',
        awareness: true),
    MicronutrientKey.zincMg: MicronutrientDisplay(
        shortNameDe: 'Zink', shortNameEn: 'Zinc', unitLabel: 'mg'),
  };

  static MicronutrientDisplay? forKey(String key) => _table[key];
}

// True when the active supplement contributes a non-zero amount for
// [nutrientKey]. Used to surface the "+" marker on the matching cell.
bool nutrientHasSupplementContribution(
    String nutrientKey, UserProfileSettings profile) {
  final v = profile.activeSupplement?.values[nutrientKey];
  return v != null && v > 0;
}

// Fold a day's meals + the active supplement into the running total for
// [nutrientKey]. Used by NutritionHeader's micros tier to drive the cell
// progress.
double dailyIntakeFor(
    String nutrientKey, Iterable<MealEntry> meals, UserProfileSettings profile) {
  final mealsSum = meals.fold<double>(0, (sum, m) {
    final v = m.micronutrients?[nutrientKey];
    return sum + (v ?? 0);
  });
  final supplementSum = profile.activeSupplement?.values[nutrientKey] ?? 0;
  return mealsSum + supplementSum;
}

// Aggregates a day's worth of per-meal micronutrient estimates into one
// per-key sum. Absent keys on a meal contribute 0; meals with a null
// micronutrients map (legacy entries, photo path that skipped them)
// contribute nothing.
//
// Returns only keys that have a non-zero total — the donut UI uses this
// directly to render only "live" nutrients without an empty-state loop.
Map<String, double> sumMicronutrientsFor(Iterable<MealEntry> meals) {
  final totals = <String, double>{};
  for (final m in meals) {
    final mn = m.micronutrients;
    if (mn == null || mn.isEmpty) continue;
    for (final entry in mn.entries) {
      totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
    }
  }
  return totals;
}
