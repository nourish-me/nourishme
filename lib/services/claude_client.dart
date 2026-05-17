import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MealParseResult {
  final bool isMeal;
  final String? rejectionReason;
  final String summary;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double portionAmount;
  final String portionUnit;
  final List<String> safetyWarnings;

  const MealParseResult({
    required this.isMeal,
    required this.rejectionReason,
    required this.summary,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.portionAmount,
    required this.portionUnit,
    required this.safetyWarnings,
  });
}

class ChatTurn {
  final bool isUser;
  final String text;
  const ChatTurn({required this.isUser, required this.text});
}

class ClaudeClient {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';
  static const _apiVersion = '2023-06-01';

  static const _parsePrompt = '''
Du bist ein Ernährungs-Assistent für eine stillende Mutter von Zwillingen.
Parse den beschriebenen Eintrag in strukturierte Nährwerte und prüfe auf Food-Safety-Risiken beim Stillen.

Akzeptiere alle Arten von Nahrungsaufnahme: vollwertige Mahlzeiten, Snacks, Süßes, sowie Getränke wie Kaffee, Tee, Saft, Smoothie, Milch, Limonade, Alkohol oder Wasser (Wasser darf 0 kcal haben).

Relevante Risiken:
- Quecksilberhaltiger Fisch (Thunfisch, Schwertfisch, Hai, Königsmakrele, Marlin)
- Koffein (Mengen ab ca. 200 mg/Tag relevant)
- Alkohol jeglicher Art
- Rohmilchprodukte, rohes Fleisch oder roher Fisch
- Kräuter die Milchbildung hemmen können (Salbei, Pfefferminze in größeren Mengen)

Wenn Mengen nicht angegeben sind, schätze konservativ auf Basis einer normalen Portion oder Tasse.

Wenn ein Bild beigefügt ist, analysiere zusätzlich das Foto. Nutze sichtbare Referenzobjekte (Besteck, Hand, bekannte Verpackungen, Teller, Tasse) für die Portionsschätzung. Wenn Text und Bild vorhanden sind und der Text eine konkrete Menge nennt, vertraue dem Text bei der Menge und nutze das Bild zur Identifikation der Speise.

Wenn die Eingabe keine Nahrungsaufnahme beschreibt (z.B. Zufallszeichen, leere Wörter, nicht-essbare Dinge, eine Frage), setze "is_meal" auf false und gib in "rejection_reason" einen kurzen deutschen Hinweis zurück, z.B. "Bitte beschreibe ein Essen oder Getränk." In dem Fall dürfen kcal und Makros 0 sein und safety_warnings leer bleiben.

Schätze für jeden Eintrag auch die Portionsgröße als einzelne Zahl mit Einheit ("g" für feste/breiige Speisen, "ml" für Getränke). Für Mischmahlzeiten gib die Gesamtmenge an.

Antworte AUSSCHLIESSLICH mit JSON in diesem Schema, ohne Markdown-Codeblock, ohne Text davor oder danach:
{
  "is_meal": bool,
  "rejection_reason": string oder null,
  "summary": string,
  "kcal": int,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "portion_amount": number,
  "portion_unit": string ("g" oder "ml"),
  "safety_warnings": [string]
}

"summary" ist eine kurze deutsche Beschreibung, maximal 80 Zeichen.
"portion_amount" und "portion_unit" zusammen müssen plausibel zur summary passen. Bei is_meal=false dürfen sie 0 bzw. "g" sein.
"safety_warnings" enthält ausschließlich gesundheitliche Hinweise zum Stillen, niemals Eingabe-Probleme. Leer wenn nichts kritisch ist.
''';

