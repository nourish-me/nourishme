// Compact scientific reference values for the breastfeeding/pregnancy
// nutrition assistant. Sources are noted per fact: DGE 2025, BfR, EFSA,
// WHO, LactMed, FDA/EPA, ACOG. Used in:
//   - Claude system prompts (as a context block)
//   - Settings/Onboarding info sheets
//
// Values are the most restrictive of the cited bodies unless noted.
// Last revised: 2026-05-18.

class NutritionFact {
  final String topic;
  final String summary;
  final String detail;
  final String source;
  const NutritionFact({
    required this.topic,
    required this.summary,
    required this.detail,
    required this.source,
  });
}

class NutritionFacts {
  static const caffeine = NutritionFact(
    topic: 'Koffein',
    summary: 'Max. 200 mg/Tag',
    detail:
        'Filterkaffee 200 ml ~90 mg, Espresso 30 ml ~63 mg, Schwarztee 250 ml ~28 mg, '
        'Grüner Tee 250 ml ~19 mg, Cola 330 ml ~32 mg, Dunkle Schokolade 100 g ~50-80 mg, '
        'Energy Drink 250 ml ~80 mg. Bei Neugeborenen Koffein-Halbwertszeit 65-130 h, '
        'ab 6 Monaten nur noch ~2,6 h.',
    source: 'EFSA 2015, BfR, DGE',
  );

  static const alcoholPregnancy = NutritionFact(
    topic: 'Alkohol in der Schwangerschaft',
    summary: 'Null-Toleranz',
    detail:
        'Kein sicherer Grenzwert. Alkohol gilt als embryotoxisch und teratogen, '
        'jegliche Menge kann das Fetal Alcohol Spectrum auslösen.',
    source: 'WHO, BfR, DGE, ACOG, AAP',
  );

  static const alcoholLactation = NutritionFact(
    topic: 'Alkohol in der Stillzeit',
    summary: 'Wenn überhaupt, dann mit Wartezeit',
    detail:
        'Maximal 0,5 g Ethanol/kg KG gelegentlich (ca. 1 Standardgetränk bei 60 kg). '
        'Wartezeit bis Muttermilch alkoholfrei: ca. 2-2,5 h pro Standarddrink, additiv. '
        'Pump-and-Dump reduziert Alkohol in der Milch NICHT, Alkohol diffundiert mit '
        'fallendem Blutspiegel passiv zurück. Beste Wahl: gar nicht oder Wartezeit einhalten.',
    source: 'LactMed (NIH), CDC, AAP, Academy of Breastfeeding Medicine',
  );

  static const mercuryFish = NutritionFact(
    topic: 'Quecksilberhaltiger Fisch',
    summary: 'Großraubfische meiden, kleine Fettfische bevorzugen',
    detail:
        'Meiden: Hai, Schwertfisch, Königsmakrele, Marlin, Großaugen-Thunfisch, '
        'Tilefish, Orange Roughy, Hecht, Heilbutt (>3 Portionen/Woche), Aal, Rotbarsch. '
        'Empfohlen (1-2 Portionen/Woche): Lachs, Hering, Sardinen, Makrele (Atlantic), '
        'Forelle, Kabeljau, Seelachs, Garnelen, Tilapia, Anchovis, Scholle. '
        'Thunfisch in Dose (Skipjack) max. 1 Portion 113 g/Woche.',
    source: 'FDA/EPA 2024, EFSA 2014, DGE / Netzwerk Gesund ins Leben',
  );

  static const listeriaSS = NutritionFact(
    topic: 'Listerien-Risiko Schwangerschaft',
    summary: 'In SS 17-20× erhöht',
    detail:
        'Meiden: Rohmilch, Rohmilchkäse (Brie, Camembert, Roquefort, Blauschimmel), '
        'Sauermilchkäse, Schmierrinde-Käse, Käserinden generell, Mett, Tatar, '
        'Carpaccio, Rohwurst (Salami, Teewurst), Rohschinken, Sushi, kalt geräucherter '
        'Lachs, Graved Lachs, Matjes, rohe Austern. '
        'Sichere Kerntemperatur Fleisch: ≥70 °C für 2 Min.',
    source: 'BfR, CDC, RKI',
  );

