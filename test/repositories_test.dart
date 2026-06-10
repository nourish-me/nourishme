import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nurturetrack/models/favorite_meal.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/models/weight_entry.dart';
import 'package:nurturetrack/services/favorite_repository.dart';
import 'package:nurturetrack/services/meal_repository.dart';
import 'package:nurturetrack/services/weight_repository.dart';

// Locks the Hive-backed CRUD repos (Meal, Favorite, Weight) at the boundary
// every UI surface reads through. They share the same shape:
//   save(entity) is upsert-by-id (same id wins, never duplicates)
//   delete(id) is a silent no-op on unknown ids
//   clearAll() empties the box
//   all() returns the full set in a repo-specific stable order
//   watch() emits the current set on subscribe and on every box change
//
// The shape sounds trivial but each ordering rule is load-bearing:
//   Meal:     createdAt DESC  (newest first; the diary lists rely on this)
//   Favorite: summary ASC     (alphabetical chip order in the input row)
//   Weight:   recordedAt ASC  (oldest first; trends-chart line direction)
//
// Mirrors thread_ordering_test.dart's setup: tmp dir + scoped box name +
// teardown that closes and deletes the box, so each test runs in isolation
// without leaking state across the suite.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('repositories_test');
    Hive.init(tmp.path);
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<Box<String>> openScopedBox(String label) =>
      Hive.openBox<String>('${label}_${DateTime.now().microsecondsSinceEpoch}');

  // ─────────────────────── MealRepository ───────────────────────

  MealEntry meal(
    String id,
    DateTime at, {
    int kcal = 0,
    double protein = 0,
    String summary = '',
  }) =>
      MealEntry(
        id: id,
        createdAt: at,
        rawText: '',
        summary: summary.isEmpty ? id : summary,
        kcal: kcal,
        proteinG: protein,
        carbsG: 0,
        fatG: 0,
        portionAmount: 0,
        portionUnit: 'g',
        portionAlias: null,
        safetyWarnings: const [],
      );

  group('MealRepository', () {
    test('all() is empty on a fresh box', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      expect(repo.all(), isEmpty);
    });

    test('save() persists a meal and all() returns it round-tripped', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      final m = meal('m1', DateTime(2026, 6, 10, 8), kcal: 350, protein: 14.5);
      await repo.save(m);
      final got = repo.all();
      expect(got.length, 1);
      expect(got.single.id, 'm1');
      expect(got.single.kcal, 350);
      expect(got.single.proteinG, 14.5);
      expect(got.single.createdAt, DateTime(2026, 6, 10, 8));
    });

    test('save() with an existing id UPDATES in place (no duplicate). '
        'This is what the Mengen-Edit flow relies on - same id, new values, '
        'one row in the diary, not two', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      await repo.save(meal('m1', DateTime(2026, 6, 10), kcal: 200));
      await repo.save(meal('m1', DateTime(2026, 6, 10), kcal: 380));
      final got = repo.all();
      expect(got.length, 1);
      expect(got.single.kcal, 380);
    });

    test('all() orders by createdAt DESCENDING (newest first) - the diary '
        'and history screens depend on this exact direction', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      // Insert in deliberately scrambled order to prove the sort, not insertion.
      await repo.save(meal('lunch', DateTime(2026, 6, 10, 13)));
      await repo.save(meal('breakfast', DateTime(2026, 6, 10, 8)));
      await repo.save(meal('dinner', DateTime(2026, 6, 10, 19)));
      expect(
        repo.all().map((m) => m.id).toList(),
        ['dinner', 'lunch', 'breakfast'],
      );
    });

    test('delete() removes one entry; delete() on an unknown id is a '
        'silent no-op (used by the slidable-delete UI which does not pre-'
        'check existence)', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      await repo.save(meal('a', DateTime(2026, 6, 10)));
      await repo.save(meal('b', DateTime(2026, 6, 10)));
      await repo.delete('a');
      expect(repo.all().map((m) => m.id).toList(), ['b']);
      await repo.delete('does-not-exist'); // must not throw
      expect(repo.all().map((m) => m.id).toList(), ['b']);
    });

    test('clearAll() empties the box (used by the reset-app flow)', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      await repo.save(meal('a', DateTime(2026, 6, 10)));
      await repo.save(meal('b', DateTime(2026, 6, 10)));
      await repo.clearAll();
      expect(repo.all(), isEmpty);
    });

    test('watch() yields the current state immediately on subscribe + '
        're-yields after a write (the providers fan this stream into the '
        'diary). We assert the initial-then-update shape; exact Hive event '
        'multiplicity per write is not part of the contract', () async {
      final repo = MealRepository(await openScopedBox('meals'));
      // Take(2): initial-state yield + one post-write yield, then auto-
      // cancel so the test never hangs on a hot box.watch() stream.
      final fut = repo.watch().take(2).toList();
      // Microtask hop so the take() subscription is registered before we
      // mutate the box - otherwise the post-write event can race ahead
      // of the listener attaching.
      await Future<void>.delayed(Duration.zero);
      await repo.save(meal('m1', DateTime(2026, 6, 10)));
      final snapshots = await fut.timeout(const Duration(seconds: 2));
      expect(snapshots.first, isEmpty,
          reason: 'first yield should be the box state at subscribe time');
      expect(snapshots.last.length, 1,
          reason: 'second yield should reflect the save() that followed');
    });
  });

  // ─────────────────────── FavoriteRepository ───────────────────────

  FavoriteMeal favorite(String id, String summary, {int kcal = 0}) =>
      FavoriteMeal(
        id: id,
        summary: summary,
        kcal: kcal,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        portionAmount: 0,
        portionUnit: 'g',
        safetyWarnings: const [],
      );

  group('FavoriteRepository', () {
    test('save() then all() round-trips and preserves the optional '
        'micronutrients field (now persisted; was dropped pre-#46)', () async {
      final repo = FavoriteRepository(await openScopedBox('favorites'));
      const fav = FavoriteMeal(
        id: 'f1',
        summary: 'Skyr 150g',
        kcal: 90,
        proteinG: 18,
        carbsG: 5,
        fatG: 0.3,
        portionAmount: 150,
        portionUnit: 'g',
        safetyWarnings: [],
        micronutrients: {'calcium_mg': 165, 'b12_ug': 0.6},
      );
      await repo.save(fav);
      final got = repo.all().single;
      expect(got.id, 'f1');
      expect(got.proteinG, 18);
      expect(got.micronutrients, {'calcium_mg': 165, 'b12_ug': 0.6});
    });

    test('save() with existing id updates in place (dedupe-by-summary in '
        'confirm_screen relies on this to overwrite the same chip rather '
        'than spawning a duplicate)', () async {
      final repo = FavoriteRepository(await openScopedBox('favorites'));
      await repo.save(favorite('f1', 'Apfel', kcal: 80));
      await repo.save(favorite('f1', 'Apfel groß', kcal: 110));
      final got = repo.all();
      expect(got.length, 1);
      expect(got.single.summary, 'Apfel groß');
      expect(got.single.kcal, 110);
    });

    test('all() orders by summary ASCENDING (alphabetical chip row in '
        'the meal input)', () async {
      final repo = FavoriteRepository(await openScopedBox('favorites'));
      await repo.save(favorite('1', 'Zwiebel'));
      await repo.save(favorite('2', 'Apfel'));
      await repo.save(favorite('3', 'Müsli'));
      expect(
        repo.all().map((f) => f.summary).toList(),
        ['Apfel', 'Müsli', 'Zwiebel'],
      );
    });

    test('delete() + clearAll() behave like the meal repo', () async {
      final repo = FavoriteRepository(await openScopedBox('favorites'));
      await repo.save(favorite('a', 'A'));
      await repo.save(favorite('b', 'B'));
      await repo.delete('a');
      expect(repo.all().map((f) => f.id).toList(), ['b']);
      await repo.delete('does-not-exist'); // no-op
      await repo.clearAll();
      expect(repo.all(), isEmpty);
    });
  });

  // ─────────────────────── WeightRepository ───────────────────────

  WeightEntry weight(String id, double kg, DateTime at) =>
      WeightEntry(id: id, weightKg: kg, recordedAt: at);

  group('WeightRepository', () {
    test('save() persists and round-trips weight + recordedAt', () async {
      final repo = WeightRepository(await openScopedBox('weights'));
      await repo.save(weight('w1', 68.4, DateTime(2026, 6, 10, 7, 30)));
      final got = repo.all().single;
      expect(got.id, 'w1');
      expect(got.weightKg, 68.4);
      expect(got.recordedAt, DateTime(2026, 6, 10, 7, 30));
    });

    test('all() orders by recordedAt ASCENDING (oldest first) so the '
        'trends-tab line chart reads left-to-right in time order', () async {
      final repo = WeightRepository(await openScopedBox('weights'));
      // Insert scrambled.
      await repo.save(weight('mid', 67.0, DateTime(2026, 5, 15)));
      await repo.save(weight('latest', 65.8, DateTime(2026, 6, 8)));
      await repo.save(weight('earliest', 68.0, DateTime(2026, 4, 30)));
      expect(
        repo.all().map((w) => w.id).toList(),
        ['earliest', 'mid', 'latest'],
      );
    });

    test('save() with existing id updates - lets the Settings save flow '
        'replace today\'s reading instead of stacking duplicates', () async {
      final repo = WeightRepository(await openScopedBox('weights'));
      await repo.save(weight('w1', 68.0, DateTime(2026, 6, 10)));
      await repo.save(weight('w1', 67.6, DateTime(2026, 6, 10)));
      final got = repo.all();
      expect(got.length, 1);
      expect(got.single.weightKg, 67.6);
    });

    test('delete()/clearAll() round-trip', () async {
      final repo = WeightRepository(await openScopedBox('weights'));
      await repo.save(weight('a', 68, DateTime(2026, 6, 1)));
      await repo.save(weight('b', 67, DateTime(2026, 6, 2)));
      await repo.delete('a');
      expect(repo.all().map((w) => w.id).toList(), ['b']);
      await repo.clearAll();
      expect(repo.all(), isEmpty);
    });
  });
}
