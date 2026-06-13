import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/meal_entry.dart';
import 'prompts/chat_base_de.dart';
import 'prompts/chat_base_en.dart';
import 'prompts/parse_de.dart';
import 'prompts/parse_en.dart';
import 'prompts/per_meal_de.dart';
import 'prompts/per_meal_en.dart';
import 'prompts/supplement_de.dart';
import 'prompts/supplement_en.dart';
import 'safety_rules.dart';

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
  // Per-meal micronutrient estimates from the parser, keyed by
  // MicronutrientKey (e.g. folate_ug, iron_mg). Null when the prompt's
  // micronutrient block wasn't returned (e.g. legacy parser or photo
  // path where the model judged everything negligible). Absent keys on
  // a non-null map mean the parser skipped negligible values (<5 %
  // of daily target).
  final Map<String, double>? micronutrients;

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
    this.micronutrients,
  });

  // Neutral non-meal result. Used as a graceful fallback when the model's
  // reply can't be parsed into nutrition JSON: the input was never a
  // loggable meal, so the caller routes it to the coach chat instead.
  const MealParseResult.nonMeal()
      : isMeal = false,
        rejectionReason = null,
        summary = '',
        kcal = 0,
        proteinG = 0,
        carbsG = 0,
        fatG = 0,
        portionAmount = 0,
        portionUnit = 'g',
        portionAlias = null,
        safetyWarnings = const [],
        micronutrients = null;

  // Pure transformation of a raw model reply into a MealParseResult. Extracted
  // from ClaudeClient.parseMeal so the brittle bits - JSON extraction from a
  // possibly-prose reply, decode failure handling, and field defaulting - are
  // unit-testable without a network round-trip. parseMeal builds the prompt,
  // calls _post(), then delegates the reply parsing here.
  factory MealParseResult.fromModelText(String text) {
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      // No JSON at all means the model answered in prose, which only happens
      // for inputs that aren't a loggable meal (typically a question). Fall
      // back to a non-meal result so the send routes to the coach chat
      // instead of dying with a generic "Couldn't send".
      debugPrint('parseMeal: no JSON in reply, treating as non-meal. Raw: $text');
      return const MealParseResult.nonMeal();
    }
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(text.substring(jsonStart, jsonEnd + 1))
          as Map<String, dynamic>;
    } catch (e) {
      debugPrint('parseMeal: JSON decode failed ($e), treating as non-meal. Raw: $text');
      return const MealParseResult.nonMeal();
    }
    // Temporary diagnostic while we verify the micronutrient pipeline.
    // Logs the RAW pre-mapped value so a malformed entry (e.g. Claude
    // returned a string instead of a number, or the key shape changed)
    // is visible before the cast-and-map step would swallow it.
    debugPrint('parseMeal micronutrients: ${parsed['micronutrients']}');

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
      micronutrients: _parseMicronutrients(parsed['micronutrients']),
    );
  }

  // Tolerant parse of the parser's micronutrient block. The model is asked
  // for numbers, but occasionally returns a stringified number ("120") or
  // outright garbage for a key. A hard `(v as num)` cast there throws an
  // uncaught CastError that kills the WHOLE meal save (the user's core
  // action) over a single bad nutrient. Instead: coerce numeric strings,
  // and silently skip any value we can't read as a number, so one malformed
  // entry never blocks logging the meal. Returns null only when the block is
  // absent or not a map (preserving the "absent == 0" aggregation contract).
  static Map<String, double>? _parseMicronutrients(Object? raw) {
    if (raw is! Map) return null;
    final out = <String, double>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      final n = value is num
          ? value.toDouble()
          : value is String
              ? double.tryParse(value.trim())
              : null;
      if (n != null) out[key] = n;
    });
    return out;
  }

  /// Returns a copy with [safetyWarnings] replaced. Used to fold the
  /// deterministic safety-rule warnings into a parsed meal.
  MealParseResult copyWith({List<String>? safetyWarnings}) => MealParseResult(
        isMeal: isMeal,
        rejectionReason: rejectionReason,
        summary: summary,
        kcal: kcal,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        portionAmount: portionAmount,
        portionUnit: portionUnit,
        portionAlias: portionAlias,
        safetyWarnings: safetyWarnings ?? this.safetyWarnings,
        micronutrients: micronutrients,
      );
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
    String callType = 'unknown',
    // Set true for callers whose system prompt is large + identical across
    // users (parse, per-meal coach, chat). The Anthropic API caches the
    // marked block for ~5 min and bills cached input at ~10% of normal.
    // Safety/supplement skip caching - their prompts are short or per-call
    // dynamic.
    bool cacheSystem = false,
  }) async {
    final url = _usingProxy
        ? Uri.parse('$_proxyUrl/messages')
        : Uri.parse(_directEndpoint);
    final headers = <String, String>{
      'content-type': 'application/json',
    };
    if (_usingProxy) {
      headers['x-app-secret'] = _appSecret;
      // Labels the call so the Worker can break COGS down by type (parse vs
      // coach vs photo vs chat). Not forwarded to Anthropic.
      headers['x-call-type'] = callType;
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
              // String-form for un-cached calls (Anthropic happy path).
              // List-form with cache_control marks the system block as
              // ephemerally cacheable so identical prefixes across users
              // and across calls land on the warm cache.
              'system': cacheSystem
                  ? [
                      {
                        'type': 'text',
                        'text': systemPrompt,
                        'cache_control': {'type': 'ephemeral'},
                      }
                    ]
                  : systemPrompt,
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
    final raw = utf8.decode(response.bodyBytes);
    try {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final content = body['content'] as List;
      return (content.first as Map)['text'] as String;
    } catch (e) {
      // 200 OK but the body isn't the Anthropic {content:[{text}]} shape we
      // expect, e.g. a proxy/edge error page served with a 200. Surface a
      // real CoachApiException (visible message + raw body for logs) instead
      // of letting a CastError bubble up as a generic "Couldn't send".
      throw CoachApiException(
        'Something went wrong. Try again.',
        'unexpected 200 body: ${raw.substring(0, raw.length.clamp(0, 300))}',
      );
    }
  }

  Future<MealParseResult> parseMeal(
    String userText, {
    Uint8List? imageBytes,
    String locale = 'en',
    bool isPregnant = false,
    int? trimester,
    bool isLactating = false,
    // Recent entries from the user's history whose summary matches the
    // typed text. Lets the parser anchor on the user's actual past
    // brand+portion values rather than re-estimating from scratch.
    // Typically the top 3 matches from mealHistorySuggestionsProvider.
    List<MealEntry> brandHistoryHints = const [],
  }) async {
    final isDe = _isGerman(locale);
    // Phase context so safety_warnings stay relevant: a not-pregnant user
    // shouldn't get pregnancy-specific warnings (e.g. on an alcohol photo).
    final phaseDe = isPregnant
        ? 'schwanger (${trimester ?? 1}. Trimester)'
        : isLactating
            ? 'produziert Muttermilch (stillt oder pumpt)'
            : 'nicht schwanger und produziert keine Muttermilch';
    final phaseEn = isPregnant
        ? 'pregnant (trimester ${trimester ?? 1})'
        : isLactating
            ? 'producing breast milk (nursing or pumping)'
            : 'not pregnant and not producing breast milk';
    final phaseLine = isDe
        ? 'Phase der Nutzerin: $phaseDe. Gib NUR safety_warnings, die zu DIESER Phase passen, keine für andere Phasen.'
        : 'User phase: $phaseEn. Give ONLY safety_warnings relevant to THIS phase, none for other phases.';

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
    final entryText = userText.isEmpty
        ? (isDe
            ? 'Schätze diesen Eintrag basierend auf dem Bild.'
            : 'Estimate this entry based on the image.')
        : userText;
    final historyBlock = _brandHistoryBlock(brandHistoryHints, isDe: isDe);
    content.add({
      'type': 'text',
      'text': '$phaseLine$historyBlock\n\n$entryText',
    });

    final text = await _post(
      systemPrompt: isDe ? parsePromptDe : parsePromptEn,
      messages: [
        {'role': 'user', 'content': content},
      ],
      callType: imageBytes != null ? 'photo' : 'parse',
      cacheSystem: true,
    );

    final result = MealParseResult.fromModelText(text);
    // A non-meal (no parseable nutrition) routes to the coach chat; running
    // food-safety rules on it would mis-fire (e.g. on the question "darf ich
    // Kaffee trinken?"), so only apply the deterministic floor to real meals.
    if (!result.isMeal) return result;
    final deterministic = SafetyRules.allWarnings(
      '$userText ${result.summary}',
      SafetyPhase(
        isPregnant: isPregnant,
        trimester: trimester,
        isLactating: isLactating,
      ),
      locale: locale,
    );
    if (deterministic.isEmpty) return result;
    return result.copyWith(
      safetyWarnings:
          SafetyRules.mergeWarnings(deterministic, result.safetyWarnings),
    );
  }

  // Safety-only check for a known product (e.g. one scanned via Open Food
  // Facts, which has no safety data). Returns phase-relevant warnings
  // (caffeine, alcohol, mercury fish, raw dairy/meat, etc.) or an empty list
  // on "nothing critical" or any failure, so the scan flow degrades quietly.
  Future<List<String>> safetyCheck({
    required String productName,
    required bool isPregnant,
    int? trimester,
    required bool isLactating,
    String locale = 'en',
  }) async {
    final isDe = _isGerman(locale);
    final phaseDe = isPregnant
        ? 'schwanger, ${trimester ?? 1}. Trimester'
        : isLactating
            ? 'produziert Muttermilch'
            : 'weder schwanger noch milchproduzierend';
    final phaseEn = isPregnant
        ? 'pregnant, trimester ${trimester ?? 1}'
        : isLactating
            ? 'producing breast milk'
            : 'neither pregnant nor producing milk';
    final system = isDe
        ? '''Du bist ein Food-Safety-Prüfer. Die Nutzerin ist: $phaseDe.
Die Standard-Risiken (Koffein, Alkohol, Quecksilber-Großraubfisch, rohe Milch/rohes Fleisch/roher Fisch, Leber im 1. Trimester, milchhemmende Kräuter) werden bereits separat automatisch geprüft. Nenne daher NUR zusätzliche, darüber hinausgehende Risiken und wiederhole diese Standard-Risiken NICHT.
Antworte AUSSCHLIESSLICH mit einem JSON-Array kurzer deutscher Warn-Strings, z.B. ["Koffein: ca. 80 mg pro Dose, achte auf die Tagesgrenze von 200 mg"]. Wenn nichts kritisch ist, antworte mit []. Vermeide das Wort "Stillen", nutze "während du Muttermilch produzierst".'''
        : '''You are a food-safety checker. The user is: $phaseEn.
The standard risks (caffeine, alcohol, high-mercury predatory fish, raw milk / raw meat / raw fish, liver in the first trimester, lactation-suppressing herbs) are already checked separately and automatically. So name ONLY additional risks beyond those, and do NOT repeat the standard ones.
Reply ONLY with a JSON array of short English warning strings, e.g. ["Caffeine: ~80 mg per can, mind the 200 mg daily limit"]. If nothing is critical, reply with []. Avoid the word "breastfeeding"; use "while you're producing breast milk".''';
    // Deterministic floor: the known, finite risks (see safety_rules.dart) are
    // computed locally and ALWAYS returned, even if the model call below fails
    // or misses something. The model only adds extra, fuzzier warnings on top.
    final phase = SafetyPhase(
      isPregnant: isPregnant,
      trimester: trimester,
      isLactating: isLactating,
    );
    final deterministic =
        SafetyRules.allWarnings(productName, phase, locale: locale);
    try {
      final raw = (await _post(
        systemPrompt: system,
        messages: [
          {'role': 'user', 'content': productName},
        ],
        maxTokens: 200,
        callType: 'safety',
      ))
          .trim();
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start == -1 || end == -1) return deterministic;
      final list = jsonDecode(raw.substring(start, end + 1)) as List;
      final modelWarnings = list
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return SafetyRules.mergeWarnings(deterministic, modelWarnings);
    } catch (e) {
      debugPrint('safetyCheck failed for "$productName": $e');
      // Model failed, but the deterministic rules still stand.
      return deterministic;
    }
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
    String dietStyle = 'omnivore',
    Set<String> restrictions = const {},
    String dietaryNotes = '',
    String locale = 'en',
    DateTime? loggedAt,
    bool requestFollowUps = false,
    String? weightTrend,
    String? microNudge,
    // "What do you want to use up today?" feature. ingredients carries the
    // user's stated list (free text) if any; askForIngredients flips on
    // when we haven't asked today yet and have no stored list.
    String? ingredients,
    bool askForIngredients = false,
    // Goal-driven body-composition guardrail block. Caller assembles the
    // full multi-line string (with the validated 1800/300-500/6-8w/etc
    // numbers) so this method stays a pure passthrough.
    String? goalGuardrails,
  }) async {
    final isDe = _isGerman(locale);
    // The coach reasons about meal timing ("breakfast", "next meal") from
    // this hour. Use the meal's logged-at timestamp when available (e.g.
    // the user logs breakfast in the evening with a custom time), and fall
    // back to wall-clock now for the standard same-moment case.
    final hour = (loggedAt ?? DateTime.now()).hour;
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
            dietLine: _dietLine(
                isDe: true,
                dietStyle: dietStyle,
                restrictions: restrictions,
                dietaryNotes: dietaryNotes,
                isPregnant: isPregnant,
                numChildrenNursing: numChildrenNursing),
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
            dietLine: _dietLine(
                isDe: false,
                dietStyle: dietStyle,
                restrictions: restrictions,
                dietaryNotes: dietaryNotes,
                isPregnant: isPregnant,
                numChildrenNursing: numChildrenNursing),
          );

    // Every Nth meal the coach gets primed to surface engagement-questions
    // the user can tap, which then prefill the meal-input field. Threading
    // this through the user-message (not the system prompt) keeps the
    // baseline format identical for the common case.
    final followUpInstructionDe =
        '\nFüge AM ENDE der Antwort eine Sektion **Fragen:** an mit 2-3 kurzen Bullets (je max 8 Wörter), die als ANTWORT-Vorlagen für die Nutzerin formuliert sind. Beispiele: "Ich esse selten Fisch", "Ich brauche Vorschläge für unterwegs", "Mir fehlt heute Energie". Format: `- <Bullet>`. Keine Fragezeichen.';
    final followUpInstructionEn =
        '\nAppend a section **Follow-ups:** AT THE END with 2-3 short bullets (max 8 words each), phrased as REPLY templates from the user. Examples: "I rarely eat fish", "I need on-the-go ideas", "I feel low energy today". Format: `- <bullet>`. No question marks.';

    var finalUserMessage = userMessage;
    // Only passed (by the caller) when the trend is notably fast, so the coach
    // doesn't bring up weight on every ordinary meal.
    if (weightTrend != null && weightTrend.isNotEmpty) {
      finalUserMessage += '\n\n$weightTrend';
    }
    if (microNudge != null && microNudge.isNotEmpty) {
      finalUserMessage += '\n\n$microNudge';
    }
    if (ingredients != null && ingredients.isNotEmpty) {
      finalUserMessage += isDe
          ? '\n\nVorhandene Zutaten: $ingredients. Beim NÄCHSTEN Vorschlag priorisieren. Nährstoffziele und Bewertung des aktuellen Gerichts haben Vorrang. Passt eine Zutat nicht sinnvoll, weglassen. Kurz erwähnen, welche Zutaten du verwendet hast.'
          : '\n\nAvailable ingredients: $ingredients. Prioritise in the NEXT suggestion. Nutrient goals and the current meal review take precedence; drop an ingredient if it does not fit. Briefly note which ingredients you used.';
    }
    if (askForIngredients) {
      finalUserMessage += isDe
          ? '\n\nFrage die Nutzerin am Ende kurz und beiläufig, ob sie heute etwas Bestimmtes verbrauchen möchte, das du beim nächsten Vorschlag berücksichtigst.'
          : '\n\nAt the end, briefly and casually ask the user whether there is anything in particular she wants to use up today for you to factor into the next suggestion.';
    }
    if (goalGuardrails != null && goalGuardrails.isNotEmpty) {
      finalUserMessage += '\n\n$goalGuardrails';
    }
    if (requestFollowUps) {
      finalUserMessage += isDe ? followUpInstructionDe : followUpInstructionEn;
    }

    return _post(
      systemPrompt: isDe ? perMealPromptDe : perMealPromptEn,
      messages: [
        {'role': 'user', 'content': finalUserMessage},
      ],
      // 70-word answer + optional follow-up bullets fit well under this; the
      // cap just bounds the worst case (output tokens are the dominant cost).
      maxTokens: 600,
      callType: 'coach',
      cacheSystem: true,
    );
  }

  // Single-line summary of diet style + avoid-list + free-text notes, ready
  // to drop into the user-message profile block. Returns an empty string
  // when nothing is set so omnivores without restrictions don't get a
  // confusing "Diet: omnivore" line in their context.
  // Format a compact "earlier similar entries" block listing the user's
  // own prior matching meals. The parser is instructed in the prompt
  // (parse_de / parse_en) to prefer these values when the current text
  // closely matches a hint, instead of re-estimating from scratch. Keeps
  // brand-accurate macros for repeat logs of the same item (Skyr,
  // specific cereal, recurring takeaway).
  //
  // Returns empty string when no hints - keeps the prompt clean for the
  // common case.
  static String _brandHistoryBlock(List<MealEntry> hints,
      {required bool isDe}) {
    if (hints.isEmpty) return '';
    final lines = <String>[];
    for (final m in hints.take(3)) {
      final portion = m.portionAmount > 0
          ? '${m.portionAmount.toStringAsFixed(0)} ${m.portionUnit}'
          : '';
      final macros =
          'kcal ${m.kcal}, P ${m.proteinG.toStringAsFixed(0)}, KH ${m.carbsG.toStringAsFixed(0)}, F ${m.fatG.toStringAsFixed(0)}';
      lines.add(portion.isEmpty
          ? '- ${m.summary}: $macros'
          : '- ${m.summary} ($portion): $macros');
    }
    final header = isDe
        ? '\n\nFrühere ähnliche Einträge dieser Nutzerin (Marke/Portion kennt sie schon):'
        : '\n\nEarlier similar entries from this user (brand/portion she already tracks):';
    final footer = isDe
        ? '\nWenn der aktuelle Eintrag zu einem davon eindeutig passt, übernimm dessen Werte direkt - nicht neu schätzen.'
        : '\nIf the current entry clearly matches one of these, use its values directly - do not re-estimate.';
    return '$header\n${lines.join("\n")}$footer';
  }

  static String _dietLine({
    required bool isDe,
    required String dietStyle,
    required Set<String> restrictions,
    required String dietaryNotes,
    bool isPregnant = false,
    int numChildrenNursing = 0,
  }) {
    final hasStyle = dietStyle.isNotEmpty && dietStyle != 'omnivore';
    final hasRestrictions = restrictions.isNotEmpty;
    final hasNotes = dietaryNotes.trim().isNotEmpty;
    if (!hasStyle && !hasRestrictions && !hasNotes) return '';
    final parts = <String>[];
    if (isDe) {
      if (hasStyle) parts.add('Ernährung: $dietStyle');
      if (hasRestrictions) parts.add('Vermeidet: ${restrictions.join(", ")}');
      if (hasNotes) parts.add('Hinweis: ${dietaryNotes.trim()}');
    } else {
      if (hasStyle) parts.add('Diet: $dietStyle');
      if (hasRestrictions) parts.add('Avoids: ${restrictions.join(", ")}');
      if (hasNotes) parts.add('Note: ${dietaryNotes.trim()}');
    }
    final base = isDe
        ? '\nErnährungsprofil: ${parts.join(" · ")}'
        : '\nDietary profile: ${parts.join(" · ")}';
    // Vegan + Schwangerschaft / Stillzeit: kritische Nährstoffe gelten als
    // Risiko, wenn nicht aktiv supplementiert wird. Der Coach bekommt
    // hier eine konkrete Liste der Hochrisiko-Lücken, damit er nicht nur
    // den Tageskorridor kommentiert sondern proaktiv auf B12 / DHA /
    // Iod / Eisen achtet - das war der Punkt der Ernährungsfachkraft-
    // Review (Vegan-Alarm). Greift nur in der Stillzeit oder
    // Schwangerschaft - außerhalb dieser Phasen ist die Plant-Based
    // Empfehlung weniger kritisch.
    final isPhase = isPregnant || numChildrenNursing > 0;
    if (dietStyle == 'vegan' && isPhase) {
      final guardrail = isDe
          ? '\nVegan in dieser Phase: Achte besonders auf Vitamin B12 '
              '(tägliche Supplementierung essenziell, ohne reicht keine '
              'Mahlzeit), DHA (Algenöl 200-300 mg/Tag empfohlen), Iod '
              '(150-200 µg/Tag), Eisen (Vit-C zur Resorption), Cholin '
              '(Sojaprodukte, Erdnüsse), Calcium (angereicherte Drinks), '
              'Zink und Vitamin D. Nenne diese aktiv, wenn die Mahlzeit '
              'eine Lücke offen lässt. Quelle: DGE, AND, EFSA.'
          : '\nVegan during this phase: be especially attentive to '
              'vitamin B12 (daily supplementation is essential, no meal '
              'covers this), DHA (200-300 mg/day algae oil recommended), '
              'iodine (150-200 µg/day), iron (pair with vitamin C for '
              'absorption), choline (soy products, peanuts), calcium '
              '(fortified plant milks), zinc and vitamin D. Surface '
              'these proactively when a meal leaves the gap open. '
              'Source: DGE, AND, EFSA.';
      return base + guardrail;
    }
    return base;
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
    String dietLine = '',
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
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'de')}$dietLine

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
    String dietLine = '',
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
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'en')}$dietLine

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
    final base = isDe ? chatPromptBaseDe : chatPromptBaseEn;
    final contextHeader = isDe ? 'Kontext heute:' : 'Context today:';
    return _post(
      systemPrompt: '$base\n\n$contextHeader\n$todayContext',
      messages: messages,
      maxTokens: 600,
      callType: 'chat',
    );
  }

  // Vision-based parse of a supplement label photo. The user takes a
  // single shot of the "Nährwerttabelle / Nutrition facts" panel on the
  // back of their prenatal supplement; Claude extracts the per-day
  // values keyed by MicronutrientKey so they can be added to the daily
  // aggregation.
  //
  // The model is told to compute "per day" by multiplying per-capsule
  // values by dosesPerDay if that's spelled out on the label. If
  // dosesPerDay is ambiguous from the label, the model defaults to 1
  // and we surface a stepper so the user can correct in the result
  // sheet.
  //
  // Throws CoachApiException on network/auth/parse failure so the
  // caller can show a "couldn't read the label, try again" hint and
  // fall back to manual entry.
  Future<SupplementParseResult> parseSupplementLabel(
    Uint8List imageBytes, {
    String locale = 'en',
  }) async {
    final isDe = _isGerman(locale);
    final systemPrompt = isDe ? supplementPromptDe : supplementPromptEn;
    final userText = isDe
        ? 'Extrahiere die Nährwerte aus dem Foto und gib das JSON zurück.'
        : 'Extract the nutrient values from the photo and return JSON.';
    final text = await _post(
      systemPrompt: systemPrompt,
      messages: [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
            {'type': 'text', 'text': userText},
          ],
        },
      ],
      maxTokens: 400,
      callType: 'supplement_parse',
    );
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw CoachApiException(
        isDe
            ? 'Das Etikett ließ sich nicht auslesen. Probier ein klareres Foto oder trag die Werte manuell ein.'
            : "Couldn't read the label. Try a clearer photo or enter the values manually.",
        'no JSON in reply: ${text.substring(0, text.length.clamp(0, 200))}',
      );
    }
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(text.substring(jsonStart, jsonEnd + 1))
          as Map<String, dynamic>;
    } catch (e) {
      throw CoachApiException(
        isDe
            ? 'Etikett-Daten waren unleserlich. Probier ein neues Foto.'
            : "Label data was unreadable. Try another photo.",
        'JSON decode failed: $e',
      );
    }
    final dosesPerDay = (parsed['doses_per_day'] as num?)?.toInt() ?? 1;
    final perDose = (parsed['values'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ) ??
        const <String, double>{};
    // Bake dosesPerDay into the stored values so the daily-aggregation
    // provider can just add them once without needing the dose count.
    final perDay = <String, double>{
      for (final entry in perDose.entries)
        entry.key: entry.value * dosesPerDay,
    };
    return SupplementParseResult(
      name: (parsed['name'] as String?)?.trim() ?? '',
      values: perDay,
      dosesPerDay: dosesPerDay,
    );
  }

}

// Result from Claude Vision parsing a supplement label photo. The
// caller (Settings supplement-setup flow) shows this in a result sheet
// so the user can verify / edit before saving as ActiveSupplement.
//
// Note: [values] are already multiplied by [dosesPerDay] (the parser
// hands back per-dose values and the API method bakes the multiplication
// in). That's so the stored ActiveSupplement.values represent the user's
// actual daily intake and the daily-aggregation provider can add them
// without re-doing the math.
class SupplementParseResult {
  final String name;
  final Map<String, double> values; // per-day, already × dosesPerDay
  final int dosesPerDay; // metadata only for display

  const SupplementParseResult({
    required this.name,
    required this.values,
    required this.dosesPerDay,
  });
}
