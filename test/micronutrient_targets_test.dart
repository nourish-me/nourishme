import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/models/user_profile_settings.dart';
import 'package:nurturetrack/services/micronutrient_targets.dart';

// Locks the DGE 2025 / EFSA reference values + phase-classification math
// against the Deep Research brief. If anyone bumps a number by accident
// (DGE Erratum, EFSA revision, copy-paste mistake), these go red. The
// underlying tracker UI relies on these numbers being exactly right —
// silently wrong targets corrupt the most important feature signal.
void main() {
  group('MicronutrientTargets.forKey — phase classification', () {
    test('non-pregnant non-lactating uses baseline values', () {
      final p = _profile();
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.folateUg, p)?.value,
          300);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, p)?.value, 16);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.iodineUg, p)?.value,
          150);
    });

    test('pregnancy T1 uses pregnancy targets', () {
      final p = _profile(isPregnant: true, trimester: 1);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.folateUg, p)?.value,
          550);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, p)?.value, 27);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.iodineUg, p)?.value,
          220);
    });

    test('pregnancy with null trimester defaults to T1 numbers', () {
      // Defensive: profile mid-onboarding can land with isPregnant=true
      // but trimester not yet set. Shouldn't crash or yield wrong values.
      final p = _profile(isPregnant: true);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.folateUg, p)?.value,
          550);
    });

    test('pregnancy T2 picks up the zinc increment (T2 onward per DGE)', () {
      final p = _profile(isPregnant: true, trimester: 2);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.zincMg, p)?.value, 11);
    });

    test('pregnancy T1 still uses the lower zinc value', () {
      final p = _profile(isPregnant: true, trimester: 1);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.zincMg, p)?.value, 8);
    });

    test('lactation iodine is HIGHER than pregnancy (DGE 2025)', () {
      // Key correction from the Deep Research: DGE 2025 raised lactation
      // iodine ABOVE pregnancy iodine. The earlier values had pregnancy
      // at 230 and lactation at 260 — both wrong now. Verify the new
      // canonical numbers.
      final pregnant = _profile(isPregnant: true, trimester: 1);
      final lactating = _profile(numChildrenNursing: 1);
      final pregIodine =
          MicronutrientTargets.forKey(MicronutrientKey.iodineUg, pregnant)
              ?.value;
      final lactIodine =
          MicronutrientTargets.forKey(MicronutrientKey.iodineUg, lactating)
              ?.value;
      expect(pregIodine, 220);
      expect(lactIodine, 230);
      expect(lactIodine, greaterThan(pregIodine!));
    });

    test('lactation iron is LOWER than pregnancy (DGE 2025)', () {
      // The other research correction: pregnancy 27 mg, lactation 16 mg.
      final pregnant = _profile(isPregnant: true, trimester: 1);
      final lactating = _profile(numChildrenNursing: 1);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, pregnant)?.value,
          27);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, lactating)?.value,
          16);
    });

    test('isPregnant takes precedence over numChildrenNursing in classification',
        () {
      // Edge case: rare but legal state — pregnant again while still
      // nursing the previous child. Must classify as pregnant (the more
      // restrictive set) so the tracker uses pregnancy thresholds.
      final p = _profile(
          isPregnant: true, trimester: 2, numChildrenNursing: 1);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, p)?.value, 27);
    });

    test('forKey returns null for an unknown key', () {
      final p = _profile();
      expect(MicronutrientTargets.forKey('vitamin_unobtainium_mg', p), null);
    });

    test('choline source is EFSA AI (no DGE), all other defaults DGE 2025',
        () {
      final p = _profile(isPregnant: true, trimester: 1);
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.cholineMg, p)?.source,
          'EFSA AI');
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.folateUg, p)?.source,
          'DGE 2025');
      expect(
          MicronutrientTargets.forKey(MicronutrientKey.ironMg, p)?.source,
          'DGE 2025');
    });
  });

  group('MicronutrientTargets.allFor — completeness', () {
    test('returns all 9 tracked nutrients regardless of phase', () {
      // Every phase has every nutrient with a target — no nutrient is
      // dropped in any phase. Keeps the Settings list stable.
      for (final p in [
        _profile(),
        _profile(isPregnant: true, trimester: 1),
        _profile(isPregnant: true, trimester: 3),
        _profile(numChildrenNursing: 1),
      ]) {
        final all = MicronutrientTargets.allFor(p);
        expect(all.keys.toSet(), MicronutrientKey.all.toSet());
      }
    });
  });

  group('sumMicronutrientsFor — daily aggregation', () {
    test('empty meal list → empty map', () {
      expect(sumMicronutrientsFor(const []), <String, double>{});
    });

    test('meals with null micronutrients contribute nothing', () {
      final meals = [
        _meal(micronutrients: null),
        _meal(micronutrients: null),
      ];
      expect(sumMicronutrientsFor(meals), <String, double>{});
    });

    test('meals with empty maps contribute nothing', () {
      final meals = [_meal(micronutrients: const {})];
      expect(sumMicronutrientsFor(meals), <String, double>{});
    });

    test('single meal passes its values through unchanged', () {
      final meals = [
        _meal(micronutrients: const {'folate_ug': 120, 'iron_mg': 3.5}),
      ];
      expect(sumMicronutrientsFor(meals),
          {'folate_ug': 120.0, 'iron_mg': 3.5});
    });

    test('multiple meals sum overlapping keys, keep non-overlapping ones', () {
      final meals = [
        _meal(micronutrients: const {'folate_ug': 100, 'iron_mg': 2}),
        _meal(micronutrients: const {'folate_ug': 50, 'iodine_ug': 30}),
        _meal(micronutrients: const {'iron_mg': 4}),
      ];
      final sum = sumMicronutrientsFor(meals);
      expect(sum['folate_ug'], 150);
      expect(sum['iron_mg'], 6);
      expect(sum['iodine_ug'], 30);
      expect(sum.length, 3);
    });

    test('mixed null and value meals: nulls skip, values sum', () {
      final meals = [
        _meal(micronutrients: null),
        _meal(micronutrients: const {'dha_mg': 50}),
        _meal(micronutrients: const {'dha_mg': 100, 'b12_ug': 2.5}),
        _meal(micronutrients: null),
      ];
      final sum = sumMicronutrientsFor(meals);
      expect(sum['dha_mg'], 150);
      expect(sum['b12_ug'], 2.5);
    });
  });

  group('ActiveSupplement — JSON roundtrip', () {
    test('roundtrip preserves name, values, dosesPerDay, addedAt', () {
      final original = ActiveSupplement(
        name: 'Femibion 2',
        values: const {
          'folate_ug': 400,
          'iodine_ug': 150,
          'iron_mg': 14,
          'dha_mg': 200,
        },
        dosesPerDay: 1,
        addedAt: DateTime(2026, 6, 6, 14, 30),
      );
      final back = ActiveSupplement.fromJson(original.toJson());
      expect(back.name, original.name);
      expect(back.dosesPerDay, original.dosesPerDay);
      expect(back.addedAt, original.addedAt);
      expect(back.values, original.values);
    });

    test('fromJson tolerates int values (Hive may rehydrate as int)', () {
      final json = {
        'name': 'Femibion 1',
        'values': {'folate_ug': 800, 'iodine_ug': 150}, // ints, not doubles
        'dosesPerDay': 1,
        'addedAt': '2026-01-01T00:00:00.000',
      };
      final s = ActiveSupplement.fromJson(json);
      expect(s.values['folate_ug'], 800.0);
      expect(s.values['iodine_ug'], 150.0);
      expect(s.values['folate_ug'], isA<double>());
    });
  });

  group('UserProfileSettings — supplement field', () {
    test('roundtrip with active supplement preserves all fields', () {
      final original = UserProfileSettings(
        ageYears: 34,
        heightCm: 167,
        weightKg: 56,
        activityFactor: 1.375,
        numChildrenNursing: 2,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
        dailyMilkVolumeMl: 1500,
        activeSupplement: ActiveSupplement(
          name: 'Femibion 2',
          values: const {'folate_ug': 400, 'iodine_ug': 150},
          dosesPerDay: 1,
          addedAt: DateTime(2026, 6, 6),
        ),
      );
      final back = UserProfileSettings.fromJson(original.toJson());
      expect(back.activeSupplement, isNotNull);
      expect(back.activeSupplement!.name, 'Femibion 2');
      expect(back.activeSupplement!.values['folate_ug'], 400);
    });

    test('roundtrip without active supplement leaves field null', () {
      final original = UserProfileSettings(
        ageYears: 34,
        heightCm: 167,
        weightKg: 56,
        activityFactor: 1.375,
        numChildrenNursing: 0,
        milkSharePercent: 0,
        childrenAgeGroup: 0,
        // activeSupplement omitted
      );
      final back = UserProfileSettings.fromJson(original.toJson());
      expect(back.activeSupplement, isNull);
    });

    test('copyWith without activeSupplement arg leaves existing supplement',
        () {
      final p = _profile().copyWith(
        activeSupplement: ActiveSupplement(
          name: 'Elevit',
          values: const {'folate_ug': 800},
          dosesPerDay: 1,
          addedAt: DateTime(2026, 6, 6),
        ),
      );
      // Calling copyWith with no activeSupplement arg should leave the
      // existing supplement intact (not silently clear it).
      final modified = p.copyWith(weightKg: 60);
      expect(modified.activeSupplement?.name, 'Elevit');
      expect(modified.weightKg, 60);
    });

    test('copyWith with explicit null clears the supplement', () {
      final p = _profile().copyWith(
        activeSupplement: ActiveSupplement(
          name: 'Elevit',
          values: const {'folate_ug': 800},
          dosesPerDay: 1,
          addedAt: DateTime(2026, 6, 6),
        ),
      );
      // The sentinel-based copyWith API lets the caller pass an explicit
      // null to clear, distinct from "omit to leave alone". This is the
      // path the "delete supplement" UI button will use.
      final cleared = p.copyWith(activeSupplement: null);
      expect(cleared.activeSupplement, isNull);
    });
  });
}

// -------- helpers --------

UserProfileSettings _profile({
  bool isPregnant = false,
  int? trimester,
  int numChildrenNursing = 0,
}) =>
    UserProfileSettings(
      ageYears: 30,
      heightCm: 165,
      weightKg: 60,
      activityFactor: 1.375,
      isPregnant: isPregnant,
      trimester: trimester,
      numChildrenNursing: numChildrenNursing,
      milkSharePercent: numChildrenNursing > 0 ? 100 : 0,
      childrenAgeGroup: 0,
    );

MealEntry _meal({Map<String, double>? micronutrients}) => MealEntry(
      id: 'test',
      createdAt: DateTime(2026, 6, 6, 12),
      rawText: 'test',
      summary: 'test',
      kcal: 200,
      proteinG: 10,
      carbsG: 20,
      fatG: 5,
      portionAmount: 100,
      portionUnit: 'g',
      safetyWarnings: const [],
      micronutrients: micronutrients,
    );
