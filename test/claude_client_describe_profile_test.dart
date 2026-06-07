import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Locks ClaudeClient.describeProfile against the exact strings the coach
// prompt relies on. This line is injected into every system prompt, so a
// silent wording or threshold change here quietly degrades every AI reply.
// The share-percent thresholds (25 / 50 / 75 / 100) are the bug-prone part:
// each boundary is pinned below so an off-by-one (`>` vs `>=`) goes red.
void main() {
  group('describeProfile — German (locale "de")', () {
    test('no milk supply when numChildren <= 0', () {
      expect(
        ClaudeClient.describeProfile(0, 0, locale: 'de'),
        'Profil: aktuell keine Milchabgabe (z.B. Schwangerschaft oder bereits abgestillt).',
      );
    });

    test('exclusive (100%), singular child', () {
      expect(
        ClaudeClient.describeProfile(1, 100, locale: 'de'),
        'Profil: versorgt ein Kind mit eigener Milch, jeweils ausschließlich (100%).',
      );
    });

    test('mostly threshold at exactly 75%, plural children', () {
      expect(
        ClaudeClient.describeProfile(2, 75, locale: 'de'),
        'Profil: versorgt 2 Kinder mit eigener Milch, jeweils hauptsächlich (75%).',
      );
    });

    test('about half threshold at exactly 50%', () {
      expect(
        ClaudeClient.describeProfile(1, 50, locale: 'de'),
        'Profil: versorgt ein Kind mit eigener Milch, jeweils etwa zur Hälfte (50%).',
      );
    });

    test('partly threshold at exactly 25%', () {
      expect(
        ClaudeClient.describeProfile(1, 25, locale: 'de'),
        'Profil: versorgt ein Kind mit eigener Milch, jeweils teilweise (25%).',
      );
    });

    test('a little below 25%', () {
      expect(
        ClaudeClient.describeProfile(1, 10, locale: 'de'),
        'Profil: versorgt ein Kind mit eigener Milch, jeweils wenig (10%).',
      );
    });

    test('region subtag de-DE still resolves to German', () {
      expect(
        ClaudeClient.describeProfile(1, 100, locale: 'de-DE'),
        startsWith('Profil:'),
      );
    });
  });

  group('describeProfile — English (default + "en")', () {
    test('defaults to English when no locale passed', () {
      expect(
        ClaudeClient.describeProfile(0, 0),
        'Profile: no current milk supply (e.g. pregnancy or already weaned).',
      );
    });

    test('exclusive (100%), singular child', () {
      expect(
        ClaudeClient.describeProfile(1, 100, locale: 'en'),
        'Profile: feeds one child with own milk, exclusively (100%) each.',
      );
    });

    test('about half (50%), plural children', () {
      expect(
        ClaudeClient.describeProfile(3, 50, locale: 'en'),
        'Profile: feeds 3 children with own milk, about half (50%) each.',
      );
    });

    test('a little below 25%', () {
      expect(
        ClaudeClient.describeProfile(1, 10, locale: 'en'),
        'Profile: feeds one child with own milk, a little (10%) each.',
      );
    });
  });
}
