import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Locks ClaudeClient.buildDietLine - the diet-profile + vegan-alarm
// guardrail block injected into every per-meal coach prompt. The
// vegan+phase combination is where the dietitian flagged a real risk
// of B12/DHA/iron gaps; this test prevents a silent regression that
// would let the coach drop the guardrail for vegan pregnant/lactating
// users.
void main() {
  group('buildDietLine - empty/omnivore baseline', () {
    test('omnivore + no restrictions + no notes → empty string', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'omnivore',
        restrictions: const {},
        dietaryNotes: '',
      );
      expect(out, isEmpty);
    });

    test('omnivore + pregnant → still empty (no guardrail for omnivore)', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'omnivore',
        restrictions: const {},
        dietaryNotes: '',
        isPregnant: true,
      );
      expect(out, isEmpty);
    });

    test('diet info present → block leads with "Ernährungsprofil:" (DE)', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
      );
      expect(out, contains('Ernährungsprofil: Ernährung: vegan'));
    });

    test('diet info present → block leads with "Dietary profile:" (EN)', () {
      final out = ClaudeClient.buildDietLine(
        isDe: false,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
      );
      expect(out, contains('Dietary profile: Diet: vegan'));
    });
  });

  group('buildDietLine - vegan guardrail conditions', () {
    test('vegan + pregnant → guardrail with B12 + DHA + Iod (DE)', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
        isPregnant: true,
      );
      expect(out, contains('Vegan in dieser Phase'));
      expect(out, contains('Vitamin B12'));
      expect(out, contains('DHA'));
      expect(out, contains('Iod'));
    });

    test('vegan + lactating (numChildrenNursing > 0) → guardrail fires', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
        numChildrenNursing: 1,
      );
      expect(out, contains('Vegan in dieser Phase'));
      expect(out, contains('Vitamin B12'));
    });

    test('vegan + lactating EN → guardrail in English', () {
      final out = ClaudeClient.buildDietLine(
        isDe: false,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
        numChildrenNursing: 2,
      );
      expect(out, contains('Vegan during this phase'));
      expect(out, contains('vitamin B12'));
      expect(out, contains('DHA'));
      expect(out, contains('iodine'));
    });

    test('vegan + neither pregnant nor lactating → NO guardrail', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
      );
      // Diet profile line is still there, just no Vegan-Alarm block.
      expect(out, contains('Ernährung: vegan'));
      expect(out, isNot(contains('Vegan in dieser Phase')));
      expect(out, isNot(contains('Vitamin B12')));
    });

    test('vegetarian + pregnant → NO vegan guardrail (only vegan triggers)',
        () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegetarian',
        restrictions: const {},
        dietaryNotes: '',
        isPregnant: true,
      );
      expect(out, contains('Ernährung: vegetarian'));
      expect(out, isNot(contains('Vegan in dieser Phase')));
    });

    test('vegan + pregnant guardrail references the source (DGE/AND/EFSA)',
        () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'vegan',
        restrictions: const {},
        dietaryNotes: '',
        isPregnant: true,
      );
      expect(out, contains('DGE'));
      expect(out, contains('AND'));
      expect(out, contains('EFSA'));
    });
  });

  group('buildDietLine - restrictions + notes still surfaced', () {
    test('omnivore + restrictions → restrictions in block', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'omnivore',
        restrictions: const {'gluten', 'lactose'},
        dietaryNotes: '',
      );
      expect(out, contains('Vermeidet:'));
      expect(out, contains('gluten'));
      expect(out, contains('lactose'));
    });

    test('omnivore + notes → notes in block', () {
      final out = ClaudeClient.buildDietLine(
        isDe: true,
        dietStyle: 'omnivore',
        restrictions: const {},
        dietaryNotes: 'kein Fisch',
      );
      expect(out, contains('Hinweis: kein Fisch'));
    });
  });
}
