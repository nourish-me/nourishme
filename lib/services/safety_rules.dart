/// Deterministic food-safety rules for pregnancy and lactation.
///
/// These encode the KNOWN, finite risks (see docs/safety-rules-reference.md)
/// as plain Dart so they can never be silently dropped by the language model.
/// Each rule is a pure function — (product text + phase) -> warning or null —
/// which makes it directly unit-testable. The model stays responsible only for
/// the fuzzy, open-ended cases; these hard rules run regardless.
///
/// This module is the first slice (caffeine). The remaining rules (alcohol,
/// raw animal products, mercury fish, liver/vitamin A) follow the same shape.
library;

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

class SafetyRules {
  // Caffeine-bearing items. Deliberately specific: bare "tea"/"Tee" is omitted
  // because herbal/fruit teas carry no caffeine — only the caffeinated kinds
  // are listed. Matched as whole words/phrases (see _containsWord), NOT raw
  // substrings, so "Tomate" can't trip the "mate" keyword.
  static const _caffeineKeywords = <String>[
    'kaffee', 'coffee', 'espresso', 'cappuccino', 'latte', 'macchiato', 'mocha',
    'cola', 'energy', 'red bull', 'mate', 'matcha', 'guarana',
    'schwarztee', 'black tea', 'grüntee', 'gruentee', 'green tea',
  ];

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
  /// Keywords in this file are kept in their ASCII / German-umlaut form
  /// (no foreign accents); _stripForeignAccents normalises the product
  /// side to match.
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

