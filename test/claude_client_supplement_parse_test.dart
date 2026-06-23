import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nurturetrack/services/claude_client.dart';

// Locks parseSupplementLabel - the clinically sensitive path that turns a
// Vision label photo into stored per-day supplement values a nursing mother
// then relies on. Driven through a MockClient (no network, no refactor): the
// mock returns the Anthropic {content:[{text}]} envelope, with the supplement
// JSON as the inner text. Covers the dose math, alias handling, the N/A skip,
// the stringified-number coercion (the bug just fixed), and the two error
// paths. Unit correctness (µg vs mg) is intentionally out of scope here - that
// is a Vision/prompt concern, not this transform.

void main() {
  setUpAll(() {
    dotenv.testLoad(
        fileInput: 'NOURISHME_API_URL=https://test.example\nAPP_SECRET=secret');
  });

  // Wraps a supplement-JSON map in the model envelope the worker returns.
  ClaudeClient clientFor(Map<String, dynamic> supplementJson) {
    final body =
        jsonEncode({'content': [{'text': jsonEncode(supplementJson)}]});
    return ClaudeClient(
        httpClient: MockClient((_) async => http.Response(body, 200)));
  }

  // For the error paths: the inner reply text is raw (not valid JSON).
  ClaudeClient clientForRawText(String text) {
    final body = jsonEncode({'content': [{'text': text}]});
    return ClaudeClient(
        httpClient: MockClient((_) async => http.Response(body, 200)));
  }

  Future<SupplementParseResult> parse(ClaudeClient c, {String locale = 'en'}) =>
      c.parseSupplementLabel(Uint8List(0), locale: locale);

  test('1. doses_per_day multiplies the per-dose values into per-day', () async {
    final r = await parse(clientFor({
      'name': 'Test',
      'doses_per_day': 2,
      'values': {'vitamin_d_ug': 10, 'iron_mg': 7},
    }));
    expect(r.values['vitamin_d_ug'], 20);
    expect(r.values['iron_mg'], 14);
    expect(r.dosesPerDay, 2);
  });

  test('2. missing doses_per_day + serving_size default to 1 (values unchanged)',
      () async {
    final r = await parse(clientFor({
      'name': 'Test',
      'values': {'vitamin_d_ug': 10},
    }));
    expect(r.values['vitamin_d_ug'], 10);
    expect(r.dosesPerDay, 1);
    expect(r.servingSizeCapsules, 1);
  });

  // PINNED, not fixed: two aliases for the same nutrient in ONE reply are both
  // canonicalised to vitamin_d_ug and SUMMED (10 + 5 = 15). Flagged separately
  // for Vanessa to decide whether to dedupe - needs evidence the model ever
  // returns two aliases at once before changing behaviour.
  test('3. alias variants canonicalise and SUM (current behaviour, pinned)',
      () async {
    final r = await parse(clientFor({
      'name': 'Test',
      'doses_per_day': 1,
      'values': {'vitamin_d3_ug': 10, 'cholecalciferol_ug': 5},
    }));
    expect(r.values['vitamin_d_ug'], 15);
  });

  test('4. non-numeric value (N/A) is skipped → nutrient absent', () async {
    final r = await parse(clientFor({
      'name': 'Test',
      'doses_per_day': 1,
      'values': {'iron_mg': 'N/A', 'folate_ug': 400},
    }));
    expect(r.values.containsKey('iron_mg'), isFalse);
    expect(r.values['folate_ug'], 400);
  });

  test('5. stringified number is coerced, not dropped (FIXED behaviour)',
      () async {
    final r = await parse(clientFor({
      'name': 'Test',
      'doses_per_day': 1,
      'values': {'iron_mg': '14'},
    }));
    expect(r.values['iron_mg'], 14);
  });

  test('6. name is trimmed; empty values → name-only result', () async {
    final r = await parse(clientFor({
      'name': '  Femibion 2  ',
      'values': <String, dynamic>{},
    }));
    expect(r.name, 'Femibion 2');
    expect(r.values, isEmpty);
  });

  test('7. no JSON in reply → CoachApiException (localized DE)', () async {
    expect(
      () => parse(clientForRawText('Tut mir leid, ich kann das nicht lesen.'),
          locale: 'de'),
      throwsA(isA<CoachApiException>().having((e) => e.userMessage,
          'userMessage', contains('Etikett ließ sich nicht auslesen'))),
    );
  });

  test('8. malformed JSON → CoachApiException (localized DE)', () async {
    expect(
      () => parse(clientForRawText('{ name: not valid json, }'), locale: 'de'),
      throwsA(isA<CoachApiException>().having((e) => e.userMessage,
          'userMessage', contains('unleserlich'))),
    );
  });
}
