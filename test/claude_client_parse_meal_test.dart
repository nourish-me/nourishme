import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Locks MealParseResult.fromModelText - the pure reply-parsing logic extracted
// from ClaudeClient.parseMeal. This is the robustness layer of the AI-call
// path: it must survive malformed or prose-only model replies without throwing,
// and must default missing fields rather than crash the diary send. A silent
// regression here means wrong nutrition numbers or a generic "Couldn't send".
void main() {
  group('fromModelText - graceful fallbacks', () {
    test('prose-only reply (no JSON) → non-meal', () {
      final r = MealParseResult.fromModelText(
        'That sounds more like a question than a meal. Want me to help?',
      );
      expect(r.isMeal, false);
      expect(r.summary, '');
      expect(r.kcal, 0);
      expect(r.safetyWarnings, isEmpty);
    });

    test('malformed JSON (both braces present, invalid body) → non-meal', () {
      // Hits the jsonDecode try/catch branch specifically: there is a '{' and
      // a '}', so extraction proceeds, but the body fails to decode.
      final r = MealParseResult.fromModelText('{"kcal": broken}');
      expect(r.isMeal, false);
      expect(r.kcal, 0);
    });

    test('empty string → non-meal', () {
      final r = MealParseResult.fromModelText('');
      expect(r.isMeal, false);
    });
  });

  group('fromModelText - valid replies', () {
    test('full valid JSON maps every field', () {
      final r = MealParseResult.fromModelText('''
{
  "is_meal": true,
  "rejection_reason": null,
  "summary": "Haferflocken mit Beeren",
  "kcal": 320,
  "protein_g": 12.5,
  "carbs_g": 45,
  "fat_g": 8.2,
  "portion_amount": 250,
  "portion_unit": "g",
  "portion_alias": "eine Schale",
  "safety_warnings": ["Koffein: achte auf die Tagesgrenze"],
  "micronutrients": {"folate_ug": 120, "iron_mg": 2.5}
}
''');
      expect(r.isMeal, true);
      expect(r.summary, 'Haferflocken mit Beeren');
      expect(r.kcal, 320);
      expect(r.proteinG, 12.5);
      expect(r.carbsG, 45.0);
      expect(r.fatG, 8.2);
      expect(r.portionAmount, 250.0);
      expect(r.portionUnit, 'g');
      expect(r.portionAlias, 'eine Schale');
      expect(r.safetyWarnings, ['Koffein: achte auf die Tagesgrenze']);
      expect(r.micronutrients, {'folate_ug': 120.0, 'iron_mg': 2.5});
    });

    test('JSON embedded in surrounding prose is still extracted', () {
      final r = MealParseResult.fromModelText(
        'Sure! Here you go:\n{"is_meal": true, "summary": "Apfel", "kcal": 95}\nHope that helps.',
      );
      expect(r.isMeal, true);
      expect(r.summary, 'Apfel');
      expect(r.kcal, 95);
    });
  });

  group('fromModelText - defaulting of missing/edge fields', () {
    test('missing fields fall back to safe defaults', () {
      final r = MealParseResult.fromModelText('{"summary": "Snack"}');
      expect(r.isMeal, true); // default true when key absent
      expect(r.summary, 'Snack');
      expect(r.kcal, 0);
      expect(r.proteinG, 0);
      expect(r.portionUnit, 'g');
      expect(r.portionAlias, isNull);
      expect(r.safetyWarnings, isEmpty);
      expect(r.micronutrients, isNull);
    });

    test('blank portion_alias becomes null', () {
      final r = MealParseResult.fromModelText(
        '{"summary": "x", "portion_alias": "   "}',
      );
      expect(r.portionAlias, isNull);
    });

    test('explicit is_meal false carries the rejection reason', () {
      final r = MealParseResult.fromModelText(
        '{"is_meal": false, "rejection_reason": "Das ist eine Frage, keine Mahlzeit."}',
      );
      expect(r.isMeal, false);
      expect(r.rejectionReason, 'Das ist eine Frage, keine Mahlzeit.');
    });

    test('integer macro values are coerced to double', () {
      final r = MealParseResult.fromModelText(
        '{"summary": "x", "protein_g": 10, "carbs_g": 20, "fat_g": 5}',
      );
      expect(r.proteinG, 10.0);
      expect(r.carbsG, 20.0);
      expect(r.fatG, 5.0);
    });
  });
}
