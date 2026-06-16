import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/models/meal_entry.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Locks ClaudeClient.buildBrandHistoryBlock - the parseMeal prompt
// enrichment that lets the parser anchor on the user's own prior
// values for repeat brand logs instead of re-estimating. The format
// is what the prompt expects to see; a silent change to header,
// footer, or per-entry layout could quietly drop the hint or scramble
// the parser's interpretation.
MealEntry _entry({
  required String id,
  required String summary,
  int kcal = 0,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  double portionAmount = 0,
  String portionUnit = 'g',
}) =>
    MealEntry(
      id: id,
      createdAt: DateTime(2026, 6, 1, 8, 0),
      rawText: summary,
      summary: summary,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      portionAmount: portionAmount,
      portionUnit: portionUnit,
      safetyWarnings: const [],
    );

void main() {
  group('buildBrandHistoryBlock - empty', () {
    test('no hints → empty string (keeps the prompt clean)', () {
      expect(
        ClaudeClient.buildBrandHistoryBlock(const [], isDe: true),
        isEmpty,
      );
      expect(
        ClaudeClient.buildBrandHistoryBlock(const [], isDe: false),
        isEmpty,
      );
    });
  });

  group('buildBrandHistoryBlock - single entry', () {
    test('with portion → "summary (amount unit): macros"', () {
      final out = ClaudeClient.buildBrandHistoryBlock([
        _entry(
          id: '1',
          summary: 'Skyr Vanille',
          kcal: 120,
          protein: 18,
          carbs: 9,
          fat: 1,
          portionAmount: 150,
          portionUnit: 'g',
        ),
      ], isDe: true);
      expect(out, contains('Skyr Vanille (150 g)'));
      expect(out, contains('kcal 120'));
      expect(out, contains('P 18'));
      expect(out, contains('KH 9'));
      expect(out, contains('F 1'));
    });

    test('without portion (portionAmount == 0) → no "(amount)" parens', () {
      final out = ClaudeClient.buildBrandHistoryBlock([
        _entry(id: '1', summary: 'Kaffee', kcal: 5),
      ], isDe: true);
      expect(out, contains('- Kaffee: kcal 5'));
      expect(out, isNot(contains('(0 g)')));
    });

    test('DE header + footer present', () {
      final out = ClaudeClient.buildBrandHistoryBlock(
        [_entry(id: '1', summary: 'Apfel', kcal: 50)],
        isDe: true,
      );
      expect(out, contains('Frühere ähnliche Einträge'));
      expect(out, contains('übernimm dessen Werte direkt'));
    });

    test('EN header + footer present', () {
      final out = ClaudeClient.buildBrandHistoryBlock(
        [_entry(id: '1', summary: 'Apple', kcal: 50)],
        isDe: false,
      );
      expect(out, contains('Earlier similar entries'));
      expect(out, contains('use its values directly'));
    });
  });

  group('buildBrandHistoryBlock - multiple entries', () {
    test('three entries → all three listed', () {
      final out = ClaudeClient.buildBrandHistoryBlock([
        _entry(id: '1', summary: 'Skyr', kcal: 120),
        _entry(id: '2', summary: 'Müsli', kcal: 350),
        _entry(id: '3', summary: 'Banane', kcal: 90),
      ], isDe: true);
      expect(out, contains('Skyr'));
      expect(out, contains('Müsli'));
      expect(out, contains('Banane'));
    });

    test('five entries → only top three included (.take(3))', () {
      final out = ClaudeClient.buildBrandHistoryBlock([
        _entry(id: '1', summary: 'First', kcal: 100),
        _entry(id: '2', summary: 'Second', kcal: 100),
        _entry(id: '3', summary: 'Third', kcal: 100),
        _entry(id: '4', summary: 'Fourth', kcal: 100),
        _entry(id: '5', summary: 'Fifth', kcal: 100),
      ], isDe: true);
      expect(out, contains('First'));
      expect(out, contains('Second'));
      expect(out, contains('Third'));
      expect(out, isNot(contains('Fourth')));
      expect(out, isNot(contains('Fifth')));
    });
  });

  group('buildBrandHistoryBlock - timeOfDayFallback', () {
    // The photo-only path feeds a time-of-day list of recent entries as a
    // vocabulary anchor. Header and footer must differ from the brand-match
    // variant: the model must NOT copy the macros 1:1 (the food in the photo
    // is not necessarily one of these), only use the summaries to break
    // color/shape ambiguity.
    test('empty hints → empty string', () {
      expect(
        ClaudeClient.buildBrandHistoryBlock(
          const [],
          isDe: true,
          timeOfDayFallback: true,
        ),
        isEmpty,
      );
    });

    test('DE header + footer signal "vocabulary anchor, not values"', () {
      final out = ClaudeClient.buildBrandHistoryBlock(
        [_entry(id: '1', summary: 'Heidelbeeren mit Joghurt', kcal: 180)],
        isDe: true,
        timeOfDayFallback: true,
      );
      expect(out, contains('Tageszeit'));
      expect(out, contains('Vokabular-Anker'));
      // Must NOT use the brand-match footer that says "übernimm dessen Werte
      // direkt" - that would mis-instruct the vision model.
      expect(out, isNot(contains('übernimm dessen Werte direkt')));
    });

    test('EN header + footer signal "vocabulary anchor, not values"', () {
      final out = ClaudeClient.buildBrandHistoryBlock(
        [_entry(id: '1', summary: 'Blueberries with yoghurt', kcal: 180)],
        isDe: false,
        timeOfDayFallback: true,
      );
      expect(out, contains('time of day'));
      expect(out, contains('vocabulary anchor'));
      expect(out, isNot(contains('use its values directly')));
    });

    test('per-entry line format identical to brand-match variant', () {
      // Same _entry, both variants - line shape stays the same so the
      // prompt model doesn't need to learn two formats.
      final entry = _entry(
        id: '1',
        summary: 'Skyr Vanille',
        kcal: 120,
        protein: 18,
        carbs: 9,
        fat: 1,
        portionAmount: 150,
        portionUnit: 'g',
      );
      final brand =
          ClaudeClient.buildBrandHistoryBlock([entry], isDe: true);
      final tod = ClaudeClient.buildBrandHistoryBlock(
        [entry],
        isDe: true,
        timeOfDayFallback: true,
      );
      expect(brand, contains('- Skyr Vanille (150 g): kcal 120'));
      expect(tod, contains('- Skyr Vanille (150 g): kcal 120'));
    });
  });
}
