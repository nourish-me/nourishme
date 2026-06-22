// Golden food->micros eval (Plan 2026-06-22-parser-micro-reliability, Phase 3+4).
//
// Release gate for the parser's micronutrient reliability. Because the parser is
// an LLM (non-deterministic), each food is run N times and judged by MAJORITY:
// a food is GREEN if it passes in at least ceil(N/2) runs. Per run it checks
//   - every `expect` key present and within [min,max]  (catches UNDER-reporting)
//   - no `absent` key returned above the corpus epsilon (catches OVER-reporting)
// Prints a per-food pass-rate + the problems seen, and exits non-zero if any food
// is not green, so it can gate a release.
//
// Run before each TestFlight build:  dart run tool/micro_eval.dart
// Optional first arg = runs per food (default 3).  Needs .env at the repo root.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nurturetrack/services/prompts/parse_de.dart';

Future<void> main(List<String> argv) async {
  final runs = argv.isNotEmpty ? int.tryParse(argv.first) ?? 3 : 3;
  final majority = (runs / 2).ceil();

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

  print('Eval: $runs Runs/Food, grün ab $majority/$runs.\n');
  var green = 0;
  final notGreen = <String>[];

  for (final food in foods) {
    final meal = food['meal'] as String;
    final expect = (food['expect'] as Map).cast<String, dynamic>();
    final absent = (food['absent'] as List).cast<String>();

    var pass = 0;
    final notes = <String>[];
    for (var r = 0; r < runs; r++) {
      Map<String, dynamic> micros;
      try {
        micros = await _parse(url, secret, phase, meal);
      } catch (e) {
        notes.add('run$r REQUEST-FEHLER: $e');
        continue;
      }
      final problems = _check(expect, absent, micros, epsilon);
      if (problems.isEmpty) {
        pass++;
      } else {
        notes.add('run$r: ${problems.join("; ")}');
      }
    }

    final isGreen = pass >= majority;
    if (isGreen) green++;
    print('${isGreen ? "✓" : "✗"} $pass/$runs  $meal');
    if (!isGreen) {
      notGreen.add('$meal ($pass/$runs)');
      for (final n in notes) {
        print('    $n');
      }
    }
  }

  print('\n=== ${green}/${foods.length} Foods grün (Mehrheit) ===');
  if (notGreen.isNotEmpty) {
    print('NICHT grün:');
    for (final f in notGreen) {
      print('  - $f');
    }
    exitCode = 1;
  }
}

List<String> _check(Map<String, dynamic> expect, List<String> absent,
    Map<String, dynamic> micros, double epsilon) {
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
  return problems;
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
  if (resp.statusCode != 200) {
    throw 'HTTP ${resp.statusCode}: ${resp.body.substring(0, resp.body.length.clamp(0, 160))}';
  }
  final body = jsonDecode(resp.body) as Map<String, dynamic>;
  final content = body['content'];
  if (content is! List || content.isEmpty) {
    throw 'unerwartete Antwort (kein content): ${resp.body.substring(0, resp.body.length.clamp(0, 160))}';
  }
  final text = (content.first as Map)['text'] as String;
  final js = jsonDecode(
          text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1))
      as Map<String, dynamic>;
  return (js['micronutrients'] as Map?)?.cast<String, dynamic>() ?? {};
}