  // Energy drinks get a stricter rule than other caffeine sources: DGE
  // explicitly says pregnant women should avoid them entirely because of
  // taurine, inositol and other ingredients whose interactions aren't
  // well understood. Lactation keeps the 200 mg/day limit.
  static const _energyDrinkKeywords = <String>[
    'energy', 'energydrink', 'energy drink', 'red bull', 'monster',
    'rockstar', 'relentless', 'effect',
  ];

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
    if (!_caffeineKeywords.any((k) => _containsWord(product, k))) return null;
    final de = locale.toLowerCase().startsWith('de');
    final isEnergyDrink =
        _energyDrinkKeywords.any((k) => _containsWord(product, k));
    if (isEnergyDrink && phase.isPregnant) {
      return de
          ? 'Energy-Drinks: in der Schwangerschaft komplett meiden (DGE, wegen Taurin, Inosit und weiteren Inhaltstoffen mit ungeklärten Wechselwirkungen).'
          : 'Energy drinks: avoid entirely in pregnancy (DGE: taurine, inositol and other ingredients with unclear interactions).';
    }
    return de
        ? 'Koffein: achte auf die Tagesgrenze von 200 mg (EFSA), über den Tag verteilt.'
        : 'Caffeine: mind the 200 mg daily limit (EFSA), spread over the day.';
  }

  // Alcohol sources, DE + EN. German compounds (Rotwein, Glühwein...) are
  // listed explicitly because whole-word matching won't find "wein" inside
  // them — that same strictness is what stops "Schweinebraten" from matching
  // "wein". Short words like "gin"/"rum" are safe here precisely because they
  // match as whole words only ("Rumpsteak" / "Ingwer" don't trip them).
  static const _alcoholKeywords = <String>[
    'alkohol', 'alcohol',
    'wein', 'wine', 'rotwein', 'weißwein', 'weisswein', 'glühwein', 'gluehwein',
    'sekt', 'prosecco', 'champagner', 'champagne',
    'bier', 'beer', 'pils',
    'schnaps', 'wodka', 'vodka', 'whisky', 'whiskey', 'gin', 'rum',
    'likör', 'likoer', 'liqueur', 'cocktail', 'aperol', 'spritz', 'sangria',
    'brandy', 'cognac', 'tequila', 'baileys', 'eierlikör', 'eierlikoer',
  ];

  // Alcohol-free variants must never trigger the alcohol rule. Checked as raw
  // substrings (markers like "0,0 %" contain non-letters) before the keyword
  // scan.
  static const _alcoholFreeMarkers = <String>[
    'alkoholfrei', 'alcohol-free', 'alcohol free', 'non-alcoholic',
    '0,0', '0.0',
  ];

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
    final lower = product.toLowerCase();
    if (_alcoholFreeMarkers.any(lower.contains)) return null;
    if (!_alcoholKeywords.any((k) => _containsWord(product, k))) return null;
    final de = locale.toLowerCase().startsWith('de');
    if (phase.isPregnant) {
      return de
          ? 'Alkohol: in der Schwangerschaft ganz meiden, es gibt keine bekannte sichere Menge.'
          : 'Alcohol: avoid completely in pregnancy; there is no known safe amount.';
    }
    return de
        ? 'Alkohol: auch beim Milchproduzieren meiden (DGE/BfR). Alkohol geht in die Muttermilch über und kann schon nach kleinen Mengen die Milchmenge messbar drücken.'
        : 'Alcohol: avoid while producing milk too (DGE/BfR). Alcohol passes into breast milk and even small amounts measurably affect milk supply.';
  }

  // Raw / undercooked animal products carrying listeria or toxoplasma risk.
  // Compounds are listed explicitly (rohmilchkäse, weichkäse, briekäse) so
  // word matching finds them; this same strictness is what keeps "Omelett"
  // off "mett", "Brioche" off "brie", "Tatarensauce" off "tatar". Bare
  // "lachs"/"salmon" is intentionally NOT a keyword — only the raw/smoked
  // forms (Räucherlachs, Graved) are risky; cooked salmon is fine.
  //
  // Selection logic — we deliberately do NOT list every cheese / cured meat
  // that could be raw-milk. Generic words like "Parmesan" or "Mozzarella"
  // would false-positive on industrial pasteurised versions sold under the
  // same name. We only list keywords where either (a) the standard
  // traditional product IS raw-milk / raw / cold-smoked even in the
  // pasteurised-by-default supermarket landscape (Appenzeller, Gruyère,
  // Parmaschinken, Matjes), or (b) the wash-rind cheeses where the risk is
  // structural (rind biology), independent of milk treatment.
  //
  // Origin of the additional entries: beta tester logged "Brötchen mit
  // Appenzeller Käse" in pregnancy and the LLM confidently replied
  // "ist pasteurisiert" — Appenzeller is traditionally raw-milk. So the
  // list is expanded, and per_meal_de/en + parse_de/en prompts are tightened
  // to never assert pasteurisation status from a cheese/meat/fish name.
  static const _rawAnimalKeywords = <String>[
    // Raw milk + raw-milk-direct (Vorzugsmilch is a German specialty that
    // is genuinely unpasteurised and sold legally - easy to miss).
    'rohmilch', 'rohmilchkäse', 'rohmilchkaese', 'raw milk',
    'vorzugsmilch', 'hofmilch',
    // Raw / cured meats, including Italian / Swiss / Spanish cured ham
    // family - all traditionally air-cured raw, listeria + toxoplasma.
    'mett', 'mettwurst', 'tatar', 'hackepeter', 'carpaccio', 'rohwurst', 'salami',
    'rohschinken', 'parmaschinken', 'prosciutto', 'serrano', 'serranoschinken',
    'coppa', 'bresaola', 'bündnerfleisch', 'buendnerfleisch', 'pancetta',
    'lachsschinken',
    // Wild / game (toxoplasma). Bare "wild" matches the German word for
    // game/venison; "wild boar"/"wildschwein" cover the explicit cases.
    // Note: wild boar offal (Wildschweinleber, Wildschwein-Innereien) is
    // additionally flagged by the dedicated boarOffal rule below for
    // PFAS / dioxin / PCB contamination per BfR, on top of this
    // listeria/toxoplasma hit.
    'wild', 'wildbraten', 'wildschwein', 'reh', 'rehbraten', 'hirsch',
    // Raw / cold-smoked / pickled fish - the cooked/hot-smoked versions of
    // many of these are fine, but the marketing names blur the line, so we
    // warn on the names that ARE the cold-cured form (Matjes, Bismarck,
    // Rollmops, Bückling are all uncooked-cured by definition).
    'sushi', 'sashimi', 'roher fisch', 'raw fish', 'roher lachs',
    'räucherlachs', 'raeucherlachs', 'räucherfisch', 'raeucherfisch',
    'graved', 'gravlax', 'smoked salmon',
    'matjes', 'bismarckhering', 'rollmops', 'bückling', 'bueckling',
    'roher hering', 'sauerlappen',
    // Raw molluscs (norovirus, hepatitis A on top of listeria).
    'auster', 'austern', 'oyster', 'oysters',
    // Cheeses. Wash-rind (Munster, Limburger, Reblochon, Vacherin, Romadur,
    // Handkäse) carry the structural rind-biology risk; the raw-milk hard
    // cheeses (Appenzeller, Gruyère, Comté, Parmigiano Reggiano, Pecorino,
    // Manchego, Beaufort, Bergkäse) are listed by their traditional names.
    // We list "Parmigiano Reggiano" explicitly but NOT bare "Parmesan" -
    // the latter is sold pre-grated and industrially pasteurised in
    // Germany, hitting it would mis-fire.
    'weichkäse', 'weichkaese', 'camembert', 'brie', 'briekäse', 'briekaese',
    'gorgonzola', 'roquefort', 'blauschimmel',
    'munster', 'limburger', 'reblochon', 'vacherin', 'romadur', 'handkäse',
    'handkaese',
    'appenzeller', 'gruyere', 'comte',
    'parmigiano reggiano', 'pecorino', 'manchego', 'beaufort',
    'bergkäse', 'bergkaese', 'cantal',
    // Egg-based raw sauces / desserts. Keywords kept in ASCII form;
    // _stripForeignAccents normalises "Béarnaise" → "bearnaise" at match
    // time so listing only "bearnaise" here covers both spellings.
    'rohes ei', 'raw egg', 'tiramisu', 'mousse', 'feinkostsalat',
    'hollandaise', 'sauce hollandaise', 'bearnaise', 'sauce bearnaise',
    // Sprouts / seedlings - frequent salmonella source.
    'sprossen', 'bohnensprossen', 'alfalfa', 'alfalfasprossen', 'mungo',
    'mungosprossen', 'mungbohnensprossen',
  ];

  /// Rule 3 — raw animal products (listeria / toxoplasma). Unlike caffeine and
  /// alcohol, this is a PREGNANCY-specific risk: the elevated listeriosis risk
  /// is tied to pregnancy and doesn't carry through breast milk, so it does
  /// NOT fire for a (non-pregnant) lactating user. Returns null otherwise.
  static String? rawAnimalProducts(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    if (!_rawAnimalKeywords.any((k) => _containsWord(product, k))) return null;
    return locale.toLowerCase().startsWith('de')
        ? 'Roh vom Tier: in der Schwangerschaft meiden (Listerien-/Toxoplasmose-Risiko), z.B. Rohmilch, rohes Fleisch/Fisch, Räucherfisch, Weichkäse.'
        : 'Raw animal foods: avoid in pregnancy (listeria/toxoplasma risk), e.g. raw milk, raw meat/fish, smoked fish, soft cheese.';
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

  // High-mercury predatory fish. Distinctive names matched as token-substrings
  // so compounds (Thunfischsalat, Haifischsteak, Hechtsuppe) are caught. Plain
  // "Makrele" is intentionally absent — regular mackerel is low-mercury and
  // even recommended; only "Königsmakrele" (king mackerel) is listed.
  static const _mercuryFishTokens = <String>[
    'thunfisch', 'tuna', 'hai', 'schwertfisch', 'swordfish', 'hecht', 'pike',
    'königsmakrele', 'koenigsmakrele', 'marlin', 'butterfisch',
  ];
  static const _mercuryFishPhrases = <String>['king mackerel'];

  /// Rule 4 — high-mercury predatory fish (BfR). Pregnancy: avoid. Lactation:
  /// limit (mercury passes into milk in small amounts). Returns null when the
  /// phase isn't relevant or no high-mercury fish matches.
  static String? mercuryFish(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final hit = _mercuryFishTokens.any((k) => _tokenContains(product, k)) ||
        _mercuryFishPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    final de = locale.toLowerCase().startsWith('de');
    if (phase.isPregnant) {
      return de
          ? 'Quecksilber: Großraubfisch (Thunfisch, Hai, Schwertfisch, Hecht) in der Schwangerschaft meiden.'
          : 'Mercury: avoid large predatory fish (tuna, shark, swordfish, pike) in pregnancy.';
    }
    return de
        ? 'Quecksilber: Großraubfisch (Thunfisch, Hai, Schwertfisch) beim Milchproduzieren einschränken.'
        : 'Mercury: limit large predatory fish (tuna, shark, swordfish) while producing milk.';
  }

  // Liver sources (token-substring catches Kalbsleber, Hühnerleber, Leberwurst,
  // Leberpastete). "retinol" covers high-dose vitamin A supplements.
  static const _liverTokens = <String>['leber', 'liver', 'retinol'];
  static const _liverPhrases = <String>['foie gras'];
  // Leberkäse / Leberkäs / Leberkas (incl. -semmel compounds) is a meatloaf
  // that traditionally contains NO liver despite the name — must not trigger.
  static const _liverExclusions = <String>['leberkäs', 'leberkaes', 'leberkas'];

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
    final lower = product.toLowerCase();
    if (_liverExclusions.any(lower.contains)) return null;
    final hit = _liverTokens.any((k) => _tokenContains(product, k)) ||
        _liverPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    final de = locale.toLowerCase().startsWith('de');
    final trimester = phase.trimester ?? 1;
    if (trimester == 1) {
      return de
          ? 'Leber/Vitamin A: im 1. Trimester meiden (hoher Retinol-Gehalt, in hohen Dosen teratogen).'
          : 'Liver/vitamin A: avoid in the first trimester (high retinol, teratogenic at high doses).';
    }
    return de
        ? 'Leber/Vitamin A: in der gesamten Schwangerschaft sehr zurückhaltend (BfR: Verzicht auf Leber aller Tierarten wegen schwankend hoher Retinol-Werte).'
        : 'Liver/vitamin A: stay very cautious throughout pregnancy (BfR advises avoiding liver of all species due to inconsistently high retinol content).';
  }

  static const _lactationHerbTokens = <String>[
    'salbei', 'sage', 'pfefferminz', 'peppermint',
  ];
  // Signals of a LARGE / medicinal amount. Deliberately specific (salbeiöl,
  // pfefferminzöl — not bare "öl") so an everyday dish with "Olivenöl" doesn't
  // trip it.
  static const _largeAmountMarkers = <String>[
    'literweise', 'abstill', 'konzentrat', 'tinktur', 'extrakt',
    'ätherisch', 'essential oil', 'hochdosiert', 'salbeiöl', 'pfefferminzöl',
  ];

  /// Rule 6 — sage/peppermint and milk supply. Deliberately SOFT: a
  /// milk-suppressing effect is NOT reliably established and, if any, needs
  /// large/medicinal amounts (docs/safety-rules-reference.md, rule 6 — weak
  /// evidence). So this never warns on an everyday cup of tea — only when a
  /// herb AND a large/medicinal-amount signal are both present, and even then
  /// it returns a gentle note, not a warning. Lactation only. Null otherwise.
  static String? lactationHerbs(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isLactating) return null;
    if (!_lactationHerbTokens.any((k) => _tokenContains(product, k))) {
      return null;
    }
    final lower = product.toLowerCase();
    if (!_largeAmountMarkers.any(lower.contains)) return null;
    return locale.toLowerCase().startsWith('de')
        ? 'Hinweis: Salbei/Pfefferminze in großen Mengen können theoretisch die Milchbildung dämpfen. Alltagsmengen sind unkritisch.'
        : 'Note: large amounts of sage/peppermint may theoretically lower milk supply. Everyday amounts are fine.';
  }

  // Wild boar offal (Wildschwein-Innereien). BfR scopes this separately from
  // the regular game/raw-animal hit: in addition to listeria/toxoplasma the
  // organs of wild boar specifically carry elevated PFAS, dioxin and PCB
  // loads from the food chain, with measurable accumulation. The standard
  // game keywords (wildschwein) already fire the rawAnimal rule; this adds
  // a SECOND warning when the user explicitly logs the offal-portion form.
  // Single-token compounds (matched as token-substrings so "Wildschweinleber"
  // is found inside "Wildschweinleberpastete" too).
  static const _boarOffalTokens = <String>[
    'wildschweinleber', 'wildschweinniere', 'wildschweininnereien',
  ];
  // Multi-word phrases (matched as whole-word/phrase so "Wildschwein-Innereien"
  // and "wild boar offal" land here - the hyphen splits the German compound
  // into two tokens and _tokenContains can't bridge that).
  static const _boarOffalPhrases = <String>[
    'wildschwein innereien', 'wild boar liver', 'wild boar offal',
  ];

  /// Rule 7a (BfR) — wild boar offal: PFAS, dioxin, PCB. Pregnancy only;
  /// BfR also lists women of childbearing age and lactating women in the
  /// avoidance group, so we fire for both pregnant and lactating users.
  /// Returns null otherwise.
  static String? boarOffal(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isRelevant) return null;
    final hit = _boarOffalTokens.any((k) => _tokenContains(product, k)) ||
        _boarOffalPhrases.any((k) => _containsWord(product, k));
    if (!hit) return null;
    return locale.toLowerCase().startsWith('de')
        ? 'Wildschwein-Innereien: in Schwangerschaft und Stillzeit meiden (BfR: hohe PFAS-, Dioxin- und PCB-Gehalte).'
        : 'Wild boar offal: avoid in pregnancy and lactation (BfR: elevated PFAS, dioxin and PCB content).';
  }

  // Quinine-bearing drinks: tonic water, bitter lemon, and some bitter
  // spirits (Aperol-style aren't always quinine-based; bare "tonic" is
  // the safest hit). BfR says pregnancy = avoid quinine. We match the
  // explicit drink names because bare "tonic" would also catch unrelated
  // wellness "skin tonic" / "hair tonic" entries that nobody logs as
  // food anyway, but to be safe we use _containsWord (whole-word) for the
  // generic ones.
  static const _quinineKeywords = <String>[
    'tonic water', 'tonic-water', 'tonicwater',
    'bitter lemon', 'bitter-lemon', 'bitterlemon',
    'gin tonic', 'gin-tonic', 'gintonic',
    'chinin', 'quinine',
  ];

  /// Rule 8 — quinine-containing drinks. Pregnancy: avoid (BfR). Returns null
  /// in lactation or for non-pregnant users — BfR scopes the recommendation
  /// to pregnancy. Tonic water + bitter lemon are the realistic everyday
  /// hits; the "chinin"/"quinine" keywords catch direct mentions for the
  /// rare case someone logs a bitter spirit.
  static String? quinine(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    if (!_quinineKeywords.any((k) => _containsWord(product, k))) return null;
    return locale.toLowerCase().startsWith('de')
        ? 'Chininhaltige Getränke (Tonic Water, Bitter Lemon): in der Schwangerschaft meiden (BfR).'
        : 'Quinine-containing drinks (tonic water, bitter lemon): avoid in pregnancy (BfR).';
  }

  // Algae / seaweed products. DGE recommends pregnant users avoid these:
  // iodine content swings wildly between batches (often above the 600 µg/d
  // UL in a single serving) and many products carry arsenic and other
  // contaminants. Listed by the names most likely to appear in user logs;
  // "algen" (plural, NOT bare "alge") catches "Algensalat", "Algen-Smoothie",
  // "Algenprodukte" without false-positiving "Algerien" (which contains
  // "alge" but not "algen"). "algae" / "seaweed" cover the English forms.
  static const _algaeTokens = <String>[
    'algen', 'algae', 'seaweed',
    'nori', 'wakame', 'kombu', 'kelp', 'dulse', 'arame', 'hijiki',
    'spirulina', 'chlorella',
  ];

  /// Rule 7 — algae / seaweed products. Pregnancy-only (DGE
  /// recommendation): unpredictable iodine load + arsenic + other
  /// contaminants. Sushi rolls with nori are the most common everyday hit;
  /// algae supplements (spirulina/chlorella tablets) the most concentrated
  /// one. Returns null in lactation or for non-pregnant users — the source
  /// scopes this to pregnancy.
  static String? algae(String product, SafetyPhase phase,
      {String locale = 'en'}) {
    if (!phase.isPregnant) return null;
    // "Kombucha" (fermented tea) contains the substring "kombu" but is NOT
    // seaweed — exclude it so it can't trip the algae rule. Real "Kombu"
    // (the kelp) still fires because it never contains "kombucha".
    if (product.toLowerCase().contains('kombucha')) return null;
    if (!_algaeTokens.any((k) => _tokenContains(product, k))) return null;
    return locale.toLowerCase().startsWith('de')
        ? 'Algen/Algenprodukte: in der Schwangerschaft besser meiden. Jodgehalt schwankt stark und liegt oft über der Tagesobergrenze, dazu Arsen und andere Kontaminanten (DGE).'
        : 'Algae/seaweed products: better avoided in pregnancy. Iodine content varies wildly and often exceeds the daily upper limit, plus arsenic and other contaminants (DGE).';
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

  /// Detect which safety topics a list of warning strings touches. Used by
  /// mergeWarnings to drop LLM elaborations on topics the deterministic
  /// rule already covered, and exposed for tests + (later) prompt
  /// instrumentation. Keyword-based detection by design - the warnings
  /// are natural prose, not structured tags.
  static Set<SafetyTopic> topicsFor(List<String> warnings) {
    final out = <SafetyTopic>{};
    for (final w in warnings) {
      final lower = w.toLowerCase();
      // Alcohol: also catch beverage-name walk-backs. LLM elaborations
      // often phrase their "a glass is fine" advice without the word
      // "alcohol" - referring to "ein Glas Wein", "a glass of wine",
      // "Sekt", "beer", etc. We must drop those too.
      if (lower.contains('alkohol') ||
          lower.contains('alcohol') ||
          RegExp(r'\bwein\b|\bwine\b|\bbier\b|\bbeer\b|sekt|prosecco|'
                  r'champagn|cocktail|schnaps|whisk|spirits|'
                  r'\brum\b|\bvodka\b|\bgin\b|likör|liqueur')
              .hasMatch(lower)) {
        out.add(SafetyTopic.alcohol);
      }
      if (lower.contains('koffein') || lower.contains('caffeine')) {
        out.add(SafetyTopic.caffeine);
      }
      if (lower.contains('quecksilber') || lower.contains('mercury')) {
        out.add(SafetyTopic.mercuryFish);
      }
      if (lower.contains('leber') ||
          RegExp(r'\bliver\b').hasMatch(lower)) {
        out.add(SafetyTopic.liver);
      }
      if (lower.contains('rohmilch') ||
          lower.contains('raw milk') ||
          lower.contains('rohes fleisch') ||
          lower.contains('raw meat') ||
          lower.contains('roher fisch') ||
          lower.contains('raw fish') ||
          lower.contains('weichkäse') ||
          lower.contains('listerien') ||
          lower.contains('listeria')) {
        out.add(SafetyTopic.rawAnimal);
      }
      if (lower.contains('algen') || lower.contains('algae') ||
          lower.contains('seetang') || lower.contains('seaweed')) {
        out.add(SafetyTopic.algae);
      }
      if (lower.contains('chinin') || lower.contains('quinine') ||
          lower.contains('tonic')) {
        out.add(SafetyTopic.quinine);
      }
      if (lower.contains('wildschwein') ||
          lower.contains('wild boar')) {
        out.add(SafetyTopic.boarOffal);
      }
      if (lower.contains('salbei') || lower.contains('sage') ||
          lower.contains('pfefferminz') || lower.contains('peppermint')) {
        out.add(SafetyTopic.milkSuppressingHerbs);
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
