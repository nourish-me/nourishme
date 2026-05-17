class UserProfileSettings {
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final double activityFactor;
  final int numChildrenNursing;
  final int milkSharePercent;
  final int childrenAgeGroup; // 0 = 0-6mo, 1 = 6-12mo, 2 = 12+mo
  final int milkSupplementKcal;

  const UserProfileSettings({
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activityFactor,
    required this.numChildrenNursing,
    required this.milkSharePercent,
    required this.childrenAgeGroup,
    required this.milkSupplementKcal,
  });

  factory UserProfileSettings.defaults() => const UserProfileSettings(
        ageYears: 34,
        heightCm: 167.0,
        weightKg: 56.0,
        activityFactor: 1.375,
        numChildrenNursing: 2,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
        milkSupplementKcal: 1000,
      );

  /// Suggestion based on number of children, age, and share percentage.
  /// Per-child kcal: 0-6mo ~500, 6-12mo ~400, 12+mo ~300 for full supply.
  static int suggestedSupplement({
    required int numChildren,
    required int ageGroup,
    required int sharePercent,
  }) {
    if (numChildren <= 0) return 0;
    const perChild = [500, 400, 300];
    final idx = ageGroup.clamp(0, 2);
    return (numChildren * perChild[idx] * sharePercent / 100).round();
  }

  UserProfileSettings copyWith({
    int? ageYears,
    double? heightCm,
    double? weightKg,
    double? activityFactor,
    int? numChildrenNursing,
    int? milkSharePercent,
    int? childrenAgeGroup,
    int? milkSupplementKcal,
  }) =>
      UserProfileSettings(
        ageYears: ageYears ?? this.ageYears,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityFactor: activityFactor ?? this.activityFactor,
        numChildrenNursing: numChildrenNursing ?? this.numChildrenNursing,
        milkSharePercent: milkSharePercent ?? this.milkSharePercent,
        childrenAgeGroup: childrenAgeGroup ?? this.childrenAgeGroup,
        milkSupplementKcal: milkSupplementKcal ?? this.milkSupplementKcal,
      );

  Map<String, dynamic> toJson() => {
        'ageYears': ageYears,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityFactor': activityFactor,
        'numChildrenNursing': numChildrenNursing,
        'milkSharePercent': milkSharePercent,
        'childrenAgeGroup': childrenAgeGroup,
        'milkSupplementKcal': milkSupplementKcal,
      };

  factory UserProfileSettings.fromJson(Map<String, dynamic> json) {
    final numChildren = json['numChildrenNursing'] as int? ?? 2;
    final share = json['milkSharePercent'] as int? ?? 100;
    final ageGroup = json['childrenAgeGroup'] as int? ?? 0;
    return UserProfileSettings(
      ageYears: json['ageYears'] as int,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      activityFactor: (json['activityFactor'] as num).toDouble(),
      numChildrenNursing: numChildren,
      milkSharePercent: share,
      childrenAgeGroup: ageGroup,
      milkSupplementKcal: json['milkSupplementKcal'] as int? ??
          suggestedSupplement(
            numChildren: numChildren,
            ageGroup: ageGroup,
            sharePercent: share,
          ),
    );
  }
}

class ActivityLevel {
  final String label;
  final String hint;
  final double factor;
  const ActivityLevel(this.label, this.hint, this.factor);

  static const all = [
    ActivityLevel('Gering', 'kaum Bewegung', 1.2),
    ActivityLevel('Mäßig', 'Spaziergänge, leichte Hausarbeit', 1.375),
    ActivityLevel('Aktiv', 'regelmäßiges Training', 1.55),
    ActivityLevel('Hoch', 'intensives Training, körperliche Arbeit', 1.725),
  ];

  static ActivityLevel closestTo(double f) =>
      all.reduce((a, b) => (a.factor - f).abs() < (b.factor - f).abs() ? a : b);
}

class ChildAgeGroup {
  final String label;
  final String hint;
  final int kcalPerChild;
  const ChildAgeGroup(this.label, this.hint, this.kcalPerChild);

  static const all = [
    ChildAgeGroup('0–6', 'voller Milchbedarf', 500),
    ChildAgeGroup('6–12', 'mit Beikost', 400),
    ChildAgeGroup('12+', 'erweiterte Stillzeit', 300),
  ];
}
