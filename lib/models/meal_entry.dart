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
      };

  // Older entries (pre-portion-persistence) deserialise with sensible
  // defaults so existing Hive data keeps working without a migration step.
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
      );
}
