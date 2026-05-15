class MealEntry {
  final String id;
  final DateTime createdAt;
  final String rawText;
  final String summary;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
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
        'safetyWarnings': safetyWarnings,
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        rawText: json['rawText'] as String,
        summary: json['summary'] as String,
        kcal: json['kcal'] as int,
        proteinG: (json['proteinG'] as num).toDouble(),
        carbsG: (json['carbsG'] as num).toDouble(),
        fatG: (json['fatG'] as num).toDouble(),
        safetyWarnings: List<String>.from(json['safetyWarnings'] as List),
      );
}