  static const _tipPrompt = '''
Du bist eine freundliche Ernährungs-Assistentin für eine stillende Mutter von Zwillingen (exklusiv stillend).
Gib einen kurzen, konkreten Coaching-Tipp basierend auf dem heutigen Stand.
Maximal 2 Sätze auf Deutsch. Sei warm aber knapp. Keine Anrede, direkt zum Tipp.
Wenn die Mutter heute deutlich unter dem Kalorienziel ist, weise darauf hin (Stillen braucht Energie). Wenn sie schon nah am Ziel ist, lobe und mache ggf. einen Vorschlag fürs Nährstoffprofil (z.B. mehr Protein, Wasser).
''';

  static const _chatPromptBase = '''
Du bist eine freundliche Ernährungs-Assistentin für eine stillende Mutter von Zwillingen (exklusiv stillend).
Antworte auf Deutsch, präzise und einfühlsam. Halte dich kurz, maximal 4-5 Sätze pro Antwort, außer eine Liste oder Aufzählung ist sinnvoll.
Beziehe dich auf Stillen-Sicherheit (Quecksilber, Koffein, Alkohol, Kräuter) wo relevant.
Wenn die Frage offen ist (z.B. nach Mahlzeitenideen), gib 2-3 konkrete Vorschläge.
''';

  Future<String> _post({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    int maxTokens = 600,
  }) async {
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
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': messages,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Claude API Fehler ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final responseContent = body['content'] as List;
    return (responseContent.first as Map)['text'] as String;
  }

  Future<MealParseResult> parseMeal(
    String userText, {
    Uint8List? imageBytes,
  }) async {
    final List<Map<String, dynamic>> content = [];
    if (imageBytes != null) {
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }
    content.add({
      'type': 'text',
      'text': userText.isEmpty
          ? 'Schätze diesen Eintrag basierend auf dem Bild.'
          : userText,
    });

    final text = await _post(
      systemPrompt: _parsePrompt,
      messages: [
        {'role': 'user', 'content': content},
      ],
    );

    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Claude hat kein JSON zurückgegeben: $text');
    }
    final parsed =
        jsonDecode(text.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

    return MealParseResult(
      isMeal: parsed['is_meal'] as bool? ?? true,
      rejectionReason: parsed['rejection_reason'] as String?,
      summary: parsed['summary'] as String? ?? '',
      kcal: (parsed['kcal'] as num?)?.toInt() ?? 0,
      proteinG: (parsed['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (parsed['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (parsed['fat_g'] as num?)?.toDouble() ?? 0,
      portionAmount: (parsed['portion_amount'] as num?)?.toDouble() ?? 0,
      portionUnit: parsed['portion_unit'] as String? ?? 'g',
      safetyWarnings: List<String>.from(parsed['safety_warnings'] as List? ?? const []),
    );
  }

  Future<String> generateCoachingTip({
    required String justEatenSummary,
    required int justEatenKcal,
    required int totalKcalToday,
    required int targetKcal,
    required List<String> safetyWarnings,
  }) async {
    final remaining = targetKcal - totalKcalToday;
    final hour = DateTime.now().hour;
    final warningLine = safetyWarnings.isEmpty
        ? ''
        : '\nSafety-Hinweise zur Mahlzeit: ${safetyWarnings.join(", ")}.';
    final userMessage = '''
Gerade eingetragen: $justEatenSummary ($justEatenKcal kcal).
Heutiger Stand inkl. Eintrag: $totalKcalToday von $targetKcal kcal (verbleibend: $remaining kcal).
Uhrzeit: $hour Uhr.$warningLine
''';
    return _post(
      systemPrompt: _tipPrompt,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      maxTokens: 200,
    );
  }

  Future<String> chat({
    required List<ChatTurn> history,
    required String todayContext,
  }) async {
    final messages = history
        .map((turn) => {
              'role': turn.isUser ? 'user' : 'assistant',
              'content': turn.text,
            })
        .toList();
    return _post(
      systemPrompt: '$_chatPromptBase\n\nKontext heute:\n$todayContext',
      messages: messages,
      maxTokens: 600,
    );
  }
}
