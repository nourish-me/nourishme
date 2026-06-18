/// Deterministic food-safety rules for pregnancy and lactation.
///
/// These encode the KNOWN, finite risks (see docs/safety-rules-reference.md
/// and docs/safety-rules-fachliche-pruefung.pdf) as plain Dart so they can
/// never be silently dropped by the language model. Each rule is a pure
/// function — (product text + phase) -> warning or null — which makes it
/// directly unit-testable. The model stays responsible only for the fuzzy,
/// open-ended cases; these hard rules run regardless.
///
/// **Single source of truth for rule DATA is `assets/safety-rules.json`.**
/// Keyword/token/phrase lists and warning message templates live there so
/// the Cloudflare Worker (output post-check, Task #88.4) can read the same
/// authoritative file at deploy. This Dart file holds the MATCH LOGIC
/// (containsWord vs tokenContains, phase-gating, trimester carve-out,
/// energy-drink variant, etc.) that operates on the loaded data.
///
/// Initialization: call `SafetyRules.initFromAsset()` in `main()` before
/// `runApp`. Tests load synchronously via
/// `SafetyRules.initFromJsonString(File('assets/safety-rules.json').readAsStringSync())`
/// in `setUpAll`.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Who the user is right now. Safety warnings are phase-specific: a user who is
/// neither pregnant nor lactating should not get pregnancy/lactation warnings.
class SafetyPhase {
  final bool isPregnant;
  final int? trimester;
  final bool isLactating;

  const SafetyPhase({
    this.isPregnant = false,
    this.trimester,
    this.isLactating = false,
  });

  /// True when at least one phase applies, i.e. when safety warnings are
  /// relevant at all.
  bool get isRelevant => isPregnant || isLactating;
}

/// Loaded representation of `assets/safety-rules.json`. One field per topic
/// so the call sites can stay typed; the per-topic shape is heterogeneous
/// (some topics use `keywords`, others `tokens` + `phrases`, the caffeine
/// topic nests an `energyDrink` block, liver has `exclusions`, etc.) so we
/// pull the bits each rule needs at construction time rather than forcing a
/// uniform shape.
class SafetyRulesData {
  final String version;

  // Caffeine
  final List<String> caffeineKeywords;
  final List<String> energyDrinkKeywords;
  final Map<String, String> caffeineMessages; // locale -> default
  final Map<String, String> energyDrinkPregnantMessages; // locale -> message

  // Alcohol
  final List<String> alcoholKeywords;
  final List<String> alcoholFreeMarkers;
  final Map<String, String> alcoholPregnantMessages; // locale -> message
  final Map<String, String> alcoholLactatingMessages; // locale -> message

  // Raw animal
  final List<String> rawAnimalKeywords;
  // Heat-prefix tokens that, when paired with a rawAnimal keyword in the
  // same product string, switch the warning to the reassurance variant
  // ("durchgebacken ist sicher"). Beta tester #99: pauschale Listerien-
  // Warnung bei "Backcamembert" verunsicherte statt informierte.
  final List<String> rawAnimalHeatedMarkers;
  // Substring exclusions that suppress a rawAnimal hit on pasta-shape
  // compounds (Build +35: "Muschelnudeln" must not trigger the Muschel
  // keyword). Mirrors the algae 'kombucha vs kombu' exclusion logic.
  final List<String> rawAnimalExclusions;
  // Subset of rawAnimal keywords that ALSO triggers a warning during
  // lactation (Build +35 follow-up): raw mussels/oysters/clams/scallops
  // carry norovirus, hepatitis A and vibrio that make the mother ill
  // directly - even though listeria/toxoplasma don't pass through milk,
  // a stillende Mutter being knocked out interrupts breastfeeding.
  final List<String> rawAnimalLactationShellfishKeywords;
  final Map<String, String> rawAnimalPregnantMessages;
  final Map<String, String> rawAnimalPregnantHeatedMessages;
  final Map<String, String> rawAnimalLactatingShellfishMessages;

  // Mercury fish
  final List<String> mercuryFishTokens;
  final List<String> mercuryFishPhrases;
  final Map<String, String> mercuryFishPregnantMessages;
  final Map<String, String> mercuryFishLactatingMessages;

  // Liver
  final List<String> liverTokens;
  final List<String> liverPhrases;
  final List<String> liverExclusions;
  final Map<String, String> liverT1Messages;
  final Map<String, String> liverT2PlusMessages;

  // Milk-suppressing herbs
  final List<String> herbTokens;
  final List<String> largeAmountMarkers;
  final Map<String, String> herbLactatingMessages;

  // Algae
  final List<String> algaeTokens;
  final List<String> algaeExclusions;
  final Map<String, String> algaePregnantMessages;

