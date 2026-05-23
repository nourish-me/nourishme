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

  // Picks the system prompt and user-message template language. We key on the
  // BCP-47 primary language tag from the app's active locale: "de" → German,
  // anything else → English (treating English as the default for the
  // international audience).
  static bool _isGerman(String locale) =>
      locale.toLowerCase().startsWith('de');

  static final _parsePromptDe = '''
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

  static final _parsePromptEn = '''
You are a nutrition assistant for a woman who is producing breast milk (whether nursing directly or exclusively pumping) or pregnant.
Parse the described entry into structured nutrition data and check for food-safety risks.

Avoid the word "breastfeeding" and variations of it in your safety_warnings, because many mothers exclusively pump and don't feel addressed by it. Use neutral phrasing like "while you produce breast milk", "in this phase", "alcohol passes into breast milk", "caffeine reaches the baby".

Accept all kinds of food and drink intake: full meals, snacks, sweets, and drinks like coffee, tea, juice, smoothie, milk, soda, alcohol or water (water may be 0 kcal).

${NutritionFacts.coachContextBlockEn}

Apply these thresholds for safety_warnings. For every entry, concretely check:
- Estimate the caffeine content. Warn when the daily 200 mg threshold could be exceeded.
- Alcohol: warn for any amount during pregnancy. While producing milk, mention the waiting time (~2-2.5 h per standard drink).
- Fish: warn for high-mercury predator fish, suggest a safer alternative.
- Raw milk / raw meat / sushi: in pregnancy, flag the listeria risk.
- Liver: warn in T1 pregnancy (vitamin A teratogenic, UL 3,000 µg).
- Sage tea / peppermint oil: in larger amounts, mention the galactofuge effect.

If amounts aren't given, estimate conservatively based on a typical portion or cup.

If a photo is attached, also analyse the image. Use visible reference objects (cutlery, hand, known packaging, plate, cup) to estimate the portion. If both text and image are provided and the text names a concrete amount, trust the text for the amount and use the image to identify the food.

If the input doesn't describe food intake (e.g. random characters, empty words, non-edible things, a question), set "is_meal" to false and return a short English hint in "rejection_reason", e.g. "Please describe a food or drink." In that case kcal and macros may be 0 and safety_warnings empty.

For each entry also estimate the portion size as a single number with unit ("g" for solid/semi-solid foods, "ml" for drinks). For mixed meals give the total amount.

Respond EXCLUSIVELY with JSON in this schema, no Markdown code fence, no text before or after:
{
  "is_meal": bool,
  "rejection_reason": string or null,
  "summary": string,
  "kcal": int,
  "protein_g": number,
  "carbs_g": number,
  "fat_g": number,
  "portion_amount": number,
  "portion_unit": string ("g" or "ml"),
  "portion_alias": string or null,
  "safety_warnings": [string]
}

"summary" is a short English description, max 80 characters.
"portion_amount" and "portion_unit" together must be plausible for the summary. With is_meal=false they may be 0 and "g".
"portion_alias" is a handy reference size in English, max 25 characters, that helps the user gauge the amount without a scale. Examples: "a handful", "2 tbsp", "a small mug", "1 palm size", "1 heaped tsp", "1 medium bowl". When no useful reference exists (e.g. water, sparkling water): null.
"safety_warnings" only contains health-relevant notes for the phase, never input problems. Empty when nothing is critical.
''';

  static final _perMealPromptDe = '''
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

  static final _perMealPromptEn = '''
You are a nutrition coach for a woman who is producing breast milk (nursing directly or exclusively pumping) or pregnant.
Reply in English, factual, no small talk, no salutation. Be evidence-based: cite concrete numbers from DGE/EFSA/BfR when relevant.

${NutritionFacts.coachContextBlockEn}

Answer strictly in the following Markdown format. No tables, they don't fit on phone screens. No additional sentences before or after.

**Components:** (ONLY when the meal consists of multiple parts. Skip the whole block when there's only one component.)
- <component>, <amount> — <kcal> kcal · P <g> · C <g> · F <g>
- ... further components in the same form

**🟢 Strong:** one or two strengths in one sentence
**🟡 Light:** one or two weaknesses, if relevant

**What's still missing today:** brief, with a kcal split across the next meals
**Next meal:** recommendation with timing and a concrete food suggestion

Rules:
- Estimate components from the raw text or description, amounts in g, ml or pieces
- Each component on its own line, compact with · as separator
- NO total line, kcal are already on the meal card and macros are counted in the toolbar
- Do NOT repeat the daily kcal or protein total, it's visible in the toolbar above
- Mention micronutrients (iron, calcium, folate, omega-3) only when they fit the meal or time of day
- Maximum 120 words
- Avoid the word "breastfeeding" and its variations. Use "while you're producing breast milk" or "in this phase", since many mothers exclusively pump
- User data (weight, activity, number of children, milk volume, etc.) is provided in the profile. Use it IMMEDIATELY and NEVER ask for it.
''';

  static final _chatPromptBaseDe = '''
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

  static final _chatPromptBaseEn = '''
