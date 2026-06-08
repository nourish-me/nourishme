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

  // Diet style + allergy/intolerance markers shared with the coach so it
  // doesn't suggest off-limit food. dietStyle is one of the values in
  // [DietStyle] (omnivore | vegetarian | vegan | pescatarian). restrictions
  // is a set of canonical avoid-tags (see [DietRestrictions]). dietaryNotes
  // captures anything that doesn't fit the chip list (e.g. "no spicy
  // food", "histamine intolerance", "stomach can't handle dairy").
  final String dietStyle;
  final Set<String> restrictions;
  final String dietaryNotes;

  // Daily supplement (e.g. prenatal multivitamin). Photographed once by
  // the user; Claude Vision parses the nutrient table into structured
  // values. Those values get added to every day's micronutrient totals
  // alongside dietary intake. Null when the user hasn't configured one.
  // v1 supports a single active supplement; multi-supplement is a
  // post-launch follow-up.
  final ActiveSupplement? activeSupplement;

  // User-picked list of MicronutrientKey strings to show in the diary
  // header. Null means "use the phase/diet default" (MicronutrientDefaults
  // .forProfile). When non-null the list takes precedence — even if empty
  // (user explicitly wants no micros). Capped to 3 entries by the Settings
  // UI; the model itself does not enforce the cap.
  final List<String>? selectedMicronutrients;

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
    this.dietStyle = DietStyle.omnivore,
    this.restrictions = const {},
    this.dietaryNotes = '',
    this.activeSupplement,
    this.selectedMicronutrients,
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
    String? dietStyle,
    Set<String>? restrictions,
    String? dietaryNotes,
    // copyWith for nullable fields uses a Object-typed sentinel so the
    // caller can distinguish "leave alone" from "explicitly clear to
    // null". Needed for activeSupplement so the "delete supplement"
    // action can pass `activeSupplement: null` and have it actually
    // null out the field instead of being interpreted as "keep
    // existing".
    Object? activeSupplement = _unset,
    Object? selectedMicronutrients = _unset,
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
        dietStyle: dietStyle ?? this.dietStyle,
        restrictions: restrictions ?? this.restrictions,
        dietaryNotes: dietaryNotes ?? this.dietaryNotes,
        activeSupplement: identical(activeSupplement, _unset)
            ? this.activeSupplement
            : activeSupplement as ActiveSupplement?,
        selectedMicronutrients: identical(selectedMicronutrients, _unset)
            ? this.selectedMicronutrients
            : selectedMicronutrients as List<String>?,
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
        'dietStyle': dietStyle,
        'restrictions': restrictions.toList(),
        'dietaryNotes': dietaryNotes,
        if (activeSupplement != null)
          'activeSupplement': activeSupplement!.toJson(),
        if (selectedMicronutrients != null)
          'selectedMicronutrients': selectedMicronutrients,
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
      dietStyle: json['dietStyle'] as String? ?? DietStyle.omnivore,
      restrictions: (json['restrictions'] as List?)
              ?.whereType<String>()
              .toSet() ??
          const {},
      dietaryNotes: json['dietaryNotes'] as String? ?? '',
      activeSupplement: (json['activeSupplement'] as Map<String, dynamic>?) != null
          ? ActiveSupplement.fromJson(
              json['activeSupplement'] as Map<String, dynamic>)
          : null,
      selectedMicronutrients: (json['selectedMicronutrients'] as List?)
          ?.whereType<String>()
          .toList(),
    );
  }
}

// Internal sentinel for nullable copyWith arguments. Allows the caller
// to pass an explicit null to clear the field versus omitting the arg
// to leave it alone. Kept private to this file because it leaks the
// API only here (other nullable fields default to "leave alone" via
// the `??` pattern, which doesn't need this).
const _unset = Object();

// User's currently configured daily supplement (one at a time in v1).
// Values are PER DAY (already multiplied by dosesPerDay at parse time
// so the daily-aggregation provider can just add them once).
//
// The unit-suffixed keys match MicronutrientKey, so the values plug
// straight into the per-meal aggregation map.
class ActiveSupplement {
  final String name; // e.g. 'Femibion 2', user-editable after parse
  final Map<String, double> values; // unit-suffixed nutrient keys → per-day amount
  final int dosesPerDay; // metadata only; values already account for it
  final DateTime addedAt; // for "added on X" display + cache eviction later

  const ActiveSupplement({
    required this.name,
    required this.values,
    required this.dosesPerDay,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'values': values,
        'dosesPerDay': dosesPerDay,
        'addedAt': addedAt.toIso8601String(),
      };

  factory ActiveSupplement.fromJson(Map<String, dynamic> json) =>
      ActiveSupplement(
        name: json['name'] as String,
        values: (json['values'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        dosesPerDay: json['dosesPerDay'] as int? ?? 1,
        addedAt:
            DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

// Canonical strings for the user's diet style. Stored in
// UserProfileSettings.dietStyle and threaded into the Coach prompts so
// suggestions match. Free-form alternatives go into dietaryNotes.
class DietStyle {
  static const omnivore = 'omnivore';
  static const vegetarian = 'vegetarian';
  static const vegan = 'vegan';
  static const pescatarian = 'pescatarian';

  static const all = [omnivore, vegetarian, vegan, pescatarian];
}

// Canonical avoid-tag IDs for the Settings restriction chips. Coach
// prompts treat these as hard avoids ("never suggest").
class DietRestrictions {
  static const lactose = 'lactose';
  static const gluten = 'gluten';
  static const eggs = 'eggs';
  static const nuts = 'nuts';
  static const fish = 'fish';
  static const shellfish = 'shellfish';
  static const soy = 'soy';

  static const all = [lactose, gluten, eggs, nuts, fish, shellfish, soy];
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
