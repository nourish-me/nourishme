import '../models/meal_entry.dart';
import 'meal_aggregation.dart';

// Pure helpers that flatten a coach-call meal bundle into the shape the
// Claude per-meal prompt expects. Pulled out of CoachSessionManager so the
// joining / summing / safety-warning-deduplication / running-total logic
// can be unit-tested without the Riverpod + Hive + HTTP layers behind it.
//
// "Bundle" here = the list of meals submitMeals/submitMeal hands in. For
// a single text or photo save the list is one element and most of these
// folds collapse to that meal's own values. For a "+ Noch einen scannen"
// chain it's N meals (typically 2-5) that the coach is asked to comment
// on together.

class CoachBundleSummary {
  // Comma-joined raw text. Empty entries are dropped so a barcode-only
  // entry next to a text entry doesn't leave a trailing ", ".
  final String rawText;
  // Comma-joined summary across all meals. Always non-empty when the
  // bundle has at least one meal (each meal carries a parser summary).
  final String summary;
  // Plain folds.
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  // De-duped union of warnings across the bundle. Two meals carrying
  // identical "Koffein: ..." strings collapse to one; near-duplicates
  // (different wording, same risk) survive separately - that's the
  // tradeoff for not re-running the dedupe logic the merge layer uses.
  final List<String> safetyWarnings;

  const CoachBundleSummary({
    required this.rawText,
    required this.summary,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.safetyWarnings,
  });
}

CoachBundleSummary combineMealsForCoach(List<MealEntry> meals) {
  final t = dayTotal(meals); // same fold; reuse the aggregation helper.
  return CoachBundleSummary(
    rawText: meals
        .map((m) => m.rawText)
        .where((s) => s.isNotEmpty)
        .join(', '),
    summary: meals.map((m) => m.summary).join(', '),
    kcal: t.kcal,
    proteinG: t.proteinG,
    carbsG: t.carbsG,
    fatG: t.fatG,
    safetyWarnings: meals.expand((m) => m.safetyWarnings).toSet().toList(),
  );
}

// Day-total kcal + protein for the day [bundle.last] was logged on,
// merging in any [bundle] meal not yet visible in [byDay].
//
// Why the merge? The bundle just got saved this turn. byDay is a
// Riverpod provider fed by a Hive box.watch() stream - the stream
// usually catches up before the coach call fires, but not guaranteed
// (the bundle save and the submitMeals call happen back-to-back in
// confirm_screen). Without this merge, a 2-meal bundle where neither
// meal has reached byDay yet would compute a day total of 0 and
// confuse the coach's "remaining kcal" reasoning. With the merge,
// the bundle's own meals always count, the stream catching up later
// is a no-op (the byDay set will already contain them by id).
//
// Anchored to [bundle.last].createdAt's day, NOT today: retroactively
// logging a meal for yesterday must reason against yesterday's total,
// not today's.
({int kcal, double proteinG}) dayTotalsForCoach({
  required Map<DateTime, List<MealEntry>> byDay,
  required List<MealEntry> bundle,
}) {
  if (bundle.isEmpty) return (kcal: 0, proteinG: 0);
  final last = bundle.last;
  final mealDayKey =
      DateTime(last.createdAt.year, last.createdAt.month, last.createdAt.day);
  final sameDay = byDay[mealDayKey] ?? const <MealEntry>[];
  final extras = bundle
      .where((m) => !sameDay.any((s) => s.id == m.id))
      .toList(growable: false);
  final mealsForTotal = [...sameDay, ...extras];
  final t = dayTotal(mealsForTotal);
  return (kcal: t.kcal, proteinG: t.proteinG);
}