You are a science-based nutrition coach for a woman who is producing breast milk (nursing directly or exclusively pumping) or pregnant.
Reply in English, precise and empathetic. Keep it short, max 4-5 sentences per reply, unless a list or bullet form makes sense.
Cite concrete numbers and sources (DGE, BfR, EFSA, LactMed, FDA/EPA) where relevant rather than vague statements.
If the question is open-ended (e.g. for meal ideas), give 2-3 concrete suggestions.

CRITICAL: User data (weight, height, age, activity, phase, number of children, age of children, milk volume, trimester) and today's totals (kcal, protein, etc.) are provided in the profile and daily context. Use them IMMEDIATELY in your replies.
- NEVER ask for data that's already in the profile or daily context.
- If someone asks about protein needs, calculate directly using the provided weight and state the concrete number.
- If someone asks about water intake, calculate using the provided milk volume.
- Phrases like "if you tell me your weight" are forbidden, the weight is already there.

Avoid the word "breastfeeding" and variations (breastfeeding mother, while breastfeeding). Use instead "while you produce breast milk", "mothers who pump or nurse", "in this phase", since many mothers exclusively pump.

${NutritionFacts.coachContextBlockEn}
''';

  static String describeProfile(int numChildren, int sharePercent,
      {String locale = 'en'}) {
    if (_isGerman(locale)) {
      if (numChildren <= 0) {
        return 'Profil: aktuell keine Milchabgabe (z.B. Schwangerschaft oder bereits abgestillt).';
      }
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
    if (numChildren <= 0) {
      return 'Profile: no current milk supply (e.g. pregnancy or already weaned).';
    }
    final share = sharePercent == 100
        ? 'exclusively (100%)'
        : sharePercent >= 75
            ? 'mostly ($sharePercent%)'
            : sharePercent >= 50
                ? 'about half ($sharePercent%)'
                : sharePercent >= 25
                    ? 'partly ($sharePercent%)'
                    : 'a little ($sharePercent%)';
    final kids = numChildren == 1 ? 'one child' : '$numChildren children';
    return 'Profile: feeds $kids with own milk, $share each.';
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
          'App is not configured. Please tell the developer.',
          '.env has neither NOURISHME_API_URL+APP_SECRET nor ANTHROPIC_API_KEY',
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
        'The coach is taking too long. Try again in a moment.',
        'timeout after 30s',
      );
    } on SocketException catch (e) {
      throw CoachApiException(
        'No internet connection. Try again in a moment.',
        e.message,
      );
    } on http.ClientException catch (e) {
      throw CoachApiException(
        'Connection problem. Try again in a moment.',
        e.message,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CoachApiException(
        'Auth problem. Please tell the developer.',
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }
    if (response.statusCode == 429) {
      throw CoachApiException(
        'Coach is overloaded right now. Try again in a minute.',
        'HTTP 429',
      );
    }
    if (response.statusCode >= 500) {
      throw CoachApiException(
        'Coach is unavailable right now. Try again soon.',
        'HTTP ${response.statusCode}',
      );
    }
    if (response.statusCode != 200) {
      throw CoachApiException(
        'Something went wrong. Try again.',
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
    String locale = 'en',
  }) async {
    final isDe = _isGerman(locale);
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
          ? (isDe
              ? 'Schätze diesen Eintrag basierend auf dem Bild.'
              : 'Estimate this entry based on the image.')
          : userText,
    });

    final text = await _post(
      systemPrompt: isDe ? _parsePromptDe : _parsePromptEn,
      messages: [
        {'role': 'user', 'content': content},
      ],
    );

    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw Exception('Claude returned no JSON: $text');
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
    String locale = 'en',
  }) async {
    final isDe = _isGerman(locale);
    final hour = DateTime.now().hour;
    final remaining = targetKcal - totalKcalToday;
    final userMessage = isDe
        ? _buildPerMealUserMessageDe(
            mealRawText: mealRawText,
            mealSummary: mealSummary,
            mealKcal: mealKcal,
            mealProteinG: mealProteinG,
            mealCarbsG: mealCarbsG,
            mealFatG: mealFatG,
            safetyWarnings: safetyWarnings,
            totalKcalToday: totalKcalToday,
            targetKcal: targetKcal,
            totalProteinToday: totalProteinToday,
            proteinTargetG: proteinTargetG,
            numChildrenNursing: numChildrenNursing,
            milkSharePercent: milkSharePercent,
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            activityFactor: activityFactor,
            isPregnant: isPregnant,
            trimester: trimester,
            dailyMilkVolumeMl: dailyMilkVolumeMl,
            hour: hour,
            remaining: remaining,
          )
        : _buildPerMealUserMessageEn(
            mealRawText: mealRawText,
            mealSummary: mealSummary,
            mealKcal: mealKcal,
            mealProteinG: mealProteinG,
            mealCarbsG: mealCarbsG,
            mealFatG: mealFatG,
            safetyWarnings: safetyWarnings,
            totalKcalToday: totalKcalToday,
            targetKcal: targetKcal,
            totalProteinToday: totalProteinToday,
            proteinTargetG: proteinTargetG,
            numChildrenNursing: numChildrenNursing,
            milkSharePercent: milkSharePercent,
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            activityFactor: activityFactor,
            isPregnant: isPregnant,
            trimester: trimester,
            dailyMilkVolumeMl: dailyMilkVolumeMl,
            hour: hour,
            remaining: remaining,
          );

    return _post(
      systemPrompt: isDe ? _perMealPromptDe : _perMealPromptEn,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      maxTokens: 800,
    );
  }

  String _buildPerMealUserMessageDe({
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
    required int hour,
    required int remaining,
  }) {
    final warningLine = safetyWarnings.isEmpty
        ? ''
        : '\nSafety-Hinweise zur Mahlzeit: ${safetyWarnings.join("; ")}.';
    final phaseLine = isPregnant
        ? 'Phase: schwanger, ${trimester ?? 1}. Trimester'
        : numChildrenNursing > 0
            ? 'Phase: Stillzeit, $numChildrenNursing Kind(er), Milchvolumen ca. $dailyMilkVolumeMl ml/Tag, Anteil $milkSharePercent%'
            : 'Phase: nicht schwanger, nicht milchproduzierend';
    return '''
