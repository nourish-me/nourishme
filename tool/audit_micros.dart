// Micronutrient parse-quality audit.
//
// Run: `dart run tool/audit_micros.dart`
//
// Sends a curated list of test meals through the Worker → Claude pipeline,
// parses the model's micronutrients map, and compares against reference
// values from standard German/US food tables (BLS, Souci/Fachmann/Kraut,
// USDA FoodData Central). Prints a markdown table flagging:
//   ✓ within ±30% of reference (accepted)
//   ⚠ 30-60% off (suspect)
//   ✗ >60% off OR missing while above the 5%-DGE threshold
//   • below 5%-DGE threshold - model correctly omits (no flag)
//
// One-shot diagnostic tool. Costs roughly 10-20 Haiku 4.5 calls (~5 cents).
// IMPORTANT: keep the embedded prompt in sync with lib/services/prompts/parse_de.dart
// - if that prompt changes its micronutrients spec, update this file too.

import 'dart:convert';
import 'dart:io';

// 5% of DGE 2025 lactation reference values (phase Vanessa is testing in).
// Values below these thresholds are correctly omitted by the model per the
// parse prompt's token-saving rule.
const _thresholds = <String, double>{
  'folate_ug': 22.5, // 450 µg × 5%
  'iron_mg': 0.8, // 16 mg × 5%
  'iodine_ug': 11.5, // 230 µg × 5%
  'vitamin_d_ug': 1.0, // 20 µg × 5%
  'dha_mg': 10.0, // 200 mg × 5%
  'b12_ug': 0.275, // 5.5 µg × 5%
  'calcium_mg': 50.0, // 1000 mg × 5%
  'choline_mg': 24.0, // 480 mg × 5%
  'zinc_mg': 0.55, // 11 mg × 5%
};

class TestCase {
  final String input;
  final Map<String, double> expected;
  const TestCase({required this.input, required this.expected});
}

// Reference values are BLS/Souci-level estimates for typical preparations.
// Targets aim at populating each micronutrient at least twice across the suite
// so we can spot per-nutrient systemic bias (e.g. iron consistently too high).
const _tests = <TestCase>[
  TestCase(
    input: '100g Lachsfilet, gegart',
    expected: {
      'dha_mg': 1200,
      'vitamin_d_ug': 13,
      'iodine_ug': 33,
      'b12_ug': 3.0,
    },
  ),
  TestCase(
    input: '1 Ei (Größe M, ca. 60g), gekocht',
    expected: {
      'choline_mg': 147,
      'b12_ug': 0.5,
      'vitamin_d_ug': 1.1,
    },
  ),
  TestCase(
    input: '200g Skyr natur',
    expected: {
      'calcium_mg': 300,
      'b12_ug': 0.8,
    },
  ),
  TestCase(
    input: '100g rote Linsen, gekocht',
    expected: {
      'iron_mg': 3.3,
      'folate_ug': 180,
      'zinc_mg': 1.3,
    },
  ),
  TestCase(
    input: '30g Sonnenblumenkerne',
    expected: {
      'folate_ug': 70,
      'zinc_mg': 1.5,
    },
  ),
  TestCase(
    input: '200g Brokkoli, gegart',
    expected: {
      'folate_ug': 130,
      'calcium_mg': 80,
    },
  ),
  TestCase(
    input: '150g Rinderhackfleisch, gebraten',
    expected: {
      'iron_mg': 4.0,
      'zinc_mg': 7.0,
      'b12_ug': 3.0,
      'choline_mg': 110,
    },
  ),
  TestCase(
    input: '100g Hering, geräuchert',
    expected: {
      'vitamin_d_ug': 25,
      'dha_mg': 1800,
      'iodine_ug': 50,
      'b12_ug': 8.5,
    },
  ),
  TestCase(
    input: '200ml Vollmilch (3,5% Fett)',
    expected: {
      'calcium_mg': 240,
      'iodine_ug': 16,
      'b12_ug': 0.8,
    },
  ),
  TestCase(
    input: '1 mittelgroßer Apfel (150g)',
    // Apple has no micros above 5% threshold - expect all keys omitted.
    expected: {},
  ),
];

