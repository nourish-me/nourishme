import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/services/coach_meal_bundle.dart';

// Locks the pure-fold layer that flattens a coach-call bundle into the
// shape Claude's per-meal prompt expects, plus the stream-race-defensive
// day-total merge. Both functions came out of CoachSessionManager so the
// joining / summing / dedupe / day-anchor logic can be tested without the
// Riverpod + Hive + HTTP stack.
//
// "Bundle" = the list of meals submitMeals hands in. Single text/photo
// saves submit a one-element list; the barcode "+ Noch einen scannen"
// chain submits N (usually 2-5). All folds collapse on single-element
// bundles, so the multi-meal cases below also cover the single case.

MealEntry _m({
  required String id,
  required DateTime at,
  String rawText = '',
  String summary = '',
  int kcal = 0,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  List<String> warnings = const [],
}) =>
    MealEntry(
      id: id,
      createdAt: at,
      rawText: rawText,
      summary: summary.isEmpty ? id : summary,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      portionAmount: 0,
      portionUnit: 'g',
      portionAlias: null,
      safetyWarnings: warnings,
    );

void main() {
  group('combineMealsForCoach', () {
    test('single meal → bundle values match the meal verbatim (the '
        'single-save path is the same code path as multi)', () {
      final b = combineMealsForCoach([
        _m(
          id: 'm1',
          at: DateTime(2026, 6, 10, 8),
          rawText: '2 eggs',
          summary: '2 Eier',
          kcal: 160,
          protein: 13.0,
          carbs: 1.2,
          fat: 11.0,
          warnings: ['Roh-Risiko prüfen'],
        ),
      ]);
      expect(b.rawText, '2 eggs');
      expect(b.summary, '2 Eier');
      expect(b.kcal, 160);
      expect(b.proteinG, closeTo(13.0, 0.0001));
      expect(b.carbsG, closeTo(1.2, 0.0001));
      expect(b.fatG, closeTo(11.0, 0.0001));
      expect(b.safetyWarnings, ['Roh-Risiko prüfen']);
    });

    test('multiple meals: rawText/summary join with ", " and macros sum', () {
      final b = combineMealsForCoach([
        _m(
            id: '1',
            at: DateTime(2026, 6, 10, 8),
            rawText: 'Müsli mit Joghurt',
            summary: 'Müsli + Joghurt',
            kcal: 320,
            protein: 14.0),
        _m(
            id: '2',
            at: DateTime(2026, 6, 10, 8, 5),
            rawText: 'Banane',
            summary: 'Banane',
            kcal: 90,
            protein: 1.1),
      ]);
      expect(b.rawText, 'Müsli mit Joghurt, Banane');
      expect(b.summary, 'Müsli + Joghurt, Banane');
      expect(b.kcal, 410);
      expect(b.proteinG, closeTo(15.1, 0.0001));
    });

    test('empty rawText entries are dropped from the join: a barcode-only '
        'save next to a text save must not leave a leading/trailing ", "', () {
      // Barcode scans land with rawText == '' (the parser only sees the
      // OpenFoodFacts display string via summary, not the raw user text).
      // Without the .where(isNotEmpty) the joined rawText would read
      // ", Müsli" or "Müsli, " and confuse the coach.
      final b = combineMealsForCoach([
        _m(id: 'barcode', at: DateTime(2026, 6, 10), rawText: '', summary: 'Skyr'),
        _m(
            id: 'text',
            at: DateTime(2026, 6, 10),
            rawText: 'Müsli',
            summary: 'Müsli'),
      ]);
      expect(b.rawText, 'Müsli');
      // summary still has all components: the parser always names a meal,
      // so summaries do NOT get filtered.
      expect(b.summary, 'Skyr, Müsli');
    });

    test('all-empty rawTexts → bundle rawText is empty string '
        '(barcode + barcode chain)', () {
      final b = combineMealsForCoach([
        _m(id: 'b1', at: DateTime(2026, 6, 10), rawText: '', summary: 'Skyr'),
        _m(
            id: 'b2',
            at: DateTime(2026, 6, 10),
            rawText: '',
            summary: 'Apfelmus'),
      ]);
      expect(b.rawText, '');
      expect(b.summary, 'Skyr, Apfelmus');
    });

    test('identical safety_warnings across meals collapse to one entry '
        '(prevents the coach prompt from seeing "Koffein..." twice when '
        'two coffee scans land in the same bundle)', () {
      final b = combineMealsForCoach([
        _m(
            id: 'coffee1',
            at: DateTime(2026, 6, 10),
            warnings: ['Koffein: ~80 mg, Tagesgrenze 200 mg beachten']),
        _m(
            id: 'coffee2',
            at: DateTime(2026, 6, 10),
            warnings: ['Koffein: ~80 mg, Tagesgrenze 200 mg beachten']),
      ]);
      expect(b.safetyWarnings, [
        'Koffein: ~80 mg, Tagesgrenze 200 mg beachten',
      ]);
    });

    test('distinct warnings across meals survive in the union', () {
      final b = combineMealsForCoach([
        _m(
            id: 'tuna',
            at: DateTime(2026, 6, 10),
            warnings: ['Quecksilber: Thunfisch begrenzen']),
        _m(
            id: 'wine',
            at: DateTime(2026, 6, 10),
            warnings: ['Alkohol: in der Stillzeit Wartezeit beachten']),
      ]);
      expect(
        b.safetyWarnings.toSet(),
        {
          'Quecksilber: Thunfisch begrenzen',
          'Alkohol: in der Stillzeit Wartezeit beachten',
        },
      );
    });
  });

  group('dayTotalsForCoach', () {
    test('empty bundle → zero (defensive; no caller should pass empty, '
        'but the helper must not throw)', () {
      expect(dayTotalsForCoach(byDay: const {}, bundle: const []),
          (kcal: 0, proteinG: 0));
    });

    test('bundle meal already in byDay (stream caught up): totals equal '
        'sameDay totals, no double-count', () {
      final day = DateTime(2026, 6, 10);
      final breakfast = _m(
          id: 'breakfast', at: day.add(const Duration(hours: 8)), kcal: 350);
      final lunch =
          _m(id: 'lunch', at: day.add(const Duration(hours: 13)), kcal: 600);
      // The bundle currently being submitted IS already in byDay (i.e. the
      // box.watch stream caught up before submitMeals fired). No extras.
      final byDay = {day: [breakfast, lunch]};
      final totals =
          dayTotalsForCoach(byDay: byDay, bundle: [lunch]);
      // lunch counts ONCE despite being in both byDay and the bundle.
      expect(totals.kcal, 950);
    });

    test('bundle meal NOT in byDay yet (stream race): the extras get added '
        '- otherwise the coach would see a 0-kcal day for a freshly-saved '
        'meal and reason against wrong remaining-kcal', () {
      // Race: meal was just saved to MealRepository, but the byDay provider
      // (fed by box.watch) hasn\'t emitted yet. submitMeals fires anyway.
      final day = DateTime(2026, 6, 10);
      final priorBreakfast =
          _m(id: 'old', at: day.add(const Duration(hours: 8)), kcal: 350);
      final freshLunch =
          _m(id: 'new', at: day.add(const Duration(hours: 13)), kcal: 600);
      final byDay = {day: [priorBreakfast]}; // freshLunch not visible yet
      final totals =
          dayTotalsForCoach(byDay: byDay, bundle: [freshLunch]);
      expect(totals.kcal, 950); // old (350) + new (600), no double count
    });

    test('multi-meal bundle, some in byDay some not, get merged by id', () {
      final day = DateTime(2026, 6, 10);
      final visible = _m(
          id: 'visible', at: day.add(const Duration(hours: 8)), kcal: 300);
      final notYet = _m(
          id: 'not-yet', at: day.add(const Duration(hours: 13)), kcal: 500);
      final byDay = {day: [visible]};
      final totals = dayTotalsForCoach(byDay: byDay, bundle: [visible, notYet]);
      // visible from sameDay, not-yet from extras (id mismatch). Total: 800.
      expect(totals.kcal, 800);
    });

    test('day key follows bundle.LAST meal\'s day (anchors retro-logs to '
        'their day, not today): a yesterday-logged meal reasons against '
        'yesterday\'s running total', () {
      final yesterday = DateTime(2026, 6, 9);
      final today = DateTime(2026, 6, 10);
      final yesterdayLunch = _m(
          id: 'y-lunch',
          at: yesterday.add(const Duration(hours: 13)),
          kcal: 600);
      final todayBreakfast = _m(
          id: 't-breakfast',
          at: today.add(const Duration(hours: 8)),
          kcal: 350);
      final byDay = {
        yesterday: [yesterdayLunch],
        today: [todayBreakfast],
      };
      // Retroactive save: bundle contains a meal whose createdAt is
      // yesterday; coach must reason about yesterday\'s total.
      final totals =
          dayTotalsForCoach(byDay: byDay, bundle: [yesterdayLunch]);
      expect(totals.kcal, 600); // yesterday lunch only, NOT today's 350
    });

    test('byDay completely empty (e.g. very first meal ever): totals come '
        'entirely from the bundle extras', () {
      final day = DateTime(2026, 6, 10);
      final firstEverMeal =
          _m(id: 'first', at: day, kcal: 350, protein: 12);
      final totals = dayTotalsForCoach(
          byDay: const {}, bundle: [firstEverMeal]);
      expect(totals.kcal, 350);
      expect(totals.proteinG, closeTo(12, 0.0001));
    });

    test('totals sum protein in addition to kcal (used by the coach\'s '
        '"protein progress" line)', () {
      final day = DateTime(2026, 6, 10);
      final meal = _m(
          id: 'm', at: day, kcal: 500, protein: 28.5);
      final totals =
          dayTotalsForCoach(byDay: {day: [meal]}, bundle: [meal]);
      expect(totals.proteinG, closeTo(28.5, 0.0001));
    });
  });
}
