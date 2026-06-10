import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/services/meal_aggregation.dart';

// Locks the pure daily-aggregation helpers that drive every diary number
// the user actually sees: per-day kcal/macro sums (Tagebuch + Verlauf
// cards, Trends week chart) and the by-day grouping that powers them.
//
// Extracted from inline fold() chains in meal_providers.dart, history_screen
// and trends_screen so a single test surface covers the screens too.

MealEntry _m({
  required String id,
  required DateTime at,
  int kcal = 0,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
}) =>
    MealEntry(
      id: id,
      createdAt: at,
      rawText: '',
      summary: id,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      portionAmount: 0,
      portionUnit: 'g',
      portionAlias: null,
      safetyWarnings: const [],
    );

void main() {
  group('dayTotal', () {
    test('empty list → all-zero totals (used by empty diary days)', () {
      final t = dayTotal(const []);
      expect(t.kcal, 0);
      expect(t.proteinG, 0);
      expect(t.carbsG, 0);
      expect(t.fatG, 0);
      expect(t.mealCount, 0);
    });

    test('sums kcal as int and macros as double across meals', () {
      final meals = [
        _m(
            id: 'a',
            at: DateTime(2026, 6, 10, 8),
            kcal: 350,
            protein: 12.5,
            carbs: 40.0,
            fat: 14.2),
        _m(
            id: 'b',
            at: DateTime(2026, 6, 10, 13),
            kcal: 620,
            protein: 28.0,
            carbs: 55.5,
            fat: 22.8),
        _m(
            id: 'c',
            at: DateTime(2026, 6, 10, 19),
            kcal: 480,
            protein: 33.7,
            carbs: 30.3,
            fat: 18.0),
      ];
      final t = dayTotal(meals);
      expect(t.kcal, 1450);
      expect(t.proteinG, closeTo(74.2, 0.0001));
      expect(t.carbsG, closeTo(125.8, 0.0001));
      expect(t.fatG, closeTo(55.0, 0.0001));
      expect(t.mealCount, 3);
    });

    test('single meal with all-zero values still counts as one meal', () {
      // Edge: water entry. mealCount drives the "n meals logged" pill
      // even when kcal is 0; must not collapse to "no entries today".
      final t = dayTotal([_m(id: 'water', at: DateTime(2026, 6, 10))]);
      expect(t.kcal, 0);
      expect(t.mealCount, 1);
    });
  });

  group('groupMealsByDay', () {
    test('empty input → empty map (the history screen relies on this for '
        'the "Keine Einträge"-State)', () {
      expect(groupMealsByDay(const []), isEmpty);
    });

    test('keys are normalized to midnight: meals at any time-of-day on the '
        'same calendar day land in ONE bucket', () {
      final meals = [
        _m(id: 'morning', at: DateTime(2026, 6, 10, 7, 15)),
        _m(id: 'lunch', at: DateTime(2026, 6, 10, 12, 45)),
        _m(id: 'late', at: DateTime(2026, 6, 10, 23, 59, 59)),
      ];
      final grouped = groupMealsByDay(meals);
      expect(grouped.keys.toList(), [DateTime(2026, 6, 10)]);
      expect(grouped[DateTime(2026, 6, 10)]!.length, 3);
    });

    test('midnight boundary: 23:59 of day N stays on day N, 00:00 of '
        'day N+1 lands on day N+1 (no off-by-one merging two days)', () {
      // Regression-anchored: the prior todayMealsProvider used
      // createdAt.isAfter(startOfDay), which silently excluded exactly-
      // midnight saves. groupMealsByDay always normalized by
      // year/month/day, so a 00:00 save sat on the NEW day - the two
      // providers disagreed on that single edge timestamp. After
      // extracting [mealsForDay] with an inclusive lower bound, both
      // helpers must agree.
      final meals = [
        _m(id: 'late-tue', at: DateTime(2026, 6, 9, 23, 59, 59, 999)),
        _m(id: 'midnight-wed', at: DateTime(2026, 6, 10, 0, 0, 0, 0)),
        _m(id: 'lunch-wed', at: DateTime(2026, 6, 10, 13)),
      ];
      final grouped = groupMealsByDay(meals);
      expect(
        grouped[DateTime(2026, 6, 9)]!.map((m) => m.id).toList(),
        ['late-tue'],
      );
      expect(
        grouped[DateTime(2026, 6, 10)]!.map((m) => m.id).toList(),
        ['midnight-wed', 'lunch-wed'],
      );
    });

    test('preserves input order within each bucket so the diary renders '
        'meals in the order they were saved', () {
      final meals = [
        _m(id: '1', at: DateTime(2026, 6, 10, 8)),
        _m(id: '2', at: DateTime(2026, 6, 10, 9)),
        _m(id: '3', at: DateTime(2026, 6, 10, 10)),
      ];
      final grouped = groupMealsByDay(meals);
      expect(
        grouped[DateTime(2026, 6, 10)]!.map((m) => m.id).toList(),
        ['1', '2', '3'],
      );
    });
  });

  group('mealsForDay', () {
    test('returns only meals whose local-calendar day matches', () {
      final meals = [
        _m(id: 'tue-1', at: DateTime(2026, 6, 9, 12)),
        _m(id: 'wed-1', at: DateTime(2026, 6, 10, 8)),
        _m(id: 'wed-2', at: DateTime(2026, 6, 10, 18, 30)),
        _m(id: 'thu-1', at: DateTime(2026, 6, 11, 7)),
      ];
      final wed = mealsForDay(meals, DateTime(2026, 6, 10, 9, 27));
      expect(wed.map((m) => m.id).toList(), ['wed-1', 'wed-2']);
    });

    test('day argument time-of-day is ignored: noon, midnight, or 23:59 '
        'all return the same bucket', () {
      final meals = [
        _m(id: 'wed-meal', at: DateTime(2026, 6, 10, 12)),
      ];
      for (final ref in [
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 10, 12, 0),
        DateTime(2026, 6, 10, 23, 59, 59),
      ]) {
        expect(
          mealsForDay(meals, ref).map((m) => m.id).toList(),
          ['wed-meal'],
          reason: 'time-of-day in [day] arg should not affect bucket: $ref',
        );
      }
    });

    test('lower bound INCLUSIVE: a meal at exactly 00:00:00.000 of [day] '
        'is included (regression: old isAfter check excluded it)', () {
      final meals = [
        _m(id: 'midnight-save', at: DateTime(2026, 6, 10, 0, 0, 0, 0)),
      ];
      expect(
        mealsForDay(meals, DateTime(2026, 6, 10)).map((m) => m.id).toList(),
        ['midnight-save'],
      );
    });

    test('upper bound EXCLUSIVE: a meal at exactly 00:00 of the NEXT day '
        'belongs to the next day, not the queried one', () {
      final meals = [
        _m(id: 'next-day-midnight', at: DateTime(2026, 6, 11, 0, 0, 0, 0)),
      ];
      expect(mealsForDay(meals, DateTime(2026, 6, 10)), isEmpty);
      expect(
        mealsForDay(meals, DateTime(2026, 6, 11)).map((m) => m.id).toList(),
        ['next-day-midnight'],
      );
    });

    test('empty input → empty list', () {
      expect(mealsForDay(const [], DateTime(2026, 6, 10)), isEmpty);
    });

    test('day with no matches → empty list (the providers rely on this '
        'for "no meals yet today")', () {
      final meals = [
        _m(id: 'yesterday', at: DateTime(2026, 6, 9, 18)),
      ];
      expect(mealsForDay(meals, DateTime(2026, 6, 10)), isEmpty);
    });
  });

  group('integration: providers semantics', () {
    test('todayMealsProvider semantic: today is [now-day 00:00, next-day '
        '00:00). yesterdayMealsProvider semantic: same shape, shifted -1d. '
        'Both reachable via mealsForDay with the right day argument', () {
      // Mirrors what meal_providers.dart does after the helper extraction.
      // Locks the contract: "today" means the local calendar day of `now`,
      // "yesterday" means the calendar day before. No isBefore/isAfter
      // edge cases to second-guess.
      final now = DateTime(2026, 6, 10, 14, 30);
      final yesterday = now.subtract(const Duration(days: 1));
      final meals = [
        _m(id: 'two-days-ago', at: DateTime(2026, 6, 8, 12)),
        _m(id: 'yesterday-morning', at: DateTime(2026, 6, 9, 8)),
        _m(id: 'yesterday-evening', at: DateTime(2026, 6, 9, 21)),
        _m(id: 'today-breakfast', at: DateTime(2026, 6, 10, 7, 30)),
        _m(id: 'today-lunch', at: DateTime(2026, 6, 10, 13, 0)),
      ];
      expect(
        mealsForDay(meals, now).map((m) => m.id).toList(),
        ['today-breakfast', 'today-lunch'],
      );
      expect(
        mealsForDay(meals, yesterday).map((m) => m.id).toList(),
        ['yesterday-morning', 'yesterday-evening'],
      );
    });
  });
}