  // Boar offal
  final List<String> boarOffalTokens;
  final List<String> boarOffalPhrases;
  final Map<String, String> boarOffalMessages;

  // Quinine
  final List<String> quinineKeywords;
  final Map<String, String> quininePregnantMessages;

  // Topic detection patterns (for mergeWarnings dedupe).
  final Map<SafetyTopic, TopicDetectionPattern> detectionPatterns;

  // Per-topic severity. Topics omit the key in JSON → default `warn`. Only
  // alcohol is marked `critical` today (no known safe amount in pregnancy
  // or lactation). Drives the rendering tier in the UI (errorContainer +
  // Icons.error vs the standard tertiaryContainer + Icons.warning_amber).
  final Map<SafetyTopic, SafetyWarningSeverity> topicSeverities;

  // Input-trigger keyword lists for the emergency / escalation pre-check
  // (Task #88.3). Map keys are locale codes ('de', 'en'). The Worker
  // holds a sync'd inline copy in api/worker.js for defense in depth.
  final Map<String, List<String>> emergencyKeywords;
  final Map<String, String> emergencyResponses;
  final Map<String, List<String>> escalationKeywords;
  final Map<String, String> escalationResponses;

  SafetyRulesData._({
    required this.version,
    required this.caffeineKeywords,
    required this.energyDrinkKeywords,
    required this.caffeineMessages,
    required this.energyDrinkPregnantMessages,
    required this.alcoholKeywords,
    required this.alcoholFreeMarkers,
    required this.alcoholPregnantMessages,
    required this.alcoholLactatingMessages,
    required this.rawAnimalKeywords,
    required this.rawAnimalHeatedMarkers,
    required this.rawAnimalExclusions,
    required this.rawAnimalLactationShellfishKeywords,
    required this.rawAnimalPregnantMessages,
    required this.rawAnimalPregnantHeatedMessages,
    required this.rawAnimalLactatingShellfishMessages,
    required this.mercuryFishTokens,
    required this.mercuryFishPhrases,
    required this.mercuryFishPregnantMessages,
    required this.mercuryFishLactatingMessages,
    required this.liverTokens,
    required this.liverPhrases,
    required this.liverExclusions,
    required this.liverT1Messages,
    required this.liverT2PlusMessages,
    required this.herbTokens,
    required this.largeAmountMarkers,
    required this.herbLactatingMessages,
    required this.algaeTokens,
    required this.algaeExclusions,
    required this.algaePregnantMessages,
    required this.boarOffalTokens,
    required this.boarOffalPhrases,
    required this.boarOffalMessages,
    required this.quinineKeywords,
    required this.quininePregnantMessages,
    required this.detectionPatterns,
    required this.topicSeverities,
    required this.emergencyKeywords,
    required this.emergencyResponses,
    required this.escalationKeywords,
    required this.escalationResponses,
  });

