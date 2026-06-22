// Golden food->micros eval (Plan 2026-06-22-parser-micro-reliability, Phase 1+4).
//
// Release gate for the parser's micronutrient reliability: posts each food in
// test/fixtures/micro_corpus.json to the live worker, parses the returned
// `micronutrients`, and checks
//   - every `expect` key is present and within [min,max]  (catches UNDER-reporting)
//   - no `absent` key is returned above the corpus epsilon (catches OVER-reporting)
// Prints a per-food report and a pass/fail summary, and exits non-zero on any
// failure so it can gate a release.
//
// Run before each TestFlight build:  dart run tool/micro_eval.dart
// Needs .env (NOURISHME_API_URL + APP_SECRET) at the repo root.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nurturetrack/services/prompts/parse_de.dart';

Future<void> main() async {
  final env = <String, String>{};
  for (final line in File('.env').readAsLinesSync()) {
    final i = line.indexOf('=');
    if (i > 0) env[line.substring(0, i).trim()] = line.substring(i + 1).trim();
  }
  final url = '${env['NOURISHME_API_URL']}/messages';
  final secret = env['APP_SECRET'] ?? '';

  final corpus = jsonDecode(
      File('test/fixtures/micro_corpus.json').readAsStringSync()) as Map<String, dynamic>;
  final phase = corpus['phase'] as String;
  final epsilon = (corpus['epsilon'] as num).toDouble();
  final foods = (corpus['foods'] as List).cast<Map<String, dynamic>>();

  var passed = 0;
  final failures = <String>[];

  for (final food in foods) {
    final meal = food['meal'] as String;
    final expect = (food['expect'] as Map).cast<String, dynamic>();
    final absent = (food['absent'] as List).cast<String>();

    Map<String, dynamic> micros;
    try {
      micros = await _parse(url, secret, phase, meal);
    } catch (e) {
      failures.add('$meal → REQUEST/PARSE FEHLER: $e');
      print('✗ $meal\n    Request/Parse-Fehler: $e');
      continue;
    }

    final problems = <String>[];
    expect.forEach((key, range) {
      final lo = (range[0] as num).toDouble();
      final hi = (range[1] as num).toDouble();
      final v = (micros[key] as num?)?.toDouble();
      if (v == null) {
        problems.add('UNTER: $key fehlt (erwartet $lo–$hi)');
      } else if (v < lo || v > hi) {
        problems.add('AUSSER-BEREICH: $key=$v (erwartet $lo–$hi)');
      }
    });
    for (final key in absent) {
      final v = (micros[key] as num?)?.toDouble();
      if (v != null && v > epsilon) {
        problems.add('ÜBER: $key=$v (sollte fehlen)');
      }
    }

    if (problems.isEmpty) {
      passed++;
      print('✓ $meal');
    } else {
      failures.add('$meal → ${problems.join("; ")}');
      print('✗ $meal');
      for (final p in problems) {
        print('    $p');
      }
      print('    geliefert: $micros');
    }
  }

  print('\n=== ${passed}/${foods.length} bestanden ===');
  if (failures.isNotEmpty) {
    print('FEHLER:');
    for (final f in failures) {
      print('  - $f');
    }
    exitCode = 1;
  }
}

Future<Map<String, dynamic>> _parse(
    String url, String secret, String phase, String meal) async {
  final resp = await http.post(
    Uri.parse(url),
    headers: {
      'content-type': 'application/json',
      'x-app-secret': secret,
      'x-call-type': 'parse',
      'x-locale': 'de',
    },
    body: jsonEncode({
      'model': 'claude-haiku-4-5-20251001',
      'max_tokens': 700,
      'system': [
        {'type': 'text', 'text': parsePromptDe, 'cache_control': {'type': 'ephemeral'}}
      ],
      'messages': [
        {'role': 'user', 'content': 'Phase: $phase.\n\n$meal'}
      ],
    }),
  );
  final body = jsonDecode(resp.body) as Map<String, dynamic>;
  final text = (body['content'] as List).first['text'] as String;
  final js = jsonDecode(
          text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1))
      as Map<String, dynamic>;
  return (js['micronutrients'] as Map?)?.cast<String, dynamic>() ?? {};
}