// Mirrors the relevant portion of lib/services/prompts/parse_de.dart so this
// audit measures the actual production prompt. Keep in sync if the source
// prompt changes.
const _systemPrompt = '''Du bist ein Ernährungs-Parser für stillende Frauen. Antworte AUSSCHLIESSLICH mit einem JSON-Objekt mit folgenden Feldern (keine Vorrede, kein Markdown):

{
  "is_meal": bool,
  "summary": string,
  "kcal": number,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "portion_amount": number,
  "portion_unit": string,
  "portion_alias": string oder null,
  "safety_warnings": array of strings,
  "micronutrients": object (siehe Regeln unten) oder weglassen
}

"micronutrients" (optional, Token-sparen): Schätze für diese Mahlzeit die relevanten Mikronährstoffe nach folgendem Schema. Erlaubte Keys (Unit ist im Namen):
- folate_ug: Folat in Mikrogramm DFE
- iron_mg: Eisen in Milligramm
- iodine_ug: Jod in Mikrogramm
- vitamin_d_ug: Vitamin D in Mikrogramm
- dha_mg: DHA (Omega-3) in Milligramm
- b12_ug: Vitamin B12 in Mikrogramm
- calcium_mg: Calcium in Milligramm
- choline_mg: Cholin in Milligramm
- zinc_mg: Zink in Milligramm

PLAUSIBILITÄTS-ANKER (typische Werte pro 100 g bzw. 100 ml im rohen oder gegarten Zustand, daran orientieren bevor du raufschätzt):
- Iod: Seefisch (Lachs, Kabeljau, Hering, Seelachs) 20-50 µg, Schellfisch/Kabeljau bis 200 µg, Vollmilch 6-9 µg/100 ml, iodiertes Salz ca. 2 µg/g, Algen variabel. Werte >100 µg/100 g sind außerhalb von Schalentieren/mageren Seefischen unplausibel.
- Vitamin D: fetter Seefisch (Lachs 12-16, Hering 22-26, Makrele 4 µg/100 g), Ei ca. 1.1 µg pro Stück (60 g), Pilze nur wenn UV-belichtet. Mageres Fleisch, Gemüse, Getreide nahe null.
- DHA: fetter Seefisch (Lachs 1100-1400, Hering 1500-2000, Makrele 1100-1300, Sardine 900-1100 mg/100 g), Eigelb 30-40 mg/Stück. Mageres Fleisch, Pflanzen, magerer Fisch nahe null.
- B12: Rind 2-3 µg/100 g, Schwein/Geflügel 0.5-1 µg, Lachs/Forelle ca. 3 µg, fettiger Räucherfisch (Hering, Makrele, Sardine) 8-9 µg/100 g, Milch/Joghurt 0.4 µg/100 g. Pflanzlich null.
- Eisen: Hülsenfrüchte gegart (Linsen 3, Kichererbsen 2.5, Bohnen 2 mg/100 g), Rindfleisch 2.5-3, Spinat gegart 3.5, Tofu 2.5 mg/100 g. Getreide-Vollkorn 2-3 mg/100 g.
- Folat: Hülsenfrüchte gegart (Linsen 180, Kichererbsen 170 µg/100 g), grünes Blattgemüse roh (Spinat 145, Feldsalat 145 µg/100 g), Sonnenblumenkerne 230 µg/100 g, Brokkoli gegart 60 µg/100 g.
- Cholin: Eigelb ca. 250 mg/100 g (entspricht ca. 145 mg pro Ei), Rinderleber 330 mg/100 g, Rind/Schwein 70-85 mg/100 g, Hähnchen 60-80 mg/100 g, Lachs 60-65 mg/100 g, Sojabohnen 115 mg/100 g, Weizenkeime 150 mg/100 g, Brokkoli/Blumenkohl 40 mg/100 g. Pflanzliche Vollwertkost außer Hülsenfrüchten/Weizenkeimen meist unter 30 mg/100 g.

WICHTIG zur Effizienz: liste NUR Nährstoffe deren Wert in dieser Mahlzeit mindestens ~5% der Tagesreferenz (DGE 2025) erreicht. Bei kleineren Werten den Key komplett weglassen. Werte sind pro DIESE Mahlzeit, nicht pro 100g.
''';

Map<String, String> _parseEnv(String contents) {
  final out = <String, String>{};
  for (final line in contents.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    out[key] = value;
  }
  return out;
}

class ParseResponse {
  final Map<String, double> micronutrients;
  final String summary;
  ParseResponse({required this.micronutrients, required this.summary});
}