=== Profil der Nutzerin ===
Alter: $ageYears Jahre · Größe: ${heightCm.toStringAsFixed(0)} cm · Gewicht: ${weightKg.toStringAsFixed(1)} kg
Aktivitätsfaktor (PAL): $activityFactor
$phaseLine
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'de')}

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
  }

  String _buildPerMealUserMessageEn({
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
    required int hour,
    required int remaining,
  }) {
    final warningLine = safetyWarnings.isEmpty
        ? ''
        : '\nSafety notes for the meal: ${safetyWarnings.join("; ")}.';
    final phaseLine = isPregnant
        ? 'Phase: pregnant, trimester ${trimester ?? 1}'
        : numChildrenNursing > 0
            ? 'Phase: producing milk, $numChildrenNursing child(ren), milk volume ~$dailyMilkVolumeMl ml/day, share $milkSharePercent%'
            : 'Phase: not pregnant, not producing milk';
    return '''
=== User profile ===
Age: $ageYears years · Height: ${heightCm.toStringAsFixed(0)} cm · Weight: ${weightKg.toStringAsFixed(1)} kg
Activity factor (PAL): $activityFactor
$phaseLine
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'en')}

=== Daily context ===
Current time: $hour:00.
Daily target: $targetKcal kcal. Protein target: ~$proteinTargetG g.
Today incl. this meal: $totalKcalToday / $targetKcal kcal (remaining $remaining kcal).
Protein today: ${totalProteinToday.toStringAsFixed(0)} g.

=== Just logged ===
${mealRawText.isNotEmpty ? 'Original text: $mealRawText\n' : ''}Description: $mealSummary
Totals for this meal: $mealKcal kcal, protein ${mealProteinG.toStringAsFixed(0)} g, carbs ${mealCarbsG.toStringAsFixed(0)} g, fat ${mealFatG.toStringAsFixed(0)} g.$warningLine

Return the structured coach reply as defined in the system prompt. Use the profile data above.
''';
  }

  Future<String> chat({
    required List<ChatTurn> history,
    required String todayContext,
    String locale = 'en',
  }) async {
    final isDe = _isGerman(locale);
    final messages = history
        .map((turn) => {
              'role': turn.isUser ? 'user' : 'assistant',
              'content': turn.text,
            })
        .toList();
    final base = isDe ? _chatPromptBaseDe : _chatPromptBaseEn;
    final contextHeader = isDe ? 'Kontext heute:' : 'Context today:';
    return _post(
      systemPrompt: '$base\n\n$contextHeader\n$todayContext',
      messages: messages,
      maxTokens: 600,
    );
  }
}
