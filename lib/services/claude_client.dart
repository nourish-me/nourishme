import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'nutrition_facts.dart';

// Exception with a human-readable message safe to surface in the UI. The
// caller can show e.userMessage directly; the technical detail is kept for
// logs only.
class CoachApiException implements Exception {
  final String userMessage;
  final String? technical;
  CoachApiException(this.userMessage, [this.technical]);

  @override
  String toString() => technical != null
      ? '$userMessage ($technical)'
      : userMessage;
}

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
  // Optional human-friendly equivalent for the amount, e.g. "eine Handvoll",
  // "2 EL", "ein kleiner Becher". Surfaced beside the gram/ml number so the
  // user can sanity-check the magnitude without weighing.
  final String? portionAlias;
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
    required this.portionAlias,
    required this.safetyWarnings,
  });
}

class ChatTurn {
  final bool isUser;
  final String text;
  const ChatTurn({required this.isUser, required this.text});
}

class ClaudeClient {
  // We always go through our Cloudflare Worker proxy so the Anthropic key
  // never lives in the app bundle. The Worker injects the x-api-key header
  // server-side; the app only carries APP_SECRET, which limits casual abuse
  // and can be rotated without breaking the Anthropic credential.
  // Fallback to the direct Anthropic endpoint exists only for legacy local
  // development before the proxy was deployed.
  static const _directEndpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';
  static const _apiVersion = '2023-06-01';

  static String get _proxyUrl => dotenv.env['NOURISHME_API_URL'] ?? '';
  static String get _appSecret => dotenv.env['APP_SECRET'] ?? '';
  static String get _legacyApiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static bool get _usingProxy =>
      _proxyUrl.isNotEmpty && _appSecret.isNotEmpty;

  static final _parsePrompt = '''
Du bist ein Ernährungs-Assistent für eine Mutter, die Muttermilch produziert (egal ob sie direkt stillt oder ausschließlich abpumpt) oder schwanger ist.
Parse den beschriebenen Eintrag in strukturierte Nährwerte und prüfe auf Food-Safety-Risiken.

Vermeide in deinen safety_warnings das Wort "Stillen" und Variationen davon (stillende Mutter, beim Stillen, etc.), weil viele Mütter ausschließlich pumpen und sich davon nicht angesprochen fühlen. Nutze stattdessen neutrale Formulierungen wie "während du Muttermilch produzierst", "in dieser Phase", "Alkohol geht in die Muttermilch über", "Koffein gelangt zum Baby" o.ä.

Akzeptiere alle Arten von Nahrungsaufnahme: vollwertige Mahlzeiten, Snacks, Süßes, sowie Getränke wie Kaffee, Tee, Saft, Smoothie, Milch, Limonade, Alkohol oder Wasser (Wasser darf 0 kcal haben).

${NutritionFacts.coachContextBlock}

Nutze diese Schwellen für safety_warnings. Konkret bei jedem Eintrag prüfen:
- Koffeinmenge des Eintrags schätzen. Bei einer Tagesüberschreitung von 200 mg warnen.
- Alkohol: jegliche Menge in SS warnen. In Stillzeit Wartezeit nennen (ca. 2-2,5 h pro Standarddrink).
- Fisch: bei Quecksilber-Großraubfisch warnen, alternativ benennen.
- Rohmilch/Rohfleisch/Sushi: in SS auf Listeria-Risiko hinweisen.
- Leber: in T1 SS warnen (Vitamin A teratogen, UL 3.000 µg).
- Salbei-Tee / Pfefferminzöl: bei größeren Mengen auf milchhemmende Wirkung hinweisen.

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
  "portion_alias": string oder null,
  "safety_warnings": [string]
}

"summary" ist eine kurze deutsche Beschreibung, maximal 80 Zeichen.
"portion_amount" und "portion_unit" zusammen müssen plausibel zur summary passen. Bei is_meal=false dürfen sie 0 bzw. "g" sein.
"portion_alias" ist eine handliche Bezugsgröße auf Deutsch, max. 25 Zeichen, die der Userin hilft die Menge ohne Waage einzuschätzen. Beispiele: "eine Handvoll", "2 EL", "ein kleiner Becher", "1 Handfläche", "ein gehäufter TL", "1 mittlere Schüssel". Wenn keine sinnvolle Bezugsgröße existiert (z. B. Wasser, Mineralwasser): null.
"safety_warnings" enthält ausschließlich gesundheitliche Hinweise zum Stillen, niemals Eingabe-Probleme. Leer wenn nichts kritisch ist.
''';

