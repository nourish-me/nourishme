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
}
