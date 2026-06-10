import '../models/meal_entry.dart';

// Pure aggregation helpers for the diary's daily totals. Extracted from
// inline fold() chains scattered across providers (today/yesterday/by-day)
// and screens (history / trends), so every "what's the kcal sum for day X?"
// answer comes from the same code path.
//
// Conventions for day boundaries:
//   - A meal belongs to its createdAt's calendar day in LOCAL time
//     (year/month/day of DateTime). A meal at 23:59 sits on its
//     day; a meal at 00:00 sits on the new day - the lower bound
//     is INCLUSIVE, the upper bound (next day's 00:00) is EXCLUSIVE.
//   - Pre-extraction the providers used DateTime.isAfter(startOfDay),
//     which excluded the 00:00:00.000 boundary case. The current
//     inclusive-lower convention matches the byDay grouping (which
//     truncates createdAt to year/month/day, putting 00:00 on the new
//     day) and removes the per-provider inconsistency.
//
// All helpers are pure: same inputs → same outputs, no clock reads,
// no Hive, no Riverpod. Callers thread `now` in for any "today" framing.

// Totals for a list of meals, summed without any rounding.
class DayTotal {
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;

  const DayTotal({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
  });

  static const empty = DayTotal(
    kcal: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
    mealCount: 0,
  );
}

DayTotal dayTotal(Iterable<MealEntry> meals) {
  int kcal = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  int count = 0;
  for (final m in meals) {
    kcal += m.kcal;
    protein += m.proteinG;
    carbs += m.carbsG;
    fat += m.fatG;
    count++;
  }
  return DayTotal(
    kcal: kcal,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
    mealCount: count,
  );
}

// Buckets [meals] by their local-calendar day. Map keys are normalized to
// DateTime(year, month, day) at 00:00 local. Order of meals within each
// bucket matches input order.
Map<DateTime, List<MealEntry>> groupMealsByDay(Iterable<MealEntry> meals) {
  final grouped = <DateTime, List<MealEntry>>{};
  for (final meal in meals) {
    final day = DateTime(
      meal.createdAt.year,
      meal.createdAt.month,
      meal.createdAt.day,
    );
    grouped.putIfAbsent(day, () => []).add(meal);
  }
  return grouped;
}

// Filters [meals] to those whose createdAt falls on [day]'s calendar date
// in local time. [day]'s year/month/day are the only thing read; the
// time-of-day portion is ignored, so callers can pass DateTime.now() or
// a normalized midnight equivalently.
//
// Lower bound is INCLUSIVE (00:00:00.000 of [day] counts), upper bound is
// EXCLUSIVE (00:00:00.000 of the next day is the NEXT day's meal).
List<MealEntry> mealsForDay(Iterable<MealEntry> meals, DateTime day) {
  final startOfDay = DateTime(day.year, day.month, day.day);
  final startOfNextDay = startOfDay.add(const Duration(days: 1));
  return meals
      .where((m) =>
          !m.createdAt.isBefore(startOfDay) &&
          m.createdAt.isBefore(startOfNextDay))
      .toList();
}
