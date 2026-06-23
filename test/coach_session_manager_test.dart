import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/claude_client.dart';
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

  group('coachReplyTextFor', () {
    test('success: trims whitespace and replaces the em-dash with a hyphen', () {
      expect(
        CoachSessionManager.coachReplyTextFor(
            response: '  Stark gemacht — iss zum Abend etwas Eisenreiches.  ',
            isDe: true),
        'Stark gemacht - iss zum Abend etwas Eisenreiches.',
      );
    });

    test('CoachApiException maps to its userMessage, ignoring fallback + locale',
        () {
      final e = CoachApiException(
          'Der Coach ist gerade überlastet. Versuch es in einer Minute nochmal.',
          'HTTP 429');
      final text = CoachSessionManager.coachReplyTextFor(
          error: e, isDe: false, fallbackMessage: 'WIRD IGNORIERT');
      expect(text,
          'Der Coach ist gerade überlastet. Versuch es in einer Minute nochmal.');
      expect(text, isNot('WIRD IGNORIERT'));
    });

    // CURRENT BEHAVIOUR, intentionally pinned (no fallback built yet): an empty
    // or whitespace-only model reply persists an EMPTY coach bubble. The
    // fallback decision is Vanessa's, this test only documents the status quo.
    test('empty / whitespace response → empty string (documents empty bubble)',
        () {
      expect(
          CoachSessionManager.coachReplyTextFor(response: '', isDe: true), '');
      expect(
          CoachSessionManager.coachReplyTextFor(response: '   \n  ', isDe: true),
          '');
    });

    test('non-API error without fallback → localized default (DE/EN)', () {
      expect(
        CoachSessionManager.coachReplyTextFor(
            error: Exception('boom'), isDe: true),
        'Coach-Antwort gerade nicht verfügbar. Versuch es später nochmal.',
      );
      expect(
        CoachSessionManager.coachReplyTextFor(
            error: Exception('boom'), isDe: false),
        'Coach reply unavailable. Try again later.',
      );
    });

    test('non-API error uses the caller fallback when provided', () {
      expect(
        CoachSessionManager.coachReplyTextFor(
            error: Exception('boom'),
            isDe: true,
            fallbackMessage: 'Mein lokalisierter Fallback'),
        'Mein lokalisierter Fallback',
      );
    });
  });
}
