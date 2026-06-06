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
