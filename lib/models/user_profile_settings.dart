class UserProfileSettings {
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final double activityFactor;
  final int breastfeedingSupplementKcal;

  const UserProfileSettings({
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activityFactor,
    required this.breastfeedingSupplementKcal,
  });

  factory UserProfileSettings.defaults() => const UserProfileSettings(
        ageYears: 34,
        heightCm: 167.0,
        weightKg: 56.0,
        activityFactor: 1.375,
        breastfeedingSupplementKcal: 1000,
      );

  UserProfileSettings copyWith({
    int? ageYears,
    double? heightCm,
    double? weightKg,
    double? activityFactor,
    int? breastfeedingSupplementKcal,
  }) =>
      UserProfileSettings(
        ageYears: ageYears ?? this.ageYears,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityFactor: activityFactor ?? this.activityFactor,
        breastfeedingSupplementKcal:
            breastfeedingSupplementKcal ?? this.breastfeedingSupplementKcal,
      );

  Map<String, dynamic> toJson() => {
        'ageYears': ageYears,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityFactor': activityFactor,
        'breastfeedingSupplementKcal': breastfeedingSupplementKcal,
      };

  factory UserProfileSettings.fromJson(Map<String, dynamic> json) =>
      UserProfileSettings(
        ageYears: json['ageYears'] as int,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        activityFactor: (json['activityFactor'] as num).toDouble(),
        breastfeedingSupplementKcal:
            json['breastfeedingSupplementKcal'] as int,
      );
}

class ActivityLevel {
  final String label;
  final String hint;
  final double factor;
  const ActivityLevel(this.label, this.hint, this.factor);

  static const all = [
    ActivityLevel('Wenig aktiv', 'kaum Bewegung', 1.2),
    ActivityLevel('Leicht aktiv', 'Spaziergänge, leichte Hausarbeit', 1.375),
    ActivityLevel('Mäßig aktiv', 'regelmäßiges Training', 1.55),
    ActivityLevel('Sehr aktiv', 'intensives Training, körperliche Arbeit', 1.725),
  ];

  static ActivityLevel closestTo(double f) =>
      all.reduce((a, b) => (a.factor - f).abs() < (b.factor - f).abs() ? a : b);
}
