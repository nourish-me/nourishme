class UserProfileSettings {
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final double activityFactor;
  // Pregnancy
  final bool isPregnant;
  final int? trimester; // 1, 2, 3 when isPregnant
  // Lactation
  final int numChildrenNursing;
  final int milkSharePercent;
  final int childrenAgeGroup; // 0 = 0-6mo, 1 = 6-12mo, 2 = 12+mo
  // 0 means "no explicit volume, derive from share% + age + count".
  // Otherwise the user's measured / estimated daily milk output.
  final int dailyMilkVolumeMl;
  // Persistent override of the lactation supplement. When 0 the daily milk
  // volume is used (mL * 0.84). When set, takes precedence (manual mode).
  final int milkSupplementKcal;
  // Optional manual macro split as percentages of total kcal. Carbs are the
  // remainder (100 - protein - fat) so the split always sums to 100 %.
  // 0 means "use the auto-default" for that macro.
  final int customProteinPct;
  final int customFatPct;

  const UserProfileSettings({
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activityFactor,
    this.isPregnant = false,
    this.trimester,
    required this.numChildrenNursing,
    required this.milkSharePercent,
    required this.childrenAgeGroup,
    this.dailyMilkVolumeMl = 0,
    this.milkSupplementKcal = 0,
    this.customProteinPct = 0,
    this.customFatPct = 0,
  });

  factory UserProfileSettings.defaults() => const UserProfileSettings(
        ageYears: 34,
        heightCm: 167.0,
        weightKg: 56.0,
        activityFactor: 1.375,
        numChildrenNursing: 2,
        milkSharePercent: 100,
        childrenAgeGroup: 0,
        dailyMilkVolumeMl: 1500, // twins exclusive 0-6mo (research)
      );

  // Estimated daily milk volume given the family structure. Used as a default
  // when the user hasn't entered an explicit value. Numbers come from the
  // deep research: single 0-6mo ~780, 6-12mo ~575, >12mo ~300; doubles by
  // child count, scaled by user's share.
  static int estimatedDailyVolumeMl({
    required int numChildren,
    required int ageGroup,
    required int sharePercent,
  }) {
    if (numChildren <= 0) return 0;
    const perChild = [780, 575, 300];
    final idx = ageGroup.clamp(0, 2);
    return (numChildren * perChild[idx] * sharePercent / 100).round();
  }

  // Lactation kcal supplement based on volume (mL × 0.84 kcal/mL).
  static int volumeBasedSupplement(int dailyVolumeMl) =>
      (dailyVolumeMl * 0.84).round();

  // Pregnancy kcal supplement per trimester (DGE 2025).
  static int pregnancySupplementKcal(int trimester) {
    switch (trimester) {
      case 2:
        return 250;
      case 3:
        return 500;
      default:
        return 0;
    }
  }

  // Backward-compat helper: previous share-based formula.
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
    bool? isPregnant,
    int? trimester,
    int? numChildrenNursing,
    int? milkSharePercent,
    int? childrenAgeGroup,
    int? dailyMilkVolumeMl,
    int? milkSupplementKcal,
    int? customProteinPct,
    int? customFatPct,
  }) =>
      UserProfileSettings(
        ageYears: ageYears ?? this.ageYears,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityFactor: activityFactor ?? this.activityFactor,
        isPregnant: isPregnant ?? this.isPregnant,
        trimester: trimester ?? this.trimester,
        numChildrenNursing: numChildrenNursing ?? this.numChildrenNursing,
        milkSharePercent: milkSharePercent ?? this.milkSharePercent,
        childrenAgeGroup: childrenAgeGroup ?? this.childrenAgeGroup,
        dailyMilkVolumeMl: dailyMilkVolumeMl ?? this.dailyMilkVolumeMl,
        milkSupplementKcal: milkSupplementKcal ?? this.milkSupplementKcal,
        customProteinPct: customProteinPct ?? this.customProteinPct,
        customFatPct: customFatPct ?? this.customFatPct,
      );

  Map<String, dynamic> toJson() => {
        'ageYears': ageYears,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityFactor': activityFactor,
        'isPregnant': isPregnant,
        'trimester': trimester,
        'numChildrenNursing': numChildrenNursing,
        'milkSharePercent': milkSharePercent,
        'childrenAgeGroup': childrenAgeGroup,
        'dailyMilkVolumeMl': dailyMilkVolumeMl,
        'milkSupplementKcal': milkSupplementKcal,
        'customProteinPct': customProteinPct,
        'customFatPct': customFatPct,
      };

  factory UserProfileSettings.fromJson(Map<String, dynamic> json) {
    final numChildren = json['numChildrenNursing'] as int? ?? 0;
    final share = json['milkSharePercent'] as int? ?? 100;
    final ageGroup = json['childrenAgeGroup'] as int? ?? 0;
    return UserProfileSettings(
      ageYears: json['ageYears'] as int,
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      activityFactor: (json['activityFactor'] as num).toDouble(),
      isPregnant: json['isPregnant'] as bool? ?? false,
      trimester: json['trimester'] as int?,
      numChildrenNursing: numChildren,
      milkSharePercent: share,
      childrenAgeGroup: ageGroup,
      dailyMilkVolumeMl: json['dailyMilkVolumeMl'] as int? ?? 0,
      milkSupplementKcal: json['milkSupplementKcal'] as int? ?? 0,
      customProteinPct: json['customProteinPct'] as int? ?? 0,
      customFatPct: json['customFatPct'] as int? ?? 0,
    );
  }
}

class ActivityLevel {
  final String label;
  final String hint;
  final double factor;
  const ActivityLevel(this.label, this.hint, this.factor);

  static const all = [
    ActivityLevel('Gering', 'Kaum Bewegung', 1.2),
    ActivityLevel('Mäßig', 'Spaziergänge, leichte Hausarbeit', 1.375),
    ActivityLevel('Aktiv', 'Regelmäßiges Training', 1.55),
    ActivityLevel('Hoch', 'Intensives Training, körperliche Arbeit', 1.725),
  ];

  static ActivityLevel closestTo(double f) =>
      all.reduce((a, b) => (a.factor - f).abs() < (b.factor - f).abs() ? a : b);
}

class ChildAgeGroup {
  final String label;
  final String hint;
  final int typicalMlPerChild;
  const ChildAgeGroup(this.label, this.hint, this.typicalMlPerChild);

  static const all = [
    ChildAgeGroup('0–6 Mo', 'Voller Milchbedarf', 780),
    ChildAgeGroup('6–12 Mo', 'Mit Beikost', 575),
    ChildAgeGroup('12+ Mo', 'Erweiterte Stillzeit', 300),
  ];
}
