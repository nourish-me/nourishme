class UserProfileSettings {
  // Birth date is the source of truth (age changes as time passes).
  // ageYears stays in the model for backward compat with older Hive entries:
  // when birthdate is null we fall back to it.
  final DateTime? birthdate;
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
    this.birthdate,
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

  // Age in completed years, computed from birthdate if available, otherwise
  // falling back to the stored ageYears for old profiles.
  int get currentAge {
    if (birthdate == null) return ageYears;
    final now = DateTime.now();
    var age = now.year - birthdate!.year;
    final beforeBirthday =
        now.month < birthdate!.month ||
            (now.month == birthdate!.month && now.day < birthdate!.day);
    if (beforeBirthday) age--;
    return age;
  }

  // Helper for the inverse: derive a plausible January-1 birthdate from a
  // legacy ageYears value (used once, when the user updates an old profile).
  static DateTime birthdateFromAge(int age) =>
      DateTime(DateTime.now().year - age, 1, 1);

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
    DateTime? birthdate,
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
        birthdate: birthdate ?? this.birthdate,
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
        'birthdate': birthdate?.toIso8601String(),
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
    final birthdateRaw = json['birthdate'] as String?;
    return UserProfileSettings(
      ageYears: json['ageYears'] as int,
      birthdate: birthdateRaw != null ? DateTime.tryParse(birthdateRaw) : null,
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

// Activity level + age-group labels live as static `factors` lists for the
// math/IDs and as l10n-aware `_LabelsFor` lookups so the UI strings flip
// language with the app. The numeric tables stay const.

class ActivityLevel {
  final String label;
  final String hint;
  final double factor;
  const ActivityLevel(this.label, this.hint, this.factor);

  // Numeric PAL factors in display order. The labels come from l10n.
  static const factors = <double>[1.2, 1.375, 1.55, 1.725];

  static List<ActivityLevel> allFor(ActivityLabels labels) => [
        ActivityLevel(labels.low, labels.lowHint, factors[0]),
        ActivityLevel(labels.moderate, labels.moderateHint, factors[1]),
        ActivityLevel(labels.active, labels.activeHint, factors[2]),
        ActivityLevel(labels.high, labels.highHint, factors[3]),
      ];

  static ActivityLevel closestTo(double f, ActivityLabels labels) =>
      allFor(labels).reduce(
          (a, b) => (a.factor - f).abs() < (b.factor - f).abs() ? a : b);
}

// Lightweight value type so model code doesn't need to import the generated
// AppLocalizations directly. The UI builds this from l10n once per
// build-tree and passes it in.
class ActivityLabels {
  final String low, lowHint;
  final String moderate, moderateHint;
  final String active, activeHint;
  final String high, highHint;
  const ActivityLabels({
    required this.low,
    required this.lowHint,
    required this.moderate,
    required this.moderateHint,
    required this.active,
    required this.activeHint,
    required this.high,
    required this.highHint,
  });
}

class ChildAgeGroup {
  final String label;
  final String hint;
  final int typicalMlPerChild;
  const ChildAgeGroup(this.label, this.hint, this.typicalMlPerChild);

  // ML/day per child, same order as the labels below.
  static const typicalMls = <int>[780, 575, 300];

  static List<ChildAgeGroup> allFor(ChildAgeLabels labels) => [
        ChildAgeGroup(labels.zeroToSix, labels.zeroToSixHint, typicalMls[0]),
        ChildAgeGroup(labels.sixToTwelve, labels.sixToTwelveHint, typicalMls[1]),
        ChildAgeGroup(labels.twelvePlus, labels.twelvePlusHint, typicalMls[2]),
      ];
}

class ChildAgeLabels {
  final String zeroToSix, zeroToSixHint;
  final String sixToTwelve, sixToTwelveHint;
  final String twelvePlus, twelvePlusHint;
  const ChildAgeLabels({
    required this.zeroToSix,
    required this.zeroToSixHint,
    required this.sixToTwelve,
    required this.sixToTwelveHint,
    required this.twelvePlus,
    required this.twelvePlusHint,
  });
}
