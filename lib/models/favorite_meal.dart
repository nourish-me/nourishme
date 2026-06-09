class FavoriteMeal {
  final String id;
  final String summary;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double portionAmount;
  final String portionUnit;
  final List<String> safetyWarnings;
  // Per-meal micronutrient estimates from the original parse, kept so a
  // re-log via the favorite chip contributes to the day's micro totals
  // instead of silently dropping out. Null on favorites saved before this
  // field existed; treated as "no micro contribution" by the aggregator.
  final Map<String, double>? micronutrients;

  const FavoriteMeal({
    required this.id,
    required this.summary,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.portionAmount,
    required this.portionUnit,
    required this.safetyWarnings,
    this.micronutrients,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'summary': summary,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'portionAmount': portionAmount,
        'portionUnit': portionUnit,
        'safetyWarnings': safetyWarnings,
        if (micronutrients != null) 'micronutrients': micronutrients,
      };

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) => FavoriteMeal(
        id: json['id'] as String,
        summary: json['summary'] as String,
        kcal: json['kcal'] as int,
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        portionAmount: (json['portionAmount'] as num?)?.toDouble() ?? 0,
        portionUnit: json['portionUnit'] as String? ?? 'g',
        safetyWarnings:
            List<String>.from(json['safetyWarnings'] as List? ?? const []),
        micronutrients: (json['micronutrients'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      );
}