  static const vitaminAPregnancy = NutritionFact(
    topic: 'Vitamin A in der Schwangerschaft',
    summary: 'Obergrenze 3.000 µg Retinol/Tag (teratogen)',
    detail:
        'In den ersten 3 SS-Monaten keine Leber verzehren (Retinol bis 25 mg/100 g). '
        'Harte UL 3.000 µg = 10.000 IE/Tag gilt nur für vorgebildetes Retinol, '
        'nicht für β-Carotin. β-Carotin aus Karotten, Süßkartoffeln etc. unbedenklich.',
    source: 'DGE 2020, EFSA 2015, IOM 2001',
  );

  static const hydrationLactation = NutritionFact(
    topic: 'Hydration in der Stillzeit',
    summary: 'DGE: 3,1 L Total Water, davon 1,7 L Getränke',
    detail:
        'Bei Zwillingen +700-1.000 ml, bei Drillingen +1.500-2.000 ml. '
        'Mythos widerlegt: mehr trinken steigert Milchmenge NICHT (Dusdieker 1985, '
        'Horowitz 1980). Milch bleibt zu 87-88 % Wasser auch bei milder Dehydration. '
        'Best practice: "drink to thirst", hellgelber Urin als Indikator. '
        'Obergrenze >3,5-4 L kann Milchmenge sogar reduzieren (ADH-Hemmung).',
    source: 'DGE, EFSA, IOM, La Leche League',
  );

  static const galaktofugHerbs = NutritionFact(
    topic: 'Milchhemmende Kräuter',
    summary: 'Salbei und Pfefferminze in größeren Mengen meiden',
    detail:
        'Kulinarische Mengen unbedenklich. Vorsicht bei Salbei-Tee (1-3 g getrocknete '
        'Blätter mehrfach täglich), hochdosierter Pfefferminze (ätherisches Öl, '
        'Tinkturen), Mönchspfeffer (Vitex). Petersilie nur als Hauptzutat (Tabouleh) '
        'kritisch, als Garnitur unbedenklich.',
    source: 'LactMed, ABM Protokoll #32',
  );

  static const proteinLactation = NutritionFact(
    topic: 'Protein-Bedarf',
    summary: 'Stillzeit: 1,2 g/kg KG/Tag (DGE)',
    detail:
        'Nicht-schwangere Frau Basis: 0,8 g/kg. Schwangerschaft T2: 0,9 g/kg, '
        'T3: 1,0 g/kg. Stillzeit 0-6 Mo: 1,2 g/kg (+~23 g/Tag über Basis). '
        'Gut: mageres Fleisch, Fisch, Hülsenfrüchte, Eier, Milchprodukte, Tofu.',
    source: 'DGE 2025, EFSA 2012',
  );

  static const energyLactation = NutritionFact(
    topic: 'Energie-Aufschlag Stillzeit',
    summary: 'Pro 100 ml Milch ~84 kcal',
    detail:
        'Energiedichte Muttermilch 0,67 kcal/g × Synthese-Effizienz 80 % '
        '= ~84 kcal pro 100 ml. Typische Volumina: exklusiv 0-6 Mo ~780 ml/Tag, '
        '6-12 Mo ~550 ml, >12 Mo ~200-400 ml. Zwillinge exklusiv: ~1.500 ml '
        '(+~1.100 kcal). DGE-Pauschal +500 kcal bei einem Kind 0-6 Mo.',
    source: 'DGE 2025, EFSA 2017, WHO/FAO 2004',
  );

  static const energyPregnancy = NutritionFact(
    topic: 'Energie-Aufschlag Schwangerschaft',
    summary: 'T1: 0, T2: +250, T3: +500 kcal/Tag',
    detail:
        'Voraussetzung: Vor-SS-BMI 18,5-24,9, unveränderte Aktivität. '
        'Bei Mehrlingen: +300 kcal pro zusätzlichem Fetus (ACOG-Faustformel), '
        'also Zwillinge T3 etwa +800 kcal.',
    source: 'DGE 2025, EFSA, ACOG',
  );

  static const omega3 = NutritionFact(
    topic: 'Omega-3 / DHA',
    summary: '≥200 mg DHA/Tag',
    detail:
        'In SS und Stillzeit gleich. Quellen: fetter Seefisch (Lachs, Hering, Sardine, '
        'Makrele), Algenöl-Supplement. Cochrane: Omega-3-Supplementation reduziert '
        'Frühgeburten signifikant.',
    source: 'DGE, EFSA 2010, WHO/FAO',
  );

