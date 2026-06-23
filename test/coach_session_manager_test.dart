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
    test('success: trims, replaces the em-dash, NOT a system notice', () {
      final r = CoachSessionManager.coachReplyTextFor(
          response: '  Stark gemacht — iss zum Abend etwas Eisenreiches.  ',
          isDe: true);
      expect(r.text, 'Stark gemacht - iss zum Abend etwas Eisenreiches.');
      expect(r.isSystemNotice, isFalse);
    });

    test('CoachApiException → userMessage (system notice), ignores fallback',
        () {
      final e = CoachApiException(
          'Der Coach ist gerade überlastet. Versuch es in einer Minute nochmal.',
          'HTTP 429');
      final r = CoachSessionManager.coachReplyTextFor(
          error: e, isDe: false, fallbackMessage: 'WIRD IGNORIERT');
      expect(r.text,
          'Der Coach ist gerade überlastet. Versuch es in einer Minute nochmal.');
      expect(r.text, isNot('WIRD IGNORIERT'));
      expect(r.isSystemNotice, isTrue);
    });

    // Was "documents the empty bubble"; now repurposed to pin the HANDLED
    // behaviour: an empty / whitespace 200 reply becomes the localized
    // fallback text AND is flagged as a system notice (so it isn't fed back
    // to the coach). "Empty" stays a documented, handled case.
    test('empty / whitespace response → localized fallback + system notice',
        () {
      final de =
          CoachSessionManager.coachReplyTextFor(response: '', isDe: true);
      expect(de.text,
          'Ich konnte gerade keine Antwort erzeugen. Versuch es bitte gleich noch mal.');
      expect(de.isSystemNotice, isTrue);

      final en = CoachSessionManager.coachReplyTextFor(
          response: '   \n  ', isDe: false);
      expect(en.text,
          "I couldn't generate a reply just now. Please try again in a moment.");
      expect(en.isSystemNotice, isTrue);
    });

    test('non-API error without fallback → localized default, system notice',
        () {
      final de = CoachSessionManager.coachReplyTextFor(
          error: Exception('boom'), isDe: true);
      expect(de.text,
          'Coach-Antwort gerade nicht verfügbar. Versuch es später nochmal.');
      expect(de.isSystemNotice, isTrue);

      final en = CoachSessionManager.coachReplyTextFor(
          error: Exception('boom'), isDe: false);
      expect(en.text, 'Coach reply unavailable. Try again later.');
    });

    test('non-API error uses the caller fallback when provided', () {
      final r = CoachSessionManager.coachReplyTextFor(
          error: Exception('boom'),
          isDe: true,
          fallbackMessage: 'Mein lokalisierter Fallback');
      expect(r.text, 'Mein lokalisierter Fallback');
      expect(r.isSystemNotice, isTrue);
    });
  });

  // Decouples the coach regen from the ordering resync (13:36-ordering fix).
  // A pure time-edit resyncs the meal's position but must NEVER fire a coach
  // call; only a real content change does, and even then not for retro /
  // past-day edits (prior behaviour preserved).
  group('shouldRegenCoachOnEdit', () {
    test('pure time-edit (values unchanged) → no regen, even live', () {
      expect(
        CoachSessionManager.shouldRegenCoachOnEdit(
            valuesChanged: false, isPastDayEdit: false, isRetroEdit: false),
        isFalse,
      );
    });

    test('value-edit, live (today, not retro) → regen', () {
      expect(
        CoachSessionManager.shouldRegenCoachOnEdit(
            valuesChanged: true, isPastDayEdit: false, isRetroEdit: false),
        isTrue,
      );
    });

    test('value-edit on a past day → no regen (as before)', () {
      expect(
        CoachSessionManager.shouldRegenCoachOnEdit(
            valuesChanged: true, isPastDayEdit: true, isRetroEdit: false),
        isFalse,
      );
    });

    test('value-edit, retroactive time → no regen (as before)', () {
      expect(
        CoachSessionManager.shouldRegenCoachOnEdit(
            valuesChanged: true, isPastDayEdit: false, isRetroEdit: true),
        isFalse,
      );
    });
  });
}