  static final _perMealPrompt = '''
Du bist eine Ernährungs-Coach für eine Frau, die Muttermilch produziert (direkt stillend oder ausschließlich pumpend) oder schwanger ist.
Antworte auf Deutsch, sachlich, ohne Smalltalk, ohne Anrede. Sei wissenschaftlich fundiert: nenne konkrete Zahlen aus DGE/EFSA/BfR wenn relevant.

${NutritionFacts.coachContextBlock}

Antworte strikt in folgendem Markdown-Format. Keine Tabellen, sie passen auf Handy-Bildschirmen nicht. Keine zusätzlichen Sätze davor oder danach.

**Bestandteile:** (NUR wenn die Mahlzeit aus mehreren Komponenten besteht. Bei einer Komponente diesen Block komplett weglassen.)
- <Bestandteil>, <Menge> — <kcal> kcal · P <g> · KH <g> · F <g>
- ... weitere Bestandteile in derselben Form

**🟢 Stark:** ein bis zwei Stärken in einem Satz
**🟡 Knapp:** ein bis zwei Schwachpunkte, falls relevant

**Was heute noch fehlt:** kurz, mit kcal-Split auf die nächsten Mahlzeiten
**Nächste Mahlzeit:** Empfehlung mit Timing und konkretem Lebensmittel-Vorschlag

Regeln:
- Bestandteile aus dem Originaltext oder der Beschreibung schätzen, Mengen in g, ml oder Stück
- Jeder Bestandteil auf einer eigenen Zeile, kompakt mit Trennzeichen ·
- KEINE Gesamt-Zeile, kcal stehen schon auf der Mahlzeit-Karte und Makros werden in der Toolbar gezählt
- Wiederhole NICHT den Tagesstand in kcal oder Protein, der ist in der Toolbar oben sichtbar
- Mikronährstoffe (Eisen, Calcium, Folat, Omega-3) nur nennen wenn sie zur Mahlzeit oder Tagesphase passen
- Maximal 120 Wörter
- Vermeide das Wort "Stillen" und seine Varianten. Nutze "während du Muttermilch produzierst" oder "in dieser Phase", weil viele Mütter ausschließlich pumpen
- Die Nutzerdaten (Gewicht, Aktivität, Anzahl Kinder, Milchvolumen, etc.) sind im Profil mitgeliefert. Nutze sie SOFORT und FRAG NIEMALS danach.
''';

  static final _chatPromptBase = '''
Du bist ein wissenschaftlich fundierter Ernährungs-Coach für eine Mutter, die Muttermilch produziert (direkt stillend oder ausschließlich pumpend) oder schwanger ist.
Antworte auf Deutsch, präzise und einfühlsam. Halte dich kurz, maximal 4-5 Sätze pro Antwort, außer eine Liste oder Aufzählung ist sinnvoll.
Zitiere konkrete Zahlen und Quellen (DGE, BfR, EFSA, LactMed, FDA/EPA) wo relevant statt vager Aussagen.
Wenn die Frage offen ist (z.B. nach Mahlzeitenideen), gib 2-3 konkrete Vorschläge.

KRITISCH: Die Nutzerdaten (Gewicht, Größe, Alter, Aktivität, Phase, Anzahl Kinder, Kinder-Alter, Milchvolumen, Trimester) und die heutigen Tageswerte (kcal, Protein, etc.) sind dir im Profil und Tageskontext mitgeliefert. Nutze sie SOFORT in deinen Antworten.
- Frage NIEMALS nach Daten die schon im Profil oder Tageskontext stehen.
- Wenn jemand nach Protein-Bedarf fragt, rechne ihn direkt mit dem mitgelieferten Gewicht und nenne die konkrete Zahl.
- Wenn jemand nach Wasser-Bedarf fragt, rechne mit dem mitgelieferten Milchvolumen.
- Sätze wie "wenn du mir dein Gewicht sagst" sind verboten, das Gewicht ist schon da.

Vermeide das Wort "Stillen" und Variationen (stillende Mutter, beim Stillen). Nutze stattdessen "während du Muttermilch produzierst", "Mütter, die pumpen oder anlegen", "in dieser Phase", weil viele Mütter ausschließlich pumpen.

${NutritionFacts.coachContextBlock}
''';

  static String describeProfile(int numChildren, int sharePercent) {
    if (numChildren <= 0) return 'Profil: aktuell keine Milchabgabe (z.B. Schwangerschaft oder bereits abgestillt).';
    final share = sharePercent == 100
        ? 'ausschließlich (100%)'
        : sharePercent >= 75
            ? 'hauptsächlich ($sharePercent%)'
            : sharePercent >= 50
                ? 'etwa zur Hälfte ($sharePercent%)'
                : sharePercent >= 25
                    ? 'teilweise ($sharePercent%)'
                    : 'wenig ($sharePercent%)';
    final kinder = numChildren == 1 ? 'ein Kind' : '$numChildren Kinder';
    return 'Profil: versorgt $kinder mit eigener Milch, jeweils $share.';
  }