  factory SafetyRulesData.fromJson(Map<String, dynamic> json) {
    final topics = json['topics'] as Map<String, dynamic>;
    List<String> strList(dynamic raw) =>
        ((raw as List?) ?? const []).cast<String>();

    Map<String, String> messagesForKey(
        Map<String, dynamic> topic, String key) {
      // messages: { de: { key: "..." }, en: { key: "..." } } → flatten to
      // { de: "...", en: "..." } for the variant we care about. Missing
      // locale falls through to an empty string which would be a programmer
      // error visible in tests.
      final messages = (topic['messages'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final out = <String, String>{};
      messages.forEach((locale, variants) {
        final variantMap =
            (variants as Map?)?.cast<String, dynamic>() ?? const {};
        final value = variantMap[key];
        if (value is String) out[locale] = value;
      });
      return out;
    }

    final caffeine = topics['caffeine'] as Map<String, dynamic>;
    final energyDrink = caffeine['energyDrink'] as Map<String, dynamic>;
    final alcohol = topics['alcohol'] as Map<String, dynamic>;
    final rawAnimal = topics['rawAnimal'] as Map<String, dynamic>;
    final mercury = topics['mercuryFish'] as Map<String, dynamic>;
    final liver = topics['liver'] as Map<String, dynamic>;
    final herbs = topics['milkSuppressingHerbs'] as Map<String, dynamic>;
    final algae = topics['algae'] as Map<String, dynamic>;
    final boar = topics['boarOffal'] as Map<String, dynamic>;
    final quinine = topics['quinine'] as Map<String, dynamic>;

    final inputTriggers =
        (json['inputTriggers'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    Map<String, List<String>> keywordsByLocale(String stage) {
      final stageMap =
          (inputTriggers[stage] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final byLocale =
          (stageMap['keywords'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final out = <String, List<String>>{};
      byLocale.forEach((locale, list) {
        if (list is List) out[locale] = list.cast<String>();
      });
      return out;
    }

    Map<String, String> responsesByLocale(String stage) {
      final stageMap =
          (inputTriggers[stage] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final raw = (stageMap['responses'] as Map?) ?? const {};
      return raw.cast<String, String>();
    }

    final detectionRaw =
        (json['topicDetectionPatterns'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final patterns = <SafetyTopic, TopicDetectionPattern>{};
    for (final entry in detectionRaw.entries) {
      final topic = _topicByJsonKey[entry.key];
      if (topic == null) continue;
      final body = (entry.value as Map).cast<String, dynamic>();
      patterns[topic] = TopicDetectionPattern(
        containsAny: strList(body['containsAny']),
        wordRegex: body['wordRegex'] as String?,
      );
    }

    // Per-topic severity. Default is `warn`; the JSON may bump a topic to
    // `critical` (alcohol today). Unknown values fall back to `warn` rather
    // than throwing, so a future severity tier doesn't crash older clients.
    final severities = <SafetyTopic, SafetyWarningSeverity>{};
    for (final entry in topics.entries) {
      final topic = _topicByJsonKey[entry.key];
      if (topic == null) continue;
      final body = (entry.value as Map?)?.cast<String, dynamic>();
      final label = body?['severity'] as String?;
      severities[topic] = _severityByLabel[label] ?? SafetyWarningSeverity.warn;
    }

    return SafetyRulesData._(
      version: (json['version'] as String?) ?? 'unknown',
      caffeineKeywords: strList(caffeine['keywords']),
      energyDrinkKeywords: strList(energyDrink['keywords']),
      caffeineMessages: messagesForKey(caffeine, 'default'),
      energyDrinkPregnantMessages: messagesForKey(energyDrink, 'pregnant'),
      alcoholKeywords: strList(alcohol['keywords']),
      alcoholFreeMarkers: strList(alcohol['exclusionMarkers']),
      alcoholPregnantMessages: messagesForKey(alcohol, 'pregnant'),
      alcoholLactatingMessages: messagesForKey(alcohol, 'lactating'),
      rawAnimalKeywords: strList(rawAnimal['keywords']),
      rawAnimalHeatedMarkers: strList(rawAnimal['heatedMarkers']),
      rawAnimalExclusions: strList(rawAnimal['exclusions']),
      rawAnimalLactationShellfishKeywords:
          strList(rawAnimal['lactationShellfishKeywords']),
      rawAnimalPregnantMessages: messagesForKey(rawAnimal, 'pregnant'),
      rawAnimalPregnantHeatedMessages:
          messagesForKey(rawAnimal, 'pregnantHeated'),
      rawAnimalLactatingShellfishMessages:
          messagesForKey(rawAnimal, 'lactatingShellfish'),
      mercuryFishTokens: strList(mercury['tokens']),
      mercuryFishPhrases: strList(mercury['phrases']),
      mercuryFishPregnantMessages: messagesForKey(mercury, 'pregnant'),
      mercuryFishLactatingMessages: messagesForKey(mercury, 'lactating'),
      liverTokens: strList(liver['tokens']),
      liverPhrases: strList(liver['phrases']),
      liverExclusions: strList(liver['exclusions']),
      liverT1Messages: messagesForKey(liver, 'trimester1'),
      liverT2PlusMessages: messagesForKey(liver, 'trimester2plus'),
      herbTokens: strList(herbs['tokens']),
      largeAmountMarkers: strList(herbs['largeAmountMarkers']),
      herbLactatingMessages: messagesForKey(herbs, 'lactating'),
      algaeTokens: strList(algae['tokens']),
      algaeExclusions: strList(algae['exclusions']),
      algaePregnantMessages: messagesForKey(algae, 'pregnant'),
      boarOffalTokens: strList(boar['tokens']),
      boarOffalPhrases: strList(boar['phrases']),
      boarOffalMessages: messagesForKey(boar, 'any'),
      quinineKeywords: strList(quinine['keywords']),
      quininePregnantMessages: messagesForKey(quinine, 'pregnant'),
      detectionPatterns: patterns,
      topicSeverities: severities,
      emergencyKeywords: keywordsByLocale('emergency'),
      emergencyResponses: responsesByLocale('emergency'),
      escalationKeywords: keywordsByLocale('escalation'),
      escalationResponses: responsesByLocale('escalation'),
    );
  }
}

/// Match pattern used by mergeWarnings dedupe. `containsAny` triggers on
/// any plain substring (cheap pre-filter); `wordRegex` is an optional
/// stricter check that must be a Dart-compatible RegExp pattern.
class TopicDetectionPattern {
  final List<String> containsAny;
  final String? wordRegex;
  final RegExp? _compiled;

  TopicDetectionPattern({
    required this.containsAny,
    this.wordRegex,
  }) : _compiled = wordRegex == null ? null : RegExp(wordRegex);

  bool matches(String lower) {
    if (containsAny.any(lower.contains)) return true;
    final compiled = _compiled;
    if (compiled != null && compiled.hasMatch(lower)) return true;
    return false;
  }
}

// JSON key -> SafetyTopic. Kept here so the JSON stays human-readable
// (camelCase) and the enum stays Dart-idiomatic.
const Map<String, SafetyTopic> _topicByJsonKey = {
  'alcohol': SafetyTopic.alcohol,
  'caffeine': SafetyTopic.caffeine,
  'mercuryFish': SafetyTopic.mercuryFish,
  'liver': SafetyTopic.liver,
  'rawAnimal': SafetyTopic.rawAnimal,
  'algae': SafetyTopic.algae,
  'quinine': SafetyTopic.quinine,
  'boarOffal': SafetyTopic.boarOffal,
  'milkSuppressingHerbs': SafetyTopic.milkSuppressingHerbs,
};

const Map<String?, SafetyWarningSeverity> _severityByLabel = {
  'warn': SafetyWarningSeverity.warn,
  'critical': SafetyWarningSeverity.critical,
};

class SafetyRules {
  static SafetyRulesData? _data;

  /// True once the JSON data is loaded. Rule methods throw a clear error
  /// before init so a missed `main()` call surfaces immediately instead of
  /// silently returning empty warnings.
  static bool get isInitialized => _data != null;

  /// Async asset load for app startup. Call from `main()` BEFORE `runApp`.
  static Future<void> initFromAsset() async {
    final raw = await rootBundle.loadString('assets/safety-rules.json');
    initFromJsonString(raw);
  }

  /// Synchronous init for tests and the Worker-mirror code path. Parses
  /// the given JSON string and replaces any previously loaded data.
  static void initFromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    _data = SafetyRulesData.fromJson(decoded);
  }

  static SafetyRulesData get _d {
    final d = _data;
    if (d == null) {
      throw StateError(
        'SafetyRules not initialized. Call SafetyRules.initFromAsset() in '
        "main() before runApp, or SafetyRules.initFromJsonString(...) in a "
        "test's setUpAll.",
      );
    }
    return d;
  }

  /// Whole-word/phrase match against a product string. Lowercases, strips
  /// non-German accents (é/è/à/ô/ç/ñ → e/a/o/c/n) so French / Italian /
  /// Spanish cheese and ham names match regardless of how the user types
  /// them ("Gruyère" / "Gruyere" both work), replaces any run of remaining
  /// non-letters (German umlauts kept) with a single space, pads with
  /// spaces, then looks for the space-delimited keyword. This avoids the
  /// substring trap (e.g. "Tomate" must not match "mate") AND avoids
  /// silently dropping accented characters into whitespace, which used to
  /// break "Gruyère" → "gruy re" and miss the keyword entirely.
  ///
  /// Keywords in safety-rules.json are kept in their ASCII / German-umlaut
  /// form (no foreign accents); _stripForeignAccents normalises the
  /// product side to match.
  static String _stripForeignAccents(String s) {
    const map = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u',
      'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
    };
    var result = s.toLowerCase();
    map.forEach((accented, plain) {
      result = result.replaceAll(accented, plain);
    });
    return result;
  }

  static bool _containsWord(String product, String keyword) {
    final normalised = _stripForeignAccents(product);
    final cleaned = ' '
        '${normalised.replaceAll(RegExp('[^a-zäöüß ]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()}'
        ' ';
    return cleaned.contains(' $keyword ');
  }

  /// True if any whitespace token CONTAINS [needle] as a substring. Unlike
  /// _containsWord this deliberately matches inside a token, which is needed
  /// for German head-compounds (Thunfisch -> "Thunfischsalat", "Thunfischpizza").
  /// Only safe with long, distinctive needles — see the fish keywords below,
  /// where "Makrele" still won't trip "Königsmakrele" because they share no
  /// substring in that direction.
  static bool _tokenContains(String product, String needle) {
    for (final t in product
        .toLowerCase()
        .replaceAll(RegExp('[^a-zäöüß ]+'), ' ')
        .split(' ')) {
      if (t.isNotEmpty && t.contains(needle)) return true;
    }
    return false;
  }

  static bool _isDe(String locale) => locale.toLowerCase().startsWith('de');

  /// Rule 1 — caffeine (EFSA: 200 mg/day is safe in pregnancy AND lactation,
  /// spread over the day). We can't sum exact mg without portion data, so the
  /// warning states the daily limit when a caffeine-bearing item is detected.
  /// Special case: energy drinks during pregnancy get a stricter "avoid
  /// entirely" message per DGE; for lactation the 200 mg/day limit still
  /// applies. Returns null when the phase isn't relevant or no caffeine
  /// source matches.
  static String? caffeine(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final d = _d;
    if (!d.caffeineKeywords.any((k) => _containsWord(product, k))) return null;
    final de = _isDe(locale);
    final isEnergyDrink =
        d.energyDrinkKeywords.any((k) => _containsWord(product, k));
    if (isEnergyDrink && phase.isPregnant) {
      return d.energyDrinkPregnantMessages[de ? 'de' : 'en'];
    }
    return d.caffeineMessages[de ? 'de' : 'en'];
  }

  /// Rule 2 — alcohol. Pregnancy AND lactation: avoid entirely. The previous
  /// lactation message ("~2-2.5 h wait per standard drink") came from older
  /// guidelines (Hebammen consensus, LactMed-style); the current DGE position
  /// paper + BfR risk assessment both recommend complete abstinence while
  /// producing milk, because alcohol passes into milk and even a single
  /// drink measurably affects milk-supply hormones. Plus the practical
  /// argument: "standard drink" is defined inconsistently by users, so a
  /// wait-time formula sets up a false-safety failure mode.
  /// Returns null when the phase isn't relevant, the item is an alcohol-free
  /// variant, or no alcohol source matches.
  static String? alcohol(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final d = _d;
    final lower = product.toLowerCase();
    if (d.alcoholFreeMarkers.any(lower.contains)) return null;
    if (!d.alcoholKeywords.any((k) => _containsWord(product, k))) return null;
    final de = _isDe(locale);
    final localeKey = de ? 'de' : 'en';
    if (phase.isPregnant) return d.alcoholPregnantMessages[localeKey];
    return d.alcoholLactatingMessages[localeKey];
  }

  /// Rule 3 — raw animal products (listeria / toxoplasma). Unlike caffeine and
  /// alcohol, this is a PREGNANCY-specific risk: the elevated listeriosis risk
  /// is tied to pregnancy and doesn't carry through breast milk, so it does
  /// NOT fire for a (non-pregnant) lactating user.
  ///
  /// Heat carve-out: if the product string also contains a heated-marker
  /// token (gebacken, überbacken, ofen, gegrillt, baked, broiled, grilled,
  /// ...) we return the reassurance variant instead of the avoid-message,
  /// because heat reliably kills listeria. This avoids the
  /// "Backcamembert -> pauschal meiden" false-positive (beta tester #99).
  ///
  /// Returns null otherwise.
  static String? rawAnimalProducts(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final d = _d;
    // Pasta-shape exclusions (Build +35): "Muschelnudeln" / "Conchiglie"
    // contain the "muschel" substring but are pasta, not seafood. Mirror
    // of the algae kombucha/kombu pattern.
    final lower = product.toLowerCase();
    if (d.rawAnimalExclusions.any(lower.contains)) return null;
    if (!d.rawAnimalKeywords.any((k) => _containsWord(product, k))) {
      return null;
    }
    // Heat-marker check runs as token-substring (not word-boundary) so
    // German compounds like "Backcamembert" / "Ofenkäse" match too. Safe
    // because the precondition is already a rawAnimal hit - we never
    // suppress a warning on unrelated bakery items like "Backwaren".
    final isHeated =
        d.rawAnimalHeatedMarkers.any((m) => _tokenContains(product, m));
    final localeKey = _isDe(locale) ? 'de' : 'en';
    // Heat reliably kills the pathogens (listeria/toxoplasma) so the same
    // reassurance message fires for BOTH pregnant and lactating users.
    // For lactating users this is what tells them "we noticed your input"
    // when they log something like baked camembert - otherwise silence
    // reads as a missed warning. The reassurance text says raw would be
    // a listeria concern (specific to pregnancy) but fully heated is safe;
    // for a lactating user this is still informative and not misleading.
    if (isHeated) {
      return d.rawAnimalPregnantHeatedMessages[localeKey];
    }
    // Raw (no heat marker) - pregnancy gets the broad listeria/toxo
    // warning. Lactation is mostly silent (those pathogens don't pass
    // through breast milk) EXCEPT for raw shellfish/molluscs, which
    // carry norovirus/hepatitis A/vibrio that make the mother ill
    // herself (Build +35 follow-up tester report). BfR backs this.
    if (phase.isPregnant) {
      return d.rawAnimalPregnantMessages[localeKey];
    }
    if (phase.isLactating &&
        d.rawAnimalLactationShellfishKeywords
            .any((k) => _containsWord(product, k))) {
      return d.rawAnimalLactatingShellfishMessages[localeKey];
    }
    return null;
  }

  /// Rule 4 — high-mercury predatory fish (BfR). Pregnancy: avoid. Lactation:
  /// limit (mercury passes into milk in small amounts). Returns null when the
  /// phase isn't relevant or no high-mercury fish matches.
  static String? mercuryFish(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final d = _d;
    final hit = d.mercuryFishTokens.any((k) => _tokenContains(product, k)) ||
        d.mercuryFishPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    final localeKey = _isDe(locale) ? 'de' : 'en';
    if (phase.isPregnant) return d.mercuryFishPregnantMessages[localeKey];
    return d.mercuryFishLactatingMessages[localeKey];
  }

  /// Rule 5 — liver / high-dose vitamin A. Pregnancy across ALL trimesters
  /// (BfR + DGE position): T1 is strictest because retinol is teratogenic
  /// during organogenesis, but BfR explicitly recommends avoiding liver of
  /// all species across the whole pregnancy because of the consistently
  /// very high vitamin A content. The previous "only T1" carve-out was
  /// based on older / US literature and was not strict enough vs. the
  /// German guideline state. T1 keeps the "avoid" wording; T2/T3 get a
  /// softer "very limited" wording so it reads as guidance, not alarm.
  /// Unknown trimester defaults to 1 (matches the app convention).
  static String? liverVitaminA(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    final d = _d;
    final lower = product.toLowerCase();
    if (d.liverExclusions.any(lower.contains)) return null;
    final hit = d.liverTokens.any((k) => _tokenContains(product, k)) ||
        d.liverPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    final localeKey = _isDe(locale) ? 'de' : 'en';
    final trimester = phase.trimester ?? 1;
    if (trimester == 1) return d.liverT1Messages[localeKey];
    return d.liverT2PlusMessages[localeKey];
  }

  /// Rule 6 — sage/peppermint and milk supply. Deliberately SOFT: a
  /// milk-suppressing effect is NOT reliably established and, if any, needs
  /// large/medicinal amounts (docs/safety-rules-reference.md, rule 6 — weak
  /// evidence). So this never warns on an everyday cup of tea — only when a
  /// herb AND a large/medicinal-amount signal are both present, and even then
  /// it returns a gentle note, not a warning. Lactation only. Null otherwise.
  static String? lactationHerbs(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isLactating) return null;
    final d = _d;
    if (!d.herbTokens.any((k) => _tokenContains(product, k))) {
      return null;
    }
    final lower = product.toLowerCase();
    if (!d.largeAmountMarkers.any(lower.contains)) return null;
    return d.herbLactatingMessages[_isDe(locale) ? 'de' : 'en'];
  }

  /// Rule 7a (BfR) — wild boar offal: PFAS, dioxin, PCB. Pregnancy only;
  /// BfR also lists women of childbearing age and lactating women in the
  /// avoidance group, so we fire for both pregnant and lactating users.
  /// Returns null otherwise.
  static String? boarOffal(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final d = _d;
    final hit = d.boarOffalTokens.any((k) => _tokenContains(product, k)) ||
        d.boarOffalPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    return d.boarOffalMessages[_isDe(locale) ? 'de' : 'en'];
  }

  /// Rule 8 — quinine-containing drinks. Pregnancy: avoid (BfR). Returns null
  /// in lactation or for non-pregnant users — BfR scopes the recommendation
  /// to pregnancy. Tonic water + bitter lemon are the realistic everyday
  /// hits; the "chinin"/"quinine" keywords catch direct mentions for the
  /// rare case someone logs a bitter spirit.
  static String? quinine(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    final d = _d;
    if (!d.quinineKeywords.any((k) => _containsWord(product, k))) return null;
    return d.quininePregnantMessages[_isDe(locale) ? 'de' : 'en'];
  }

  /// Rule 7 — algae / seaweed products. Pregnancy-only (DGE
  /// recommendation): unpredictable iodine load + arsenic + other
  /// contaminants. Sushi rolls with nori are the most common everyday hit;
  /// algae supplements (spirulina/chlorella tablets) the most concentrated
  /// one. Returns null in lactation or for non-pregnant users — the source
  /// scopes this to pregnancy.
  static String? algae(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    final d = _d;
    final lower = product.toLowerCase();
    // "Kombucha" (fermented tea) contains the substring "kombu" but is NOT
    // seaweed — exclude it so it can't trip the algae rule. Real "Kombu"
    // (the kelp) still fires because it never contains "kombucha".
    if (d.algaeExclusions.any(lower.contains)) return null;
    if (!d.algaeTokens.any((k) => _tokenContains(product, k))) return null;
    return d.algaePregnantMessages[_isDe(locale) ? 'de' : 'en'];
  }

  /// Runs every deterministic rule against [product] and returns the warnings
  /// that fired, in a stable order. These known, hard risks always appear here
  /// regardless of what the language model returns.
  static List<String> allWarnings(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    final out = <String>[];
    for (final w in [
      caffeine(product, phase, locale: locale),
      alcohol(product, phase, locale: locale),
      rawAnimalProducts(product, phase, locale: locale),
      mercuryFish(product, phase, locale: locale),
      liverVitaminA(product, phase, locale: locale),
      lactationHerbs(product, phase, locale: locale),
      algae(product, phase, locale: locale),
      boarOffal(product, phase, locale: locale),
      quinine(product, phase, locale: locale),
    ]) {
      if (w != null) out.add(w);
    }
    return out;
  }

  /// Merges the deterministic warnings with the model's extra ones:
  /// deterministic first (they're the trusted floor), then any model warning
  /// that isn't an exact duplicate AND doesn't touch a topic already covered
  /// by a deterministic rule. The topic-based drop is the important bit: a
  /// beta-tester logged "200 ml Sekt" and the LLM appended a 2-2.5h wait-
  /// time formula even though the deterministic rule (correctly) said
  /// "avoid completely". The exact-string dedupe didn't catch it because
  /// the LLM-paraphrased it. Now: if the deterministic warning covers
  /// alcohol/caffeine/liver/etc., drop ANY LLM warning that mentions the
  /// same topic - the model has trained itself on older, looser guidance
  /// and would otherwise walk the user back from the current DGE/BfR
  /// position.
  static List<String> mergeWarnings(
      List<String> deterministic, List<String> model) {
    final out = <String>[...deterministic];
    final coveredTopics = topicsFor(deterministic);
    for (final w in model) {
      if (w.isEmpty || out.contains(w)) continue;
      final wTopics = topicsFor([w]);
      if (wTopics.intersection(coveredTopics).isNotEmpty) continue;
      out.add(w);
    }
    return out;
  }

  /// Pre-classify user input BEFORE forwarding to the language model
  /// (Task #88.3). Returns:
  /// - `emergency` if a 112-tier symptom keyword matches (heavy bleeding,
  ///   preterm labour, no baby movement, vision changes etc.). UI shows
  ///   the emergency response, no LLM call.
  /// - `escalation` for medical-handoff topics (medication, gestational
  ///   diabetes, mastitis, postpartum depression etc.). UI shows the
  ///   escalation response, no LLM call.
  /// - `normal` otherwise (forward to Worker).
  ///
  /// Matched case-insensitive as substrings on the lowered user text.
  /// The Worker holds a sync'd defense-in-depth copy of the same lists.
  /// Returns the matched keyword as `ruleId` for audit-logging; that's
  /// the only piece of input metadata we keep on the Worker side.
  static InputClassificationResult classifyInput(String userText,
      {String locale = 'en'}) {
    final text = userText.toLowerCase();
    if (text.isEmpty) return InputClassificationResult.normal;
    final d = _d;
    final localeKey = _isDe(locale) ? 'de' : 'en';

    // Emergency takes precedence over escalation: a user typing "wehen +
    // medikament" should land on the emergency response, not the (softer)
    // escalation handoff.
    final emergencyHit = (d.emergencyKeywords[localeKey] ?? const [])
        .firstWhere(text.contains, orElse: () => '');
    if (emergencyHit.isNotEmpty) {
      return InputClassificationResult(
        classification: InputClassification.emergency,
        ruleId: emergencyHit,
        response: d.emergencyResponses[localeKey],
      );
    }
    final escalationHit = (d.escalationKeywords[localeKey] ?? const [])
        .firstWhere(text.contains, orElse: () => '');
    if (escalationHit.isNotEmpty) {
      return InputClassificationResult(
        classification: InputClassification.escalation,
        ruleId: escalationHit,
        response: d.escalationResponses[localeKey],
      );
    }
    return InputClassificationResult.normal;
  }

  /// Defense-in-depth filter that removes phantom safety warnings the
  /// language model invents from confusable food names (Build +35
  /// tester report: a photo of Muschelnudeln-soup triggered both a
  /// "shell pasta" parse AND a freehand "Muscheln rohe Meerestiere"
  /// warning, because the LLM saw the substring "Muschel" in the
  /// product name and improvised a listeria caution that has nothing
  /// to do with pasta).
  ///
  /// Filters mussel-style warnings when the meal context contains
  /// pasta-shape language ("Muschelnudeln", "Conchiglie", etc.). The
  /// canonical Pasta-form anchor in parse_de/en should already prevent
  /// this in most cases; this is the belt-and-suspenders layer.
  static List<String> applyContextExclusions(
      List<String> warnings, String originalInput) {
    final inputLower = originalInput.toLowerCase();
    final inputSuggestsPasta = const [
      'muschelnudel',
      'muschelpasta',
      'conchiglie',
      'conchigliette',
      'shell pasta',
      'pasta shell',
    ].any(inputLower.contains);
    if (!inputSuggestsPasta) return warnings;
    // Drop any warning that names "Muscheln" / "mussels" as the
    // hazardous ingredient. The bare presence of the substring is
    // enough - the LLM-fuzzy warning isn't structured.
    return warnings.where((w) {
      final lower = w.toLowerCase();
      if (!lower.contains('muschel') && !lower.contains('mussel')) {
        return true;
      }
      // Keep the warning only if it explicitly says it does NOT apply
      // (e.g. "Muschelnudeln sind Pasta, nicht Muscheln") - very rare,
      // but don't suppress a legitimate reassurance line.
      if (lower.contains('keine muschel') || lower.contains('not mussel')) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Visual severity for a single warning string. Looks up the topic via
  /// [topicsFor] and returns the highest configured severity across all
  /// matched topics. Warnings that don't match a known topic (model-fuzzy
  /// elaborations) default to `warn`. This is the seam the UI uses to pick
  /// the red vs. amber rendering — no schema change on the persisted
  /// `safetyWarnings: List<String>` required.
  static SafetyWarningSeverity severityFor(String warning) {
    final d = _d;
    final touched = topicsFor([warning]);
    var max = SafetyWarningSeverity.warn;
    for (final topic in touched) {
      final s = d.topicSeverities[topic] ?? SafetyWarningSeverity.warn;
      if (s.index > max.index) max = s;
    }
    return max;
  }

  /// Highest severity across [warnings] - drives the warnings card colour
  /// in the ConfirmSheet (one critical warning makes the whole block red).
  static SafetyWarningSeverity highestSeverity(List<String> warnings) {
    var max = SafetyWarningSeverity.warn;
    for (final w in warnings) {
      final s = severityFor(w);
      if (s.index > max.index) max = s;
    }
    return max;
  }

  /// Detect which safety topics a list of warning strings touches. Used by
  /// mergeWarnings to drop LLM elaborations on topics the deterministic
  /// rule already covered, and exposed for tests + (later) prompt
  /// instrumentation. Keyword-based detection by design - the warnings
  /// are natural prose, not structured tags.
  static Set<SafetyTopic> topicsFor(List<String> warnings) {
    final patterns = _d.detectionPatterns;
    final out = <SafetyTopic>{};
    for (final w in warnings) {
      final lower = w.toLowerCase();
      for (final entry in patterns.entries) {
        if (entry.value.matches(lower)) out.add(entry.key);
      }
    }
    return out;
  }
}

enum SafetyTopic {
  alcohol,
  caffeine,
  mercuryFish,
  liver,
  rawAnimal,
  algae,
  quinine,
  boarOffal,
  milkSuppressingHerbs,
}

/// Visual severity tier for a food-safety warning. Ordered: higher index
/// wins when merging multiple severities. New tiers can be appended without
/// breaking older clients (unknown JSON labels fall back to `warn`).
enum SafetyWarningSeverity {
  warn,
  critical,
}

/// Result of the input pre-classifier (Task #88.3). `normal` means the
/// input is safe to forward to the language model; the other two stages
/// short-circuit with a fixed, hardcoded response.
enum InputClassification {
  /// No emergency or escalation keyword matched. Send to the Worker.
  normal,

  /// Acute danger pattern (heavy bleeding, preterm labour, no baby
  /// movement, fainting, vision changes). UI shows the emergency
  /// response immediately, no LLM call. Caller should also expose a
  /// 112 tap-to-call affordance.
  emergency,

  /// Medical-handoff pattern (medication, gestational diabetes,
  /// mastitis, postpartum depression, etc.). UI shows the escalation
  /// response immediately, no LLM call.
  escalation,
}

/// Result of [SafetyRules.classifyInput] - paired classification + the
/// matched keyword (rule-ID) for audit logging + the locale-appropriate
/// response text the UI should render. For [InputClassification.normal]
/// the ruleId and response are null.
class InputClassificationResult {
  final InputClassification classification;
  final String? ruleId;
  final String? response;

  const InputClassificationResult({
    required this.classification,
    this.ruleId,
    this.response,
  });

  static const normal =
      InputClassificationResult(classification: InputClassification.normal);
}
