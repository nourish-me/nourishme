import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/coach_response_type.dart';
import '../models/meal_entry.dart';
import 'consent_gate.dart';
import 'prompts/chat_base_de.dart';
import 'prompts/chat_base_en.dart';
import 'prompts/parse_de.dart';
import 'prompts/parse_en.dart';
import 'prompts/per_meal_de.dart';
import 'prompts/per_meal_en.dart';
import 'prompts/supplement_de.dart';
import 'prompts/supplement_en.dart';
import 'safety_rules.dart';

// Reply envelope returned by every Anthropic round-trip (Task #88.5).
// `text` is the content[0].text from the Anthropic response; `type` is the
// Worker's nourishme_response_type tag (normal for live model replies,
// emergency/escalation for safety-synth, blocked for output-post-check
// fallbacks). Callers that don't care about type just unwrap `.text`.
class CoachReply {
  final String text;
  final CoachResponseType type;
  const CoachReply({required this.text, this.type = CoachResponseType.normal});
}

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
  // Coerce an AI-returned nutrient value to a number: numbers pass through,
  // numeric strings ("120", "120 ") parse to 120, anything else is null.
  // Shared by the meal parser AND parseSupplementLabel so a vision/OCR label
  // that hands back stringified numbers isn't silently dropped.
  @visibleForTesting
  static double? coerceNutrientValue(Object? value) => value is num
      ? value.toDouble()
      : value is String
          ? double.tryParse(value.trim())
          : null;

  static Map<String, double>? _parseMicronutrients(Object? raw) {
    if (raw is! Map) return null;
    final out = <String, double>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      final n = coerceNutrientValue(value);
      if (n == null) return;
      final canonical = canonicalNutrientKey(key);
      // Drop macros if the model accidentally packed them into the
      // micronutrients block (Build +34 tester report): protein_g /
      // carbs_g / fat_g / kcal already live on the parent JSON as
      // top-level fields. If they leak into "micronutrients" the B9
      // "also detected" card lists them as unsupported nutrients, which
      // is misleading - they ARE tracked, just in the macro lane.
      if (_macroKeys.contains(canonical)) return;
      // Multiple inputs (e.g. vitamin_d_ug + cholecalciferol_ug from a
      // supplement label) can canonicalize to the same key. Sum them so we
      // don't silently drop one branch.
      out.update(canonical, (prev) => prev + n, ifAbsent: () => n);
    });
    return out;
  }

  static const Set<String> _macroKeys = {
    'protein_g',
    'carbs_g',
    'carbohydrates_g',
    'fat_g',
    'kcal',
    'kcal_total',
    'energy_kcal',
  };

  // Aliases for AI-returned nutrient keys. The prompts ask the model to
  // return canonical keys (e.g. vitamin_d_ug), but supplement labels in
  // the wild list "Vitamin D3", "Cholecalciferol", "D2", etc. and the
  // model often passes those through verbatim. This map folds the common
  // chemical-name variants back onto the canonical key so the daily
  // aggregation actually counts them.
  static const Map<String, String> _nutrientAliases = {
    // Vitamin D variants (cholecalciferol = D3, ergocalciferol = D2)
    'vitamin_d3_ug': 'vitamin_d_ug',
    'vitamin_d2_ug': 'vitamin_d_ug',
    'cholecalciferol_ug': 'vitamin_d_ug',
    'ergocalciferol_ug': 'vitamin_d_ug',
    'd3_ug': 'vitamin_d_ug',
    'd2_ug': 'vitamin_d_ug',
    'vit_d_ug': 'vitamin_d_ug',
  };

  @visibleForTesting
  static String canonicalNutrientKey(String key) {
    final lower = key.trim().toLowerCase();
    return _nutrientAliases[lower] ?? lower;
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
  // Optional consent-resolver. When set, every public API call
  // (parseMeal, chat, parseSupplementLabel) checks ConsentGate.
  // canSendHealthData(resolver()) at its entry; if false, throws
  // CoachApiException with a user-facing message instead of hitting
  // the network. Left null in tests so the existing fixture-only
  // tests don't have to wire up a fake SettingsRepository - the
  // production wiring in claudeClientProvider always provides it.
  ClaudeClient({
    this.healthDataConsentAtResolver,
    this.installIdResolver,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  // HTTP transport. Defaults to a real client; tests inject a
  // package:http MockClient to exercise the _post error-mapping
  // (timeout / 401 / 429 / 5xx / non-200 / bad-200) without the network.
  final http.Client _http;

  final DateTime? Function()? healthDataConsentAtResolver;

  // Returns the user's anonymous install-id (same one the analytics
  // service uses). The Worker pseudonymises it before logging — the
  // raw install-id never appears in any audit-log line. Null/unset
  // means the Worker logs as 'anon' (acceptable, just loses
  // cross-event correlation for that call). Tests can leave this null.
  final String Function()? installIdResolver;

  // We always go through our Cloudflare Worker proxy so the Anthropic key
  // never lives in the app bundle. The Worker injects the x-api-key header
  // server-side; the app only carries APP_SECRET, which limits casual abuse
  // and can be rotated without breaking the Anthropic credential.
  // Fallback to the direct Anthropic endpoint exists only for legacy local
  // development before the proxy was deployed.
  static const _directEndpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';
  static const _apiVersion = '2023-06-01';

  // Centralised gate. Called as the first statement of every public
  // method that touches Anthropic. Keeps the GDPR check in one place
  // so a future API method can't forget it.
  void _assertHealthDataConsent() {
    final resolver = healthDataConsentAtResolver;
    if (resolver == null) return; // tests / legacy callers
    if (ConsentGate.canSendHealthData(resolver())) return;
    throw CoachApiException(
      'Coaching ist noch nicht aktiviert: bitte willige im Onboarding ein, '
      'dass deine Angaben an den Coaching-Anbieter übermittelt werden dürfen.',
      'health-data consent missing',
    );
  }

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
        return 'Profil: aktuell keine Milchabgabe (z.B. Schwangerschaft oder Stillzeit bereits beendet).';
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

  Future<CoachReply> _post({
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
    // Locale-hint for the Worker: which language's safety system-prompt
    // block to prepend (Task #88.2). Always pass the same locale the
    // caller already uses for its own systemPrompt selection.
    bool isDe = false,
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
      // Tells the Worker which locale's safety system-prompt block to
      // prepend (Task #88.2). The Worker defaults to 'en' if missing.
      headers['x-locale'] = isDe ? 'de' : 'en';
      // Pseudonymous install-id for the Worker's audit log (Task #88.7).
      // The Worker hashes it server-side with APP_SECRET; the raw value
      // is never logged. Missing header → Worker logs 'anon'.
      final installId = installIdResolver?.call();
      if (installId != null && installId.isNotEmpty) {
        headers['x-install-id'] = installId;
      }
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
      response = await _http
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
        isDe
            ? 'Der Coach braucht gerade zu lange. Versuch es gleich nochmal. Bei dringenden Fragen wende dich bitte an deine Hebamme oder Ärztin.'
            : 'The coach is taking too long. Try again in a moment. For urgent questions please reach out to your midwife or doctor.',
        'timeout after 30s',
      );
    } on SocketException catch (e) {
      throw CoachApiException(
        isDe
            ? 'Keine Internetverbindung. Versuch es gleich nochmal. Bei dringenden Fragen wende dich bitte an deine Hebamme oder Ärztin.'
            : 'No internet connection. Try again in a moment. For urgent questions please reach out to your midwife or doctor.',
        e.message,
      );
    } on http.ClientException catch (e) {
      throw CoachApiException(
        isDe
            ? 'Verbindungsproblem. Versuch es gleich nochmal. Bei dringenden Fragen wende dich bitte an deine Hebamme oder Ärztin.'
            : 'Connection problem. Try again in a moment. For urgent questions please reach out to your midwife or doctor.',
        e.message,
      );
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw CoachApiException(
        isDe
            ? 'Authentifizierungsproblem. Bitte sag der Entwicklerin Bescheid.'
            : 'Auth problem. Please tell the developer.',
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }
    if (response.statusCode == 429) {
      throw CoachApiException(
        isDe
            ? 'Der Coach ist gerade überlastet. Versuch es in einer Minute nochmal.'
            : 'Coach is overloaded right now. Try again in a minute.',
        'HTTP 429',
      );
    }
    if (response.statusCode >= 500) {
      throw CoachApiException(
        isDe
            ? 'Der Coach ist gerade nicht erreichbar. Versuch es bald nochmal.'
            : 'Coach is unavailable right now. Try again soon.',
        'HTTP ${response.statusCode}',
      );
    }
    if (response.statusCode != 200) {
      throw CoachApiException(
        isDe
            ? 'Etwas ist schiefgelaufen. Versuch es nochmal.'
            : 'Something went wrong. Try again.',
        'HTTP ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
      );
    }
    final raw = utf8.decode(response.bodyBytes);
    try {
      final body = jsonDecode(raw) as Map<String, dynamic>;
      final content = body['content'] as List;
      final text = (content.first as Map)['text'] as String;
      // The Worker tags safety-synthesised responses with this top-level
      // field so the client can render escalation/emergency/blocked bubbles
      // distinctly (Task #88.5). Anthropic never sets it; missing -> normal.
      final type = CoachResponseType.fromWire(
          body['nourishme_response_type'] as String?);
      return CoachReply(text: text, type: type);
    } catch (e) {
      // 200 OK but the body isn't the Anthropic {content:[{text}]} shape we
      // expect, e.g. a proxy/edge error page served with a 200. Surface a
      // real CoachApiException (visible message + raw body for logs) instead
      // of letting a CastError bubble up as a generic "Couldn't send".
      throw CoachApiException(
        isDe
            ? 'Etwas ist schiefgelaufen. Versuch es nochmal.'
            : 'Something went wrong. Try again.',
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
    // Recent entries logged around the current time of day. Used as a
    // vocabulary anchor for photo-only input where no typed query exists
    // to substring-match against - prevents the vision model from flipping
    // Heidelbeeren -> Pflaumen on a morning shot when the user has logged
    // Heidelbeeren 20 mornings in a row. Typically from
    // mealHistoryByTimeOfDayProvider.
    List<MealEntry> timeOfDayHints = const [],
  }) async {
    _assertHealthDataConsent();
    final isDe = _isGerman(locale);
    // Input pre-classifier (Task #88.3). Emergency/escalation keywords in
    // the user-typed text short-circuit the LLM call with a canned
    // hand-off response. The Worker does the same check defensively.
    // For parseMeal we surface the canned text via the existing
    // is_meal=false + rejectionReason channel so the diary UI shows it
    // as a snack without any UI changes; the prettier emergency/escalation
    // bubble lands with Task #88.5 (typed response handling).
    if (userText.isNotEmpty) {
      final classified =
          SafetyRules.classifyInput(userText, locale: locale);
      if (classified.classification != InputClassification.normal) {
        return MealParseResult(
          isMeal: false,
          rejectionReason: classified.response,
          summary: '',
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
          portionAmount: 0,
          portionUnit: 'g',
          portionAlias: null,
          safetyWarnings: const [],
        );
      }
    }
    // Phase context so safety_warnings stay relevant: a not-pregnant user
    // shouldn't get pregnancy-specific warnings (e.g. on an alcohol photo).
    final phaseDe = isPregnant
        ? 'schwanger (${trimester ?? 1}. Trimester)'
        : isLactating
            ? 'produziert Muttermilch (direkt oder per Pumpe)'
            : 'nicht schwanger und produziert keine Muttermilch';
    final phaseEn = isPregnant
        ? 'pregnant (trimester ${trimester ?? 1})'
        : isLactating
            ? 'producing breast milk (directly or pumped)'
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
    final historyBlock = buildBrandHistoryBlock(brandHistoryHints, isDe: isDe);
    final timeOfDayBlock = buildBrandHistoryBlock(
      timeOfDayHints,
      isDe: isDe,
      timeOfDayFallback: true,
    );
    content.add({
      'type': 'text',
      'text': '$phaseLine$historyBlock$timeOfDayBlock\n\n$entryText',
    });

    final reply = await _post(
      systemPrompt: isDe ? parsePromptDe : parsePromptEn,
      messages: [
        {'role': 'user', 'content': content},
      ],
      callType: imageBytes != null ? 'photo' : 'parse',
      cacheSystem: true,
      isDe: isDe,
    );
    // Worker-synthesised escalation/emergency/blocked responses arrive
    // as plain prose (not the JSON meal schema parseMeal expects). Detect
    // them via the response-type tag and surface the canned text via the
    // existing is_meal=false rejectionReason channel - the diary UI shows
    // it as a snack, no extra wiring needed for #93 MVP. Fancy bubble
    // styling comes via the chat path; here it stays a simple snack.
    if (reply.type != CoachResponseType.normal) {
      return MealParseResult(
        isMeal: false,
        rejectionReason: reply.text,
        summary: '',
        kcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        portionAmount: 0,
        portionUnit: 'g',
        portionAlias: null,
        safetyWarnings: const [],
      );
    }
    final text = reply.text;

    final result = MealParseResult.fromModelText(text);
    // A non-meal (no parseable nutrition) routes to the coach chat; running
    // food-safety rules on it would mis-fire (e.g. on the question "darf ich
    // Kaffee trinken?"), so only apply the deterministic floor to real meals.
    if (!result.isMeal) return result;
    // Build +35: drop LLM phantom warnings keyed on confusable food
    // names (e.g. "Muscheln" triggered for shell-shaped pasta). The
    // canonical input for context is the user's text PLUS the parsed
    // summary, so both "ich hatte Muschelnudeln" and "Conchigliette"
    // suppress the false mussel caution.
    final modelPhase = SafetyPhase(
      isPregnant: isPregnant,
      trimester: trimester,
      isLactating: isLactating,
    );
    // Build +36 fix (P0 from beta-feedback): two testers reported the
    // LLM injecting pregnancy-specific listeria warnings on cheese /
    // raw fish / cured ham even when their profile said lactation.
    // Strip these before the merge - the lactation phase has its own
    // (much narrower) deterministic warnings; pregnancy-coded prose
    // doesn't belong here.
    final phaseFilteredModelWarnings =
        SafetyRules.filterPregnancyWarningsIfLactationOnly(
      result.safetyWarnings,
      modelPhase,
    );
    final cleanedModelWarnings = SafetyRules.applyContextExclusions(
      phaseFilteredModelWarnings,
      '$userText ${result.summary}',
    );
    final deterministic = SafetyRules.allWarnings(
      '$userText ${result.summary}',
      modelPhase,
      locale: locale,
    );
    final merged = deterministic.isEmpty
        ? cleanedModelWarnings
        : SafetyRules.mergeWarnings(deterministic, cleanedModelWarnings);
    return result.copyWith(safetyWarnings: merged);
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
Antworte AUSSCHLIESSLICH mit einem JSON-Array kurzer deutscher Warn-Strings, z.B. ["Koffein: ca. 80 mg pro Dose, achte auf die Tagesgrenze von 200 mg"]. Wenn nichts kritisch ist, antworte mit []. Vermeide das Verb "stillen" und alle Adjektivformen davon ("stillende Mutter", "beim Stillen") - das Nomen "Stillzeit" für die Lebensphase ist OK. Nutze stattdessen "während du Muttermilch produzierst" oder "in der Stillzeit".'''
        : '''You are a food-safety checker. The user is: $phaseEn.
The standard risks (caffeine, alcohol, high-mercury predatory fish, raw milk / raw meat / raw fish, liver in the first trimester, lactation-suppressing herbs) are already checked separately and automatically. So name ONLY additional risks beyond those, and do NOT repeat the standard ones.
Reply ONLY with a JSON array of short English warning strings, e.g. ["Caffeine: ~80 mg per can, mind the 200 mg daily limit"]. If nothing is critical, reply with []. Avoid the verb "breastfeeding" and adjective forms ("breastfeeding mother") - the noun "lactation" for the life phase is OK. Use "while you're producing breast milk" or "during lactation" instead.''';
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
      final reply = await _post(
        systemPrompt: system,
        messages: [
          {'role': 'user', 'content': productName},
        ],
        maxTokens: 200,
        callType: 'safety',
        isDe: isDe,
      );
      // A safety-synth response is not a JSON array; fall back to the
      // deterministic warnings, the canned text isn't actionable here.
      if (reply.type != CoachResponseType.normal) return deterministic;
      final raw = reply.text.trim();
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
    // Meal-structure preference (Task #108). Drives whether the coach
    // suggests 5 meals/day, 3+1, 3-only, or skips meal-rhythm cues
    // entirely. Defaults to classic = 3+2 so callers that don't pass it
    // get the DGE default behaviour.
    String mealPattern = 'classic',
    // Shared day-state context (CoachDayContext.build): the day's
    // chronological meal sequence + full micro standing + configured
    // supplements. Before this the per-meal coach saw only aggregate
    // totals + the clock, so it guessed "next meal" from the time alone
    // and never saw the meals already logged today. Goes in the USER
    // message (volatile, uncached) so the cached system prefix is
    // untouched. Empty/null → omitted (callers without a profile).
    String? dayContext,
  }) async {
    final isDe = _isGerman(locale);
    // Distinguish the meal-time (when the user says they ate) from now
    // (wall-clock when the coach is reasoning). Same moment for live
    // logs; can be hours apart for retroactive logs (typical pattern:
    // user logs breakfast at noon). The prompt prints BOTH so the model
    // can reason about the gap and not say "iss was in ein paar Stunden"
    // when the actual meal was 3 hours ago and lunch is imminent. PATTERN
    // beta-feedback T2 + T3 (#102).
    final now = DateTime.now();
    final mealHour = (loggedAt ?? now).hour;
    final nowHour = now.hour;
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
            mealHour: mealHour,
            nowHour: nowHour,
            remaining: remaining,
            dietLine: buildDietLine(
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
            mealHour: mealHour,
            nowHour: nowHour,
            remaining: remaining,
            dietLine: buildDietLine(
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
        '\nFüge AM ENDE der Antwort eine Sektion **Fragen:** an mit 2-3 kurzen Bullets (je max 8 Wörter), die als ANTWORT-Vorlagen für die Nutzerin formuliert sind. Die Vorlagen MÜSSEN zur Ernährungsweise der Nutzerin passen: erwähne darin NIE ein Lebensmittel, das sie laut Ernährungsweise oder Vermeidungsliste gar nicht isst (z.B. bei vegetarisch/vegan kein Fisch oder Fleisch, bei veganer Ernährung auch keine Eier/Milch). Halte die Vorlagen am besten diät-neutral. Beispiele: "Ich habe wenig Zeit zum Kochen", "Ich brauche Vorschläge für unterwegs", "Mir fehlt heute Energie". Format: `- <Bullet>`. Keine Fragezeichen.';
    final followUpInstructionEn =
        '\nAppend a section **Follow-ups:** AT THE END with 2-3 short bullets (max 8 words each), phrased as REPLY templates from the user. The templates MUST fit the user\'s diet: NEVER mention a food she does not eat at all per her diet style or avoid-list (e.g. no fish or meat for vegetarian/vegan, no eggs/dairy for vegan). Keep them diet-neutral where possible. Examples: "I am short on time to cook", "I need on-the-go ideas", "I feel low energy today". Format: `- <bullet>`. No question marks.';

    var finalUserMessage = userMessage;
    // Shared day-state block right after the profile/daily context so the
    // coach reasons about the day's meal sequence + micros + supplements
    // before the per-meal review and the "next meal" suggestion.
    if (dayContext != null && dayContext.isNotEmpty) {
      finalUserMessage += '\n\n$dayContext';
    }
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
    // Meal-pattern preference line (#108). Always included so the model
    // sees the user's chosen rhythm; the prompt rule (in per_meal_de/en)
    // tells it how to honour it.
    finalUserMessage += isDe
        ? '\n\nMahlzeit-Stil-Präferenz: $mealPattern.'
        : '\n\nMeal-pattern preference: $mealPattern.';
    if (requestFollowUps) {
      finalUserMessage += isDe ? followUpInstructionDe : followUpInstructionEn;
    }

    final reply = await _post(
      isDe: isDe,
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
    return reply.text;
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
  @visibleForTesting
  static String buildBrandHistoryBlock(
    List<MealEntry> hints, {
    required bool isDe,
    // When true the block is framed as a time-of-day vocabulary anchor for
    // photo-only inputs: same line format, but the footer tells the model
    // to bias the vision interpretation toward these summaries rather than
    // copy the macros verbatim. The brand-match call site keeps the default.
    bool timeOfDayFallback = false,
  }) {
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
    final header = timeOfDayFallback
        ? (isDe
            ? '\n\nWas diese Nutzerin um diese Tageszeit häufig loggt (letzte 30 Tage, +/- 2h):'
            : '\n\nWhat this user often logs around this time of day (last 30 days, +/- 2h):')
        : (isDe
            ? '\n\nFrühere ähnliche Einträge dieser Nutzerin (Marke/Portion kennt sie schon):'
            : '\n\nEarlier similar entries from this user (brand/portion she already tracks):');
    final footer = timeOfDayFallback
        ? (isDe
            ? '\nNutze diese als Vokabular-Anker fürs Bild: bei Farb-/Form-Ambiguität (dunkle runde Frucht, weisse Creme, rote Beere) bevorzuge die Variante die zu ihrem Muster passt. Werte trotzdem frisch aus dem Bild schätzen, nicht 1:1 übernehmen.'
            : '\nUse these as a vocabulary anchor for the photo: with color/shape ambiguity (dark round fruit, white cream, red berry) prefer the variant matching her pattern. Still estimate values fresh from the image, do not copy verbatim.')
        : (isDe
            ? '\nWenn der aktuelle Eintrag zu einem davon eindeutig passt, übernimm dessen Werte direkt - nicht neu schätzen.'
            : '\nIf the current entry clearly matches one of these, use its values directly - do not re-estimate.');
    return '$header\n${lines.join("\n")}$footer';
  }

  @visibleForTesting
  static String buildDietLine({
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
    required int mealHour,
    required int nowHour,
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
    final retroLine = mealHour == nowHour
        ? 'Mahlzeit-Zeit = jetzt ($nowHour Uhr).'
        : 'Mahlzeit-Zeit: $mealHour Uhr. Jetzt: $nowHour Uhr (also nachträglich eingetragen, vor ${(nowHour - mealHour + 24) % 24} Stunden gegessen).';
    return '''
=== Profil der Nutzerin ===
Alter: $ageYears Jahre · Größe: ${heightCm.toStringAsFixed(0)} cm · Gewicht: ${weightKg.toStringAsFixed(1)} kg
Aktivitätsfaktor (PAL): $activityFactor
$phaseLine
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'de')}$dietLine

=== Tageskontext ===
$retroLine
Tagesziel: $targetKcal kcal. Protein-Ziel: ca. $proteinTargetG g.
Tagesstand inkl. dieser Mahlzeit: $totalKcalToday / $targetKcal kcal (verbleibend $remaining kcal).
Protein heute: ${totalProteinToday.toStringAsFixed(0)} g.

=== Gerade eingetragen ===
${mealRawText.isNotEmpty ? 'Originaltext: $mealRawText\n' : ''}Beschreibung: $mealSummary
Gesamtwerte dieser Mahlzeit: $mealKcal kcal, Protein ${mealProteinG.toStringAsFixed(0)} g, KH ${mealCarbsG.toStringAsFixed(0)} g, Fett ${mealFatG.toStringAsFixed(0)} g.$warningLine

Gib die strukturierte Coach-Antwort wie im System-Prompt definiert. Nutze die Profildaten oben. Wenn die Mahlzeit nachträglich eingetragen wurde (Versatz > 0 h), beziehe deinen "Nächste Mahlzeit"-Vorschlag auf JETZT (nowHour), nicht auf die Mahlzeit-Zeit.
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
    required int mealHour,
    required int nowHour,
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
    final retroLine = mealHour == nowHour
        ? 'Meal time = now ($nowHour:00).'
        : 'Meal time: $mealHour:00. Now: $nowHour:00 (so this is a retroactive log, the meal was ${(nowHour - mealHour + 24) % 24} h ago).';
    return '''
=== User profile ===
Age: $ageYears years · Height: ${heightCm.toStringAsFixed(0)} cm · Weight: ${weightKg.toStringAsFixed(1)} kg
Activity factor (PAL): $activityFactor
$phaseLine
${describeProfile(numChildrenNursing, milkSharePercent, locale: 'en')}$dietLine

=== Daily context ===
$retroLine
Daily target: $targetKcal kcal. Protein target: ~$proteinTargetG g.
Today incl. this meal: $totalKcalToday / $targetKcal kcal (remaining $remaining kcal).
Protein today: ${totalProteinToday.toStringAsFixed(0)} g.

=== Just logged ===
${mealRawText.isNotEmpty ? 'Original text: $mealRawText\n' : ''}Description: $mealSummary
Totals for this meal: $mealKcal kcal, protein ${mealProteinG.toStringAsFixed(0)} g, carbs ${mealCarbsG.toStringAsFixed(0)} g, fat ${mealFatG.toStringAsFixed(0)} g.$warningLine

Return the structured coach reply as defined in the system prompt. Use the profile data above. If the meal was logged retroactively (time offset > 0 h), base your "Next meal" suggestion on NOW (nowHour), not on the meal-time.
''';
  }

  Future<CoachReply> chat({
    required List<ChatTurn> history,
    required String todayContext,
    String locale = 'en',
  }) async {
    _assertHealthDataConsent();
    final isDe = _isGerman(locale);
    // Input pre-classifier (Task #88.3) on the LATEST user turn.
    // Emergency / escalation keywords short-circuit with the canned
    // response, no LLM call. The Worker also runs this check
    // defensively. Only the freshest user message is checked - earlier
    // turns might contain quotes of the bot's prior escalation reply
    // and would re-fire forever otherwise.
    final lastUser = history.lastWhere(
      (t) => t.isUser,
      orElse: () => const ChatTurn(isUser: true, text: ''),
    );
    if (lastUser.text.isNotEmpty) {
      final classified =
          SafetyRules.classifyInput(lastUser.text, locale: locale);
      if (classified.classification != InputClassification.normal) {
        return CoachReply(
          text: classified.response ?? '',
          type: classified.classification == InputClassification.emergency
              ? CoachResponseType.emergency
              : CoachResponseType.escalation,
        );
      }
    }
    final messages = history
        .map((turn) => {
              'role': turn.isUser ? 'user' : 'assistant',
              'content': turn.text,
            })
        .toList();
    final base = isDe ? chatPromptBaseDe : chatPromptBaseEn;
    final contextHeader = isDe ? 'Kontext heute:' : 'Context today:';
    // Inject current wall-clock time so the model can reason about
    // past-tense meal references ("had X for breakfast" said at noon
    // means breakfast was hours ago, lunch is imminent). PATTERN beta-
    // feedback T2 + T3 (#102) - T3 logs via natural-language chat and
    // got "eat something in a few hours" because the model had no
    // anchor on what time it was.
    final now = DateTime.now();
    final nowLine = isDe
        ? 'Aktuelle Uhrzeit: ${now.hour}:${now.minute.toString().padLeft(2, '0')} Uhr.'
        : 'Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}.';
    return _post(
      isDe: isDe,
      systemPrompt:
          '$base\n\n$contextHeader\n$nowLine\n$todayContext',
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
    _assertHealthDataConsent();
    final isDe = _isGerman(locale);
    final systemPrompt = isDe ? supplementPromptDe : supplementPromptEn;
    final userText = isDe
        ? 'Extrahiere die Nährwerte aus dem Foto und gib das JSON zurück.'
        : 'Extract the nutrient values from the photo and return JSON.';
    final reply = await _post(
      isDe: isDe,
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
    final text = reply.text;
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
    final servingSizeCapsules =
        (parsed['serving_size_capsules'] as num?)?.toInt() ?? 1;
    final rawValues = parsed['values'] as Map?;
    final perDose = <String, double>{};
    if (rawValues != null) {
      rawValues.forEach((k, v) {
        if (k is! String) return;
        final n = MealParseResult.coerceNutrientValue(v);
        if (n == null) return;
        final canonical = MealParseResult.canonicalNutrientKey(k);
        perDose.update(
          canonical,
          (prev) => prev + n,
          ifAbsent: () => n,
        );
      });
    }
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
      servingSizeCapsules: servingSizeCapsules,
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
  // How many physical capsules / tablets make up ONE serving (Task A6,
  // Build +34). Default 1 if the label doesn't say. Surfaced in the
  // review sheet so the user sees "1 Portion = 2 Kapseln" alongside the
  // doses-per-day pill.
  final int servingSizeCapsules;

  const SupplementParseResult({
    required this.name,
    required this.values,
    required this.dosesPerDay,
    this.servingSizeCapsules = 1,
  });
}