  Future<String> _post({
    required String systemPrompt,
    required List<Map<String, dynamic>> messages,
    int maxTokens = 600,
  }) async {
    final url = _usingProxy
        ? Uri.parse('$_proxyUrl/messages')
        : Uri.parse(_directEndpoint);
    final headers = <String, String>{
      'content-type': 'application/json',
    };
    if (_usingProxy) {
      headers['x-app-secret'] = _appSecret;
    } else {
      if (_legacyApiKey.isEmpty) {
        throw CoachApiException(
          'App ist nicht konfiguriert. Bitte sag Vanessa Bescheid.',
          '.env hat weder NOURISHME_API_URL+APP_SECRET noch ANTHROPIC_API_KEY',
        );
      }
      headers['x-api-key'] = _legacyApiKey;
      headers['anthropic-version'] = _apiVersion;
    }
    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'model': _model,
              'max_tokens': maxTokens,
              'system': systemPrompt,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw CoachApiException(
        'Der Coach braucht gerade lange. Probier es gleich nochmal.',
        'timeout after 30s',
      );
    } on SocketException catch (e) {
      throw CoachApiException(
        'Keine Internetverbindung. Probier es gleich nochmal.',
        e.message,
      );
    } on http.ClientException catch (e) {
      throw CoachApiException(
        'Verbindungsproblem. Probier es gleich nochmal.',
        e.message,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CoachApiException(
        'Auth-Problem. Bitte sag Vanessa Bescheid.',
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }
    if (response.statusCode == 429) {
      throw CoachApiException(
        'Coach gerade überlastet. Versuch es in einer Minute.',
        'HTTP 429',
      );
    }
    if (response.statusCode >= 500) {
      throw CoachApiException(
        'Coach gerade nicht erreichbar. Versuch es bald nochmal.',
        'HTTP ${response.statusCode}',
      );
    }
    if (response.statusCode != 200) {
      throw CoachApiException(
        'Etwas ist schiefgelaufen. Probier es nochmal.',
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
      portionAlias: (parsed['portion_alias'] as String?)?.trim().isEmpty == true
          ? null
          : parsed['portion_alias'] as String?,
      safetyWarnings: List<String>.from(parsed['safety_warnings'] as List? ?? const []),
    );
  }

  Future<String> generatePerMealResponse({
    required String mealRawText,
    required String mealSummary,
    required int mealKcal,
    required double mealProteinG,
    required double mealCarbsG,
    required double mealFatG,
    required List<String> safetyWarnings,
    required int totalKcalToday,
    required int targetKcal,
    required double totalProteinToday,
    required int proteinTargetG,
    required int numChildrenNursing,
    required int milkSharePercent,
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required double activityFactor,
    required bool isPregnant,
    required int? trimester,
    required int dailyMilkVolumeMl,
  }) async {
    final hour = DateTime.now().hour;
    final remaining = targetKcal - totalKcalToday;
    final warningLine = safetyWarnings.isEmpty
        ? ''
        : '\nSafety-Hinweise zur Mahlzeit: ${safetyWarnings.join("; ")}.';

    final phaseLine = isPregnant
        ? 'Phase: schwanger, ${trimester ?? 1}. Trimester'
        : numChildrenNursing > 0
            ? 'Phase: Stillzeit, $numChildrenNursing Kind(er), Milchvolumen ca. $dailyMilkVolumeMl ml/Tag, Anteil $milkSharePercent%'
            : 'Phase: nicht schwanger, nicht milchproduzierend';

    final userMessage = '''
=== Profil der Nutzerin ===
Alter: $ageYears Jahre · Größe: ${heightCm.toStringAsFixed(0)} cm · Gewicht: ${weightKg.toStringAsFixed(1)} kg
Aktivitätsfaktor (PAL): $activityFactor
$phaseLine
${describeProfile(numChildrenNursing, milkSharePercent)}

=== Tageskontext ===
Aktuelle Uhrzeit: $hour Uhr.
Tagesziel: $targetKcal kcal. Protein-Ziel: ca. $proteinTargetG g.
Tagesstand inkl. dieser Mahlzeit: $totalKcalToday / $targetKcal kcal (verbleibend $remaining kcal).
Protein heute: ${totalProteinToday.toStringAsFixed(0)} g.

=== Gerade eingetragen ===
${mealRawText.isNotEmpty ? 'Originaltext: $mealRawText\n' : ''}Beschreibung: $mealSummary
Gesamtwerte dieser Mahlzeit: $mealKcal kcal, Protein ${mealProteinG.toStringAsFixed(0)} g, KH ${mealCarbsG.toStringAsFixed(0)} g, Fett ${mealFatG.toStringAsFixed(0)} g.$warningLine

Gib die strukturierte Coach-Antwort wie im System-Prompt definiert. Nutze die Profildaten oben.
''';

    return _post(
      systemPrompt: _perMealPrompt,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      maxTokens: 800,
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
