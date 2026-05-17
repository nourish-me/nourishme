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
      );
}
