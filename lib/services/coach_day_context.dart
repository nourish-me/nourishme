import '../models/meal_entry.dart';
import '../models/user_profile_settings.dart';
import 'micronutrient_targets.dart';

/// Pure builder for the shared coach day-state context block.
///
/// Both coach call paths feed this so they reason on the SAME day-state:
///   - per-meal coach: coach_session_manager -> generatePerMealResponse
///   - chat coach:      home_input -> ClaudeClient.chat
///
/// Before this, the per-meal coach saw only aggregate day totals + the
/// clock, so it announced "lunch is next" after lunch was already logged
/// (no view on the day's meal sequence) and never saw micronutrients or
/// supplements at all; the chat coach saw micros + supplements but not the
/// sequence. This collapses both into one contract.
///
/// Pure + unit-tested: callers gather the data from providers and pass it
/// in. Returns an empty string when there is nothing to show, so callers
/// can append it conditionally.
class CoachDayContext {
  const CoachDayContext._();

  static String build({
    required List<MealEntry> mealsToday,
    required Map<String, double> micros,
    required Map<String, MicronutrientTarget> microTargets,
    required List<ActiveSupplement> supplements,
    required bool isDe,
  }) {
    final blocks = <String>[
      _mealSequenceBlock(mealsToday, isDe),
      _microsBlock(micros, microTargets, isDe),
      _supplementsBlock(supplements, isDe),
    ].where((b) => b.isNotEmpty).toList();
    return blocks.join('\n\n');
  }

  // The day's meals in time order. THIS is the gap that made the per-meal
  // coach guess "next meal" from the clock alone. Always emitted (even
  // empty) so the coach can tell an empty day from a full one.
  static String _mealSequenceBlock(List<MealEntry> meals, bool isDe) {
    final header = isDe
        ? '=== Mahlzeiten heute (chronologisch) ==='
        : '=== Meals today (chronological) ===';
    if (meals.isEmpty) {
      return '$header\n${isDe ? 'Noch keine Mahlzeit heute eingetragen.' : 'No meals logged today yet.'}';
    }
    final sorted = [...meals]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lines = sorted.map((m) {
      final t =
          '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}';
      final summary =
          m.summary.trim().isNotEmpty ? m.summary.trim() : m.rawText.trim();
      final carbsLabel = isDe ? 'KH' : 'C';
      return '- $t $summary (${m.kcal} kcal, P${m.proteinG.round()}/$carbsLabel${m.carbsG.round()}/F${m.fatG.round()} g)';
    }).join('\n');
    return '$header\n$lines';
  }

  // Full micronutrient standing, only the nutrients with a non-zero
  // reading (so the prompt is not spammed with zeroes). Same format the
  // chat path already used, now shared with per-meal too.
  static String _microsBlock(
    Map<String, double> micros,
    Map<String, MicronutrientTarget> targets,
    bool isDe,
  ) {
    final lines = <String>[];
    for (final key in MicronutrientKey.all) {
      final value = micros[key] ?? 0;
      if (value <= 0) continue;
      final target = targets[key];
      final label = MicronutrientDisplay.forKey(key);
      final shortName =
          label == null ? key : (isDe ? label.shortNameDe : label.shortNameEn);
      final unit = label?.unitLabel ?? '';
      final targetPart =
          target == null ? '' : ' / ${_fmt(target.value)} $unit';
      lines.add('- $shortName: ${_fmt(value)} $unit$targetPart');
    }
    if (lines.isEmpty) return '';
    final header = isDe
        ? '=== Mikronährstoffe heute (aus Mahlzeiten + aktiven Supplements) ==='
        : '=== Micronutrients today (from meals + active supplements) ===';
    return '$header\n${lines.join('\n')}';
  }

  // Configured supplements, label-scanned (with per-nutrient values) AND
  // name-only / onboarding (stored with an empty values map by
  // supplement_setup.dart). The name-only case is rendered explicitly so
  // the coach knows the user supplements even without parsed amounts
  // (Julia's gap) instead of swallowing them.
  static String _supplementsBlock(List<ActiveSupplement> supps, bool isDe) {
    if (supps.isEmpty) return '';
    final lines = supps.map((s) {
      final contribs = <String>[];
      for (final entry in s.values.entries) {
        final label = MicronutrientDisplay.forKey(entry.key);
        if (label == null) continue;
        final unit = label.unitLabel;
        final name = isDe ? label.shortNameDe : label.shortNameEn;
        contribs.add('$name ${_fmt(entry.value)} $unit');
      }
      if (contribs.isEmpty) {
        return isDe
            ? '- ${s.name} (konfiguriert, keine Nährwerte hinterlegt)'
            : '- ${s.name} (configured, no values on file)';
      }
      return '- ${s.name}: ${contribs.join(", ")}';
    }).join('\n');
    final header =
        isDe ? '=== Aktive Supplements ===' : '=== Active supplements ===';
    return '$header\n$lines';
  }

  // Matches the rounding the chat path used: whole numbers at >= 10, one
  // decimal below, so existing chat output stays byte-identical.
  static String _fmt(double v) => v.toStringAsFixed(v >= 10 ? 0 : 1);
}
