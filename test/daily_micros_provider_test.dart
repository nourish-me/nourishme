import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/models/user_profile_settings.dart';
import 'package:nurturetrack/providers/meal_providers.dart';

// Covers the provider GLUE in todayMicronutrientsProvider: it sums each
// meal's stored micronutrients AND adds the active daily supplement's
// per-nutrient values on top. The pure pieces (sumMicronutrientsFor,
// dailyIntakeFor) are unit-tested elsewhere; this verifies they're wired
// together correctly into the totals the diary header shows.

MealEntry _meal(Map<String, double> micros) => MealEntry(
      id: 'm-${micros.hashCode}-${micros.values.fold<double>(0, (a, b) => a + b)}',
      createdAt: DateTime(2026, 6, 23, 9),
      rawText: '',
      summary: 'meal',
      kcal: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      portionAmount: 0,
      portionUnit: 'g',
      safetyWarnings: const [],
      micronutrients: micros,
    );

UserProfileSettings _profile({List<ActiveSupplement> supplements = const []}) =>
    UserProfileSettings(
      ageYears: 34,
      heightCm: 167,
      weightKg: 56,
      activityFactor: 1.375,
      numChildrenNursing: 2,
      milkSharePercent: 100,
      childrenAgeGroup: 0,
      dailyMilkVolumeMl: 1500,
      activeSupplements: supplements,
    );

Future<Map<String, double>> _totals(
    List<MealEntry> meals, UserProfileSettings profile) async {
  final container = ProviderContainer(overrides: [
    todayMealsProvider.overrideWithValue(meals),
    userProfileProvider.overrideWith((ref) => Stream.value(profile)),
  ]);
  addTearDown(container.dispose);
  await container.read(userProfileProvider.future); // let the profile emit
  return container.read(todayMicronutrientsProvider);
}

void main() {
  test('meals only: totals are the summed per-meal micronutrients', () async {
    final totals = await _totals([
      _meal({'iron_mg': 5, 'dha_mg': 0}),
      _meal({'iron_mg': 3, 'dha_mg': 100}),
    ], _profile());
    expect(totals['iron_mg'], 8);
    expect(totals['dha_mg'], 100);
  });

  test('supplement values are added on top of the meal totals', () async {
    final totals = await _totals([
      _meal({'iron_mg': 8, 'dha_mg': 100}),
    ], _profile(supplements: [
      ActiveSupplement(
        name: 'Femibion 2',
        values: const {'iron_mg': 14, 'folate_ug': 400},
        dosesPerDay: 1,
        addedAt: DateTime(2026, 6, 1),
      ),
    ]));
    expect(totals['iron_mg'], 22); // 8 from meals + 14 from supplement
    expect(totals['dha_mg'], 100); // meals only
    expect(totals['folate_ug'], 400); // supplement-only key still appears
  });

  test('supplement contributes even with no meals logged', () async {
    final totals = await _totals(const [], _profile(supplements: [
      ActiveSupplement(
        name: 'Vit D Tropfen',
        values: const {'vitamin_d_ug': 20},
        dosesPerDay: 1,
        addedAt: DateTime(2026, 6, 1),
      ),
    ]));
    expect(totals['vitamin_d_ug'], 20);
  });

  test('empty day, no supplement → empty totals', () async {
    final totals = await _totals(const [], _profile());
    expect(totals, isEmpty);
  });
}