Future<ParseResponse> _callWorker({
  required String proxyUrl,
  required String appSecret,
  required String userText,
}) async {
  final url = Uri.parse('$proxyUrl/messages');
  final body = jsonEncode({
    'model': 'claude-haiku-4-5-20251001',
    'max_tokens': 800,
    'system': _systemPrompt,
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'text',
            'text':
                'Phase der Nutzerin: produziert Muttermilch (stillt oder pumpt). Gib NUR safety_warnings, die zu DIESER Phase passen.\n\n$userText',
          },
        ],
      },
    ],
  });
  final client = HttpClient();
  try {
    final req = await client.postUrl(url);
    req.headers.set('content-type', 'application/json');
    req.headers.set('x-app-secret', appSecret);
    req.headers.set('x-call-type', 'audit');
    req.write(body);
    final resp = await req.close();
    final respBody = await resp.transform(utf8.decoder).join();
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $respBody');
    }
    // Worker proxies the Anthropic response; content[0].text holds the model
    // output. Extract, then JSON-parse the model's reply.
    final outer = jsonDecode(respBody) as Map<String, dynamic>;
    final content = outer['content'] as List;
    final text = (content.first as Map)['text'] as String;
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw Exception('Model returned non-JSON: ${text.substring(0, 200)}');
    }
    final parsed = jsonDecode(text.substring(start, end + 1)) as Map;
    final summary = (parsed['summary'] as String?) ?? '?';
    final micros = (parsed['micronutrients'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ) ??
        const <String, double>{};
    return ParseResponse(micronutrients: micros, summary: summary);
  } finally {
    client.close();
  }
}

String _classify(String key, double? expected, double? actual) {
  final threshold = _thresholds[key] ?? 0;
  final expectedAboveThreshold = (expected ?? 0) >= threshold;
  final actualAboveThreshold = (actual ?? 0) >= threshold;

  // Both omitted or both below threshold → fine.
  if (!expectedAboveThreshold && !actualAboveThreshold) return '·';
  // Model omitted but expected value is above threshold → miss.
  if (!actualAboveThreshold) return '✗ missing';
  // Model included but expected is below threshold → spurious.
  if (!expectedAboveThreshold) return '⚠ spurious';

  final ratio = actual! / expected!;
  if (ratio >= 0.7 && ratio <= 1.3) return '✓';
  if (ratio >= 0.4 && ratio <= 1.6) return '⚠ ${(ratio * 100).round()}%';
  return '✗ ${(ratio * 100).round()}%';
}

Future<void> main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('No .env in working directory. Run from project root.');
    exit(1);
  }
  final env = _parseEnv(envFile.readAsStringSync());
  final proxyUrl = env['NOURISHME_API_URL'];
  final appSecret = env['APP_SECRET'];
  if (proxyUrl == null || appSecret == null) {
    stderr.writeln('NOURISHME_API_URL or APP_SECRET missing from .env');
    exit(1);
  }

  print('## Micronutrient parse audit\n');
  print('Reference values from BLS / Souci / USDA-FDC.');
  print(
      'Threshold: model is told to omit any micro below 5% of DGE-lactation reference.\n');

  // All micro keys we'll show in the table, in display order.
  const keysInOrder = [
    'iron_mg',
    'folate_ug',
    'b12_ug',
    'vitamin_d_ug',
    'iodine_ug',
    'dha_mg',
    'choline_mg',
    'calcium_mg',
    'zinc_mg',
  ];

  // Header
  final header = ['Meal', ...keysInOrder];
  print('| ${header.join(' | ')} |');
  print('|${header.map((_) => '---').join('|')}|');

  for (final t in _tests) {
    stderr.writeln('→ ${t.input}');
    try {
      final r = await _callWorker(
        proxyUrl: proxyUrl,
        appSecret: appSecret,
        userText: t.input,
      );
      final cells = <String>[];
      cells.add(r.summary.length > 28 ? '${r.summary.substring(0, 25)}...' : r.summary);
      for (final key in keysInOrder) {
        final expected = t.expected[key];
        final actual = r.micronutrients[key];
        final verdict = _classify(key, expected, actual);
        final actualStr =
            actual == null ? '-' : actual.toStringAsFixed(actual >= 50 ? 0 : 1);
        final expectedStr =
            expected == null ? '-' : expected.toStringAsFixed(expected >= 50 ? 0 : 1);
        cells.add('$actualStr / $expectedStr $verdict');
      }
      print('| ${cells.join(' | ')} |');
    } catch (e) {
      print('| ${t.input} | ERROR: $e |');
    }
  }

  print('\nLegend: actual / expected. ✓ ±30%, ⚠ 30-60% off, ✗ >60% off or missing, · both below threshold.');
}