  // The compact text block injected into Claude system prompts. Kept tight so
  // it doesn't blow the context budget, only the values, not full detail.
  // German version. Use [coachContextBlockEn] for English-locale users.
  static const String coachContextBlock = '''
Wissenschaftliche Schwellenwerte (DGE 2025, EFSA, BfR, LactMed, FDA/EPA):
- Koffein: maximal 200 mg/Tag. Beispiele: Filterkaffee 200ml=90mg, Espresso 30ml=63mg, Schwarztee 250ml=28mg, Cola 330ml=32mg, Dunkle Schokolade 100g=50-80mg.
- Alkohol Schwangerschaft: 0 (kein sicherer Grenzwert, embryotoxisch).
- Alkohol Stillzeit: gelegentlich max. 0,5 g/kg KG. Wartezeit bis Milch alkoholfrei ca. 2-2,5 h pro Standardgetränk. Pump-and-Dump bringt nichts.
- Quecksilberfisch meiden: Hai, Schwertfisch, Königsmakrele, Marlin, Großaugen-Thunfisch. Empfohlen 1-2x/Woche: Lachs, Hering, Sardine, Makrele (Atlantic), Forelle, Kabeljau, Garnelen.
- Listeria-Risiko SS 17-20× erhöht: keine Rohmilch/Weichkäse aus Rohmilch, kein Mett/Tatar/Rohwurst/Rohschinken, kein Sushi/Graved Lachs/Matjes. Sichere Garung ≥70 °C / 2 Min.
- Vitamin A Obergrenze SS 3.000 µg Retinol/Tag (teratogen). Leber meiden in T1. β-Carotin unbedenklich.
- Milchhemmend in größeren Mengen: Salbei (Tee), Pfefferminzöl, Mönchspfeffer. Kulinarisch unbedenklich.
- Protein-Ziel Stillzeit: 1,2 g/kg KG/Tag (DGE).
- Hydration Stillzeit: ~3,1 L Total Water, davon ~1,7 L Getränke. Zwillinge +700-1000 ml. Mehr Trinken steigert die Milchmenge NICHT (Mythos widerlegt). Best Practice: "drink to thirst", hellgelber Urin. WICHTIG: Erwähne Hydration NICHT proaktiv in deinen Coach-Antworten. Nur wenn die Nutzerin direkt danach fragt oder Beschwerden nennt (Hitze, Erschöpfung, dunkler Urin).
- Omega-3 / DHA: ≥200 mg DHA/Tag aus fettem Seefisch oder Algenöl.

Nutze diese Werte als Referenz, wenn relevant. Zitiere Zahlen statt vage Hinweise zu geben. Erwähne die Quelle wenn der User danach fragt.
''';

  // English mirror of [coachContextBlock]. Numbers and authorities are the same,
  // just translated so an EN-speaking user gets EN coach output.
  static const String coachContextBlockEn = '''
Scientific thresholds (DGE 2025, EFSA, BfR, LactMed, FDA/EPA):
- Caffeine: maximum 200 mg/day. Examples: filter coffee 200ml=90mg, espresso 30ml=63mg, black tea 250ml=28mg, cola 330ml=32mg, dark chocolate 100g=50-80mg.
- Alcohol in pregnancy: 0 (no safe limit, embryotoxic).
- Alcohol while producing milk: occasional max 0.5 g/kg body weight. Waiting time until milk is alcohol-free ~2-2.5 h per standard drink. Pump-and-dump does NOT help.
- Avoid high-mercury fish: shark, swordfish, king mackerel, marlin, bigeye tuna. Recommended 1-2x/week: salmon, herring, sardine, mackerel (Atlantic), trout, cod, shrimp.
- Listeria risk in pregnancy is 17-20x higher: no raw milk / soft cheeses from raw milk, no steak tartare / raw deli meats / raw cured ham, no sushi / cold-smoked salmon / matjes. Safe cooking ≥70 °C / 2 min.
- Vitamin A upper limit in pregnancy 3,000 µg retinol/day (teratogenic). Avoid liver in T1. β-carotene is safe.
- Galactofuge in larger amounts: sage (tea), peppermint essential oil, chasteberry. Culinary amounts are fine.
- Protein target while producing milk: 1.2 g/kg body weight/day (DGE).
- Hydration while producing milk: ~3.1 L total water, of which ~1.7 L from drinks. Twins +700-1000 ml. Drinking more does NOT increase milk volume (myth debunked). Best practice: "drink to thirst", light-yellow urine. IMPORTANT: do NOT mention hydration proactively in your coach replies. Only when the user asks directly or reports symptoms (heat, fatigue, dark urine).
- Omega-3 / DHA: ≥200 mg DHA/day from oily sea fish or algae oil.

Use these values as a reference where relevant. Cite numbers rather than vague hints. Mention the source when the user asks for it.
''';
}
