import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nurturetrack/models/thread_item.dart';
import 'package:nurturetrack/services/coach_session_manager.dart';
import 'package:nurturetrack/services/thread_repository.dart';

// Locks the diary ordering invariants for the bundled scan-session flow
// (#39): a user chains "scan a barcode" → "+ noch einen scannen" → type
// text → save, all in one session. Both meals + one coach call (anchored
// to the LAST meal in the bundle) must read top-to-bottom: A, B, Coach.
//
// Earlier-mode regressions to guard against:
//   - Coach reply for the bundle being anchored to A (earliest) instead
//     of B (latest) - that would push the bubble between A and B and
//     read as "coach already answered before I even saved my text".
//   - Two close-together meals (A at 12:00:00, B at 12:00:01) getting
//     a non-deterministic sort that puts B above A.
//   - Coach response anchored to a time AFTER another meal that arrived
//     later in the same day, pushing the bubble off its meal.
void main() {
  group('Bundled scan + text save - diary ordering', () {
    late Directory tmp;
    late Box<String> box;
    late ThreadRepository repo;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('bundle_ordering_test');
      Hive.init(tmp.path);
      box = await Hive.openBox<String>(
          'threads_${DateTime.now().microsecondsSinceEpoch}');
      repo = ThreadRepository(box);
    });

    tearDown(() async {
      await box.close();
      await tmp.delete(recursive: true);
    });

    test('barcode (A) then text (B) then coach: order is A, B, Coach', () async {
      // Simulates: confirm sheet for barcode opens at T_A, user taps "+ noch
      // einen scannen" → text. Confirm sheet for text opens 12 s later at
      // T_B. User taps Speichern. Coach call fires for the [A, B] bundle.
      final tA = DateTime(2026, 6, 9, 12, 0, 0);
      final tB = tA.add(const Duration(seconds: 12));
      await repo.add(ThreadItem.meal(mealId: 'A', at: tA));
      await repo.add(ThreadItem.meal(mealId: 'B', at: tB));
      // CoachSessionManager.submitMeals([A, B]) anchors the reply to
      // meals.last = B.
      await repo.add(ThreadItem.coachResponse(
        mealId: 'B',
        text: 'reply',
        at: CoachSessionManager.coachAnchorFor(tB),
      ));

      final items = repo.getForDate(tA);
      expect(
        items.map((i) => '${i.type.name}:${i.mealId}').toList(),
        ['meal:A', 'meal:B', 'coachResponse:B'],
      );
    });

    test('rapid bundle: A and B within the same second still order A → B', () {
      // Simulates a rapid-fire bundle where both confirm sheets open within
      // a single second. The list sort must be deterministic.
      final tA = DateTime(2026, 6, 9, 12, 0, 0);
      final tB = DateTime(2026, 6, 9, 12, 0, 0, 1); // +1 ms
      repo.add(ThreadItem.meal(mealId: 'A', at: tA));
      repo.add(ThreadItem.meal(mealId: 'B', at: tB));
      repo.add(ThreadItem.coachResponse(
        mealId: 'B',
        text: 'reply',
        at: CoachSessionManager.coachAnchorFor(tB),
      ));

      final items = repo.getForDate(tA);
      expect(
        items.map((i) => '${i.type.name}:${i.mealId}').toList(),
        ['meal:A', 'meal:B', 'coachResponse:B'],
      );
    });

    test('coach for bundle anchors to LAST meal (B), not first (A)', () async {
      // If we accidentally anchored to A.id, the coach bubble would land
      // immediately after A and BEFORE B - reading as "coach already
      // answered for my barcode while I was still typing my second item".
      final tA = DateTime(2026, 6, 9, 12, 0, 0);
      final tB = tA.add(const Duration(seconds: 12));
      await repo.add(ThreadItem.meal(mealId: 'A', at: tA));
      await repo.add(ThreadItem.meal(mealId: 'B', at: tB));
      await repo.add(ThreadItem.coachResponse(
        mealId: 'B',
        text: 'reply',
        // Even if the WRITE time were drifted (e.g. coach call took a few s),
        // the repo sorter re-anchors via mealTs[B.id] + 1µs.
        at: tB.add(const Duration(seconds: 8)),
      ));

      final items = repo.getForDate(tA);
      // Coach must sit DIRECTLY after B, not somewhere between A and B.
      final idxB = items.indexWhere(
          (i) => i.type == ThreadItemType.meal && i.mealId == 'B');
      final idxCoach = items.indexWhere(
          (i) => i.type == ThreadItemType.coachResponse);
      expect(idxCoach, idxB + 1,
          reason: 'Coach reply must be the item immediately after meal B.');
    });

    test('two meals at IDENTICAL timestamps preserve insertion order '
        '(#39: user-picked 12:30 for both barcode + text in same bundle)',
        () async {
      // Reproduces the original #39 unstable-sort bug: when the user picked
      // 12:30 for both the barcode and the text meal in the same bundle,
      // the unstable List.sort sometimes flipped text above barcode.
      final t = DateTime(2026, 6, 9, 12, 30);
      await repo.add(ThreadItem.meal(mealId: 'A_barcode', at: t));
      await repo.add(ThreadItem.meal(mealId: 'B_text', at: t));
      await repo.add(ThreadItem.coachResponse(
        mealId: 'B_text',
        text: 'reply',
        at: CoachSessionManager.coachAnchorFor(t),
      ));

      final items = repo.getForDate(t);
      expect(
        items.map((i) => '${i.type.name}:${i.mealId}').toList(),
        ['meal:A_barcode', 'meal:B_text', 'coachResponse:B_text'],
      );
    });

    test('past entries on same day stay above the bundle - retroactive '
        'breakfast at 7:30 + later bundled lunch at 12:00 reads correctly',
        () async {
      // Mixed past-now: user logged breakfast retroactively earlier in the
      // morning, then chained a bundled lunch scan at noon. Order: breakfast,
      // A_lunch, B_lunch_text, coach.
      final tBreakfast = DateTime(2026, 6, 9, 7, 30);
      final tA = DateTime(2026, 6, 9, 12, 0, 0);
      final tB = tA.add(const Duration(seconds: 30));
      await repo.add(ThreadItem.meal(mealId: 'BREAKFAST', at: tBreakfast));
      await repo.add(ThreadItem.meal(mealId: 'A', at: tA));
      await repo.add(ThreadItem.meal(mealId: 'B', at: tB));
      await repo.add(ThreadItem.coachResponse(
        mealId: 'B',
        text: 'reply',
        at: CoachSessionManager.coachAnchorFor(tB),
      ));

      final items = repo.getForDate(tA);
      expect(
        items.map((i) => '${i.type.name}:${i.mealId}').toList(),
        ['meal:BREAKFAST', 'meal:A', 'meal:B', 'coachResponse:B'],
      );
    });
  });
}
