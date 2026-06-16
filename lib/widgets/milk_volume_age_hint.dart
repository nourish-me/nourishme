import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// Helper widget shown under the daily-milk-volume slider in onboarding +
// settings (Task #103 - beta tester T3 said "I have no idea how much he
// actually eats"). Lists the four typical volume bands by child age and
// number of children, with the matching line highlighted so the user
// gets a concrete anchor before nudging the slider.
//
// Age buckets follow the existing convention in calorie_target.dart:
//   0 = 0-6 mo (exclusive breastfeeding window)
//   1 = 6-12 mo (with solids)
//   2 = 12+ mo (mostly family food)
//
// Twins-exclusive row only highlights when numChildren > 1 AND ageGroup
// is 0; otherwise it stays as a passive reference line.
class MilkVolumeAgeHint extends StatelessWidget {
  final int ageGroup;
  final int numChildren;
  const MilkVolumeAgeHint({
    super.key,
    required this.ageGroup,
    required this.numChildren,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isTwinsExclusive = numChildren > 1 && ageGroup == 0;
    bool active(int bucket) => !isTwinsExclusive && ageGroup == bucket;

    Widget row(String label, bool isActive) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '• $label',
            style: textTheme.bodySmall?.copyWith(
              color: isActive ? scheme.primary : scheme.outline,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsMilkVolumeAgeRulesTitle,
            style: textTheme.bodySmall
                ?.copyWith(color: scheme.outline, fontWeight: FontWeight.w500),
          ),
          row(l10n.settingsMilkVolumeAgeRule0to6, active(0)),
          row(l10n.settingsMilkVolumeAgeRule6to12, active(1)),
          row(l10n.settingsMilkVolumeAgeRule12plus, active(2)),
          row(l10n.settingsMilkVolumeAgeRuleTwins, isTwinsExclusive),
        ],
      ),
    );
  }
}
