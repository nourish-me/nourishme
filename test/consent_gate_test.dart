import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/consent_gate.dart';

// Locks the GDPR consent gates that decide whether the app may send
// health data to Anthropic and whether it may send analytics to
// PostHog. The decision MUST default to "no" - a regression here
// would mean we silently send pregnancy/lactation/weight payloads to
// a US sub-processor without explicit Art. 9 consent, which is a
// legal hard-line. Tests pin both null-handling and the timestamp-
// present case for both gates independently to prevent accidental
// bundling (e.g. analytics inheriting from health-data state).
void main() {
  group('ConsentGate.canSendHealthData', () {
    test('null timestamp → false (the safe default before onboarding)', () {
      expect(ConsentGate.canSendHealthData(null), isFalse);
    });

    test('any timestamp → true (consent was actively given)', () {
      expect(
        ConsentGate.canSendHealthData(DateTime(2026, 6, 14, 10, 30)),
        isTrue,
      );
    });

    test('epoch zero timestamp still counts as consent', () {
      // Defensive: even an obviously-bogus stored timestamp counts
      // as a positive flag. Storage corruption isn't our concern
      // here, but the gate itself shouldn't be the layer that
      // second-guesses an explicit "yes".
      expect(
        ConsentGate.canSendHealthData(
            DateTime.fromMillisecondsSinceEpoch(0)),
        isTrue,
      );
    });
  });

  group('ConsentGate.canTrackAnalytics', () {
    test('null timestamp → false', () {
      expect(ConsentGate.canTrackAnalytics(null), isFalse);
    });

    test('any timestamp → true', () {
      expect(
        ConsentGate.canTrackAnalytics(DateTime(2026, 6, 14, 10, 30)),
        isTrue,
      );
    });
  });

  group('Independence of the two consents (no bundling)', () {
    test('health-data null + analytics set → analytics may track', () {
      // User skipped onboarding analytics box but later turned it on
      // in Settings. Health-data consent revocation is a separate
      // path (App-Reset) and MUST NOT silently re-enable just because
      // analytics is on. Gates are evaluated independently.
      expect(ConsentGate.canSendHealthData(null), isFalse);
      expect(
        ConsentGate.canTrackAnalytics(DateTime(2026, 6, 14)),
        isTrue,
      );
    });

    test('health-data set + analytics null → no analytics', () {
      // The common case after a fresh onboarding when the user only
      // ticked the mandatory health-data box. Analytics stays silent
      // until explicitly opted in.
      expect(
        ConsentGate.canSendHealthData(DateTime(2026, 6, 14)),
        isTrue,
      );
      expect(ConsentGate.canTrackAnalytics(null), isFalse);
    });
  });
}
