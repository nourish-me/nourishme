import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/coach_session_manager.dart';

// Pure-logic coverage for CoachSessionManager. The combine/day-total maths
// live in coach_meal_bundle_test.dart; coachAnchorFor in thread_ordering_test.
// This covers isRetroactiveMeal, the gate that decides whether a live coach
// reply fires or is paused for a backfilled entry (beta feedback: "for a
// yesterday entry the coach shouldn't run").

void main() {
  final now = DateTime(2026, 6, 23, 14, 0);

  group('isRetroactiveMeal (60 min threshold)', () {
    test('logged at now → live, not retroactive', () {
      expect(CoachSessionManager.isRetroactiveMeal(now, now: now), isFalse);
    });

    test('30 min ago → still live', () {
      expect(
        CoachSessionManager.isRetroactiveMeal(
            now.subtract(const Duration(minutes: 30)),
            now: now),
        isFalse,
      );
    });

    test('exactly 60 min ago → boundary, not yet retroactive', () {
      expect(
        CoachSessionManager.isRetroactiveMeal(
            now.subtract(const Duration(minutes: 60)),
            now: now),
        isFalse,
      );
    });

    test('61 min ago → retroactive', () {
      expect(
        CoachSessionManager.isRetroactiveMeal(
            now.subtract(const Duration(minutes: 61)),
            now: now),
        isTrue,
      );
    });

    test('yesterday → retroactive', () {
      expect(
        CoachSessionManager.isRetroactiveMeal(
            now.subtract(const Duration(days: 1)),
            now: now),
        isTrue,
      );
    });

    test('future time → not retroactive', () {
      expect(
        CoachSessionManager.isRetroactiveMeal(
            now.add(const Duration(minutes: 30)),
            now: now),
        isFalse,
      );
    });
  });
}
