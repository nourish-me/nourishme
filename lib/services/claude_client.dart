import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MealParseResult {
  final String summary;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final List<String> safetyWarnings;

  const MealParseResult({
    required this.summary,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.safetyWarnings,
  });
}

class ClaudeClient {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';
  static const _apiVersion = '2023-06-01';

  static const _systemPrompt = '''
Du bist ein Ernährungs-Assistent für eine stillende Mutter von Zwillingen.
Parse die beschriebene Mahlzeit in strukturierte Nährwerte und prüfe auf Food-Safety-Risiken beim Stillen.

Relevante Risiken:
- Quecksilberhaltiger Fisch (Thunfisch, Schwertfisch, Hai, Königsmakrele, Marlin)
- Koffein (Mengen ab ca. 200 mg/Tag relevant)
- Alkohol jeglicher Art
- Rohmilchprodukte, rohes Fleisch oder roher Fisch
- Kräuter die Milchbildung hemmen können (Salbei, Pfefferminze in größeren Mengen)

Wenn Mengen nicht angegeben sind, schätze konservativ auf Basis einer normalen Portion.

Antworte AUSSCHLIESSLICH mit JSON in diesem Schema, ohne Markdown-Codeblock, ohne Text davor oder danach:
{
  "summary": string,
  "kcal": int,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "safety_warnings": [string]
}

"summary" ist eine kurze deutsche Beschreibung, maximal 80 Zeichen.
"safety_warnings" ist eine Liste deutscher Hinweise, leer wenn nichts kritisch ist.
''';

  Future<MealParseResult> parseMeal(String userText) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY fehlt in .env');
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 600,
        'system': _systemPrompt,
        'messages': [
          {'role': 'user', 'content': userText},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Claude API Fehler ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content = body['content'] as List;
    final text = (content.first as Map)['text'] as String;

    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Claude hat kein JSON zurückgegeben: $text');
    }
    final parsed =
        jsonDecode(text.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

    return MealParseResult(
      summary: parsed['summary'] as String,
      kcal: (parsed['kcal'] as num).toInt(),
      proteinG: (parsed['protein_g'] as num).toDouble(),
      carbsG: (parsed['carbs_g'] as num).toDouble(),
      fatG: (parsed['fat_g'] as num).toDouble(),
      safetyWarnings: List<String>.from(parsed['safety_warnings'] as List),
    );
  }
}
