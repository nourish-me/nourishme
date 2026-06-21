import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/models/user_profile_settings.dart';
import 'package:nurturetrack/services/coach_day_context.dart';
import 'package:nurturetrack/services/micronutrient_targets.dart';

MealEntry _meal({
  required String summary,
  required DateTime at,
  int kcal = 0,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  String rawText = '',
}) =>
    MealEntry(
      id: '$summary-${at.millisecondsSinceEpoch}',
      createdAt: at,
      rawText: rawText,
      summary: summary,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      portionAmount: 0,
      portionUnit: 'g',
      portionAlias: null,
      safetyWarnings: const [],
    );

ActiveSupplement _supp(String name, Map<String, double> values) =>
    ActiveSupplement(
      name: name,
      values: values,
      dosesPerDay: 1,
      addedAt: DateTime(2026, 6, 1),
    );

void main() {
  const noMicros = <String, double>{};
  const noTargets = <String, MicronutrientTarget>{};
  const noSupps = <ActiveSupplement>[];

  group('CoachDayContext meal sequence', () {
    test('lists meals chronologically with time + macros (de)', () {
      final ctx = CoachDayContext.build(
        mealsToday: [
          _meal(
              summary: 'Salat mit Hähnchen',
              at: DateTime(2026, 6, 21, 12, 15),
              kcal: 480,
              protein: 35,
              carbs: 30,
              fat: 22),
          _meal(
              summary: 'Haferbrei',
              at: DateTime(2026, 6, 21, 7, 30),
              kcal: 320,
              protein: 12,
              carbs: 48,
              fat: 8),
        ],
        micros: noMicros,
        microTargets: noTargets,
        supplements: noSupps,
        isDe: true,
      );
      // Breakfast (07:30) must come before lunch (12:15) regardless of
      // input order - this is the gap that made the coach guess "next meal".
      final breakfastIdx = ctx.indexOf('07:30 Haferbrei');
      final lunchIdx = ctx.indexOf('12:15 Salat mit Hähnchen');
      expect(breakfastIdx, greaterThanOrEqualTo(0));
      expect(lunchIdx, greaterThan(breakfastIdx));
      expect(ctx, contains('=== Mahlzeiten heute (chronologisch) ==='));
      expect(ctx, contains('(320 kcal, P12/KH48/F8 g)'));
    });

    test('empty day is stated explicitly, not omitted', () {
      final ctx = CoachDayContext.build(
        mealsToday: const [],
        micros: noMicros,
        microTargets: noTargets,
        supplements: noSupps,
        isDe: true,
      );
      expect(ctx, contains('Noch keine Mahlzeit heute eingetragen.'));
    });

    test('falls back to rawText when summary is blank', () {
      final ctx = CoachDayContext.build(
        mealsToday: [
          _meal(
              summary: '',
              rawText: 'zwei Scheiben Knäckebrot',
              at: DateTime(2026, 6, 21, 10, 0)),
        ],
        micros: noMicros,
        microTargets: noTargets,
        supplements: noSupps,
        isDe: true,
      );
      expect(ctx, contains('10:00 zwei Scheiben Knäckebrot'));
    });
  });

  group('CoachDayContext micros', () {
    test('lists only non-zero micros with target', () {
      final profile = UserProfileSettings(
        ageYears: 34,
        heightCm: 167,
        weightKg: 56,
        activityFactor: 1.375,
        numChildrenNursing: 2,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
        dailyMilkVolumeMl: 1500,
      );
      final targets = MicronutrientTargets.allFor(profile);
      final ctx = CoachDayContext.build(
        mealsToday: const [],
        micros: const {
          'iron_mg': 12.0,
          'dha_mg': 0.0, // zero -> dropped
          'folate_ug': 250.0,
        },
        microTargets: targets,
        supplements: noSupps,
        isDe: true,
      );
      expect(ctx,
          contains('=== Mikronährstoffe heute (aus Mahlzeiten + aktiven Supplements) ==='));
      expect(ctx, contains('Eisen: 12'));
      expect(ctx, contains('Folat: 250'));
      expect(ctx, isNot(contains('DHA:')));
    });
  });

  group('CoachDayContext supplements', () {
    test('label-scanned supplement shows per-nutrient values', () {
      final ctx = CoachDayContext.build(
        mealsToday: const [],
        micros: noMicros,
        microTargets: noTargets,
        supplements: [
          _supp('Femibion 2', const {'dha_mg': 200, 'folate_ug': 400}),
        ],
        isDe: true,
      );
      expect(ctx, contains('=== Aktive Supplements ==='));
      expect(ctx, contains('Femibion 2:'));
      expect(ctx, contains('DHA 200'));
    });

    test('name-only supplement is rendered explicitly, not swallowed', () {
      final ctx = CoachDayContext.build(
        mealsToday: const [],
        micros: noMicros,
        microTargets: noTargets,
        supplements: [_supp('Vitamin D Tropfen', const {})],
        isDe: true,
      );
      expect(ctx,
          contains('- Vitamin D Tropfen (konfiguriert, keine Nährwerte hinterlegt)'));
    });
  });

  test('returns empty string when nothing to show', () {
    final ctx = CoachDayContext.build(
      mealsToday: const [],
      micros: noMicros,
      microTargets: noTargets,
      supplements: noSupps,
      isDe: true,
    );
    // Meal sequence always renders (empty-day line), so the block is never
    // truly empty - but with no meals AND the empty-day line it still
    // carries the header. Assert the no-data sections are absent.
    expect(ctx, isNot(contains('Mikronährstoffe')));
    expect(ctx, isNot(contains('Aktive Supplements')));
  });
}
