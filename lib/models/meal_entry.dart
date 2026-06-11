class MealEntry {
  final String id;
  final DateTime createdAt;
  final String rawText;
  final String summary;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double portionAmount;
  final String portionUnit;
  // Human-friendly equivalent of the portion, e.g. "eine Handvoll", "2 EL".
  // Persisted so the edit / detail views can show the same hint.
  final String? portionAlias;
  final List<String> safetyWarnings;
  // Per-meal micronutrient estimates from parseMeal, in unit-suffixed keys
  // (see [MicronutrientKey]). Null on legacy entries logged before the
  // tracker shipped; an absent key on a newer entry means the parser
  // judged that nutrient negligible (<5 % of the daily target) and
  // skipped it to save tokens - treat absent == 0 for aggregation.
  final Map<String, double>? micronutrients;

  const MealEntry({
    required this.id,
    required this.createdAt,
    required this.rawText,
    required this.summary,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.portionAmount,
    required this.portionUnit,
    this.portionAlias,
    required this.safetyWarnings,
    this.micronutrients,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'rawText': rawText,
        'summary': summary,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'portionAmount': portionAmount,
        'portionUnit': portionUnit,
        'portionAlias': portionAlias,
        'safetyWarnings': safetyWarnings,
        if (micronutrients != null) 'micronutrients': micronutrients,
      };

  // Older entries (pre-portion-persistence, pre-micronutrients) deserialise
  // with sensible defaults so existing Hive data keeps working without a
  // migration step.
  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rawText: json['rawText'] as String,
        summary: json['summary'] as String,
        kcal: json['kcal'] as int,
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        portionAmount: (json['portionAmount'] as num?)?.toDouble() ?? 0,
        portionUnit: json['portionUnit'] as String? ?? 'g',
        portionAlias: json['portionAlias'] as String?,
        safetyWarnings: List<String>.from(json['safetyWarnings'] as List),
        micronutrients: (json['micronutrients'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      );
}

// Canonical keys for per-meal micronutrient estimates. The unit is baked
// into the key so a meal's stored map is self-describing - the daily
// aggregation and the donut UI don't need a side table to know that
// folate_ug is in micrograms and iron_mg is in milligrams.
//
// Add a new nutrient by appending a key here, extending the parsePrompt
// schema (claude_client.dart), and adding its DGE/EFSA reference target
// in MicronutrientTargets (services/micronutrient_targets.dart). Existing
// stored meals don't need migration - absent keys aggregate to 0.
class MicronutrientKey {
  static const folateUg = 'folate_ug';
  static const ironMg = 'iron_mg';
  static const iodineUg = 'iodine_ug';
  static const vitaminDUg = 'vitamin_d_ug';
  static const dhaMg = 'dha_mg';
  static const b12Ug = 'b12_ug';
  static const calciumMg = 'calcium_mg';
  static const cholineMg = 'choline_mg';
  static const zincMg = 'zinc_mg';
  static const fiberG = 'fiber_g';
  static const vitaminAUg = 'vitamin_a_ug';

  // All keys in display order (matches the order the parser is asked to
  // populate them; matches the Settings list).
  static const all = <String>[
    folateUg,
    ironMg,
    iodineUg,
    vitaminDUg,
    dhaMg,
    b12Ug,
    calciumMg,
    cholineMg,
    zincMg,
    fiberG,
    vitaminAUg,
  ];
}
