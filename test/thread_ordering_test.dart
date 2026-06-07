import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nurturetrack/models/thread_item.dart';
import 'package:nurturetrack/services/coach_session_manager.dart';
import 'package:nurturetrack/services/thread_repository.dart';

// Locks the diary's "coach reply sits directly beneath its meal" invariant
// and guards the late-night regression: a meal logged near midnight used to
// push its coach reply onto the NEXT day (coachAt = mealTime + 1min crossed
// midnight, and ThreadRepository keys by date only), where the reply detached
// from its meal and sorted to the very top of tomorrow's thread.
void main() {
  group('CoachSessionManager.coachAnchorFor (pure)', () {
    test('normal time → +1 minute, same day', () {
      expect(
        CoachSessionManager.coachAnchorFor(DateTime(2026, 6, 6, 12, 0, 0)),
        DateTime(2026, 6, 6, 12, 1, 0),
      );
    });

    test('23:59:30 clamps to end-of-day, never crosses midnight', () {
      final r =
          CoachSessionManager.coachAnchorFor(DateTime(2026, 6, 6, 23, 59, 30));
      expect(r.day, 6); // still the meal's day, not the 7th
      expect(r, DateTime(2026, 6, 6, 23, 59, 59, 999));
    });

    test('23:58:30 → +1min stays on the same day', () {
      expect(
        CoachSessionManager.coachAnchorFor(DateTime(2026, 6, 6, 23, 58, 30)),
        DateTime(2026, 6, 6, 23, 59, 30),
      );
    });
  });

  group('ThreadRepository ordering', () {
    late Directory tmp;
    late Box<String> box;
    late ThreadRepository repo;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('thread_ordering_test');
      Hive.init(tmp.path);
      box = await Hive.openBox<String>(
          'threads_${DateTime.now().microsecondsSinceEpoch}');
      repo = ThreadRepository(box);
    });

    tearDown(() async {
      await box.close();
      await tmp.delete(recursive: true);
    });

    test('coach reply sorts directly beneath its meal (midday)', () async {
      final mealAt = DateTime(2026, 6, 6, 12, 0, 0);
      await repo.add(ThreadItem.meal(mealId: 'm1', at: mealAt));
      await repo.add(ThreadItem.coachResponse(
        mealId: 'm1',
        text: 'reply',
        at: CoachSessionManager.coachAnchorFor(mealAt),
      ));

      final items = repo.getForDate(mealAt);
      expect(
        items.map((i) => i.type).toList(),
        [ThreadItemType.meal, ThreadItemType.coachResponse],
      );
    });

    test('near-midnight meal keeps its reply on the same day '
        '(regression: reply used to land on top of the next day)', () async {
      final mealAt = DateTime(2026, 6, 6, 23, 59, 30);
      final coachAt = CoachSessionManager.coachAnchorFor(mealAt);
      await repo.add(ThreadItem.meal(mealId: 'm1', at: mealAt));
      await repo.add(
          ThreadItem.coachResponse(mealId: 'm1', text: 'reply', at: coachAt));

      // Reply lives on the meal's day, directly beneath it.
      final sameDay = repo.getForDate(mealAt);
      expect(
        sameDay.map((i) => i.type).toList(),
        [ThreadItemType.meal, ThreadItemType.coachResponse],
      );

      // And does NOT leak onto the next day (where it would sort to the top).
      final nextDay = repo.getForDate(mealAt.add(const Duration(days: 1)));
      expect(nextDay, isEmpty);
    });
  });
}
