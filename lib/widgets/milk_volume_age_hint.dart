import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// Compact hint shown under the daily-milk-volume slider in onboarding +
// settings. Shows ONLY the rule line that matches the user's current
// child-age + numChildren combination so the page doesn't drown in
// four parallel reference lines (Vanessa Build+29 feedback: "viel Info,
// erschlägt mich"). The full four-line table is one tap away behind
// the info icon.
//
// Age buckets follow the existing convention in calorie_target.dart:
//   0 = 0-6 mo (exclusive breastfeeding window)
//   1 = 6-12 mo (with solids)
//   2 = 12+ mo (mostly family food)
//
// Twins-exclusive line wins over the bucket line when both apply
// (numChildren > 1 AND ageGroup == 0) - twins at that age have a
// specific number that's different from the per-child default.
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
    final activeText = isTwinsExclusive
        ? l10n.settingsMilkVolumeAgeRuleTwins
        : (ageGroup == 0
            ? l10n.settingsMilkVolumeAgeRule0to6
            : (ageGroup == 1
                ? l10n.settingsMilkVolumeAgeRule6to12
                : l10n.settingsMilkVolumeAgeRule12plus));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              '${l10n.settingsMilkVolumeAgeRulesTitle}: $activeText',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.outline,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.info_outline, size: 18, color: scheme.outline),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: l10n.settingsMilkVolumeAgeRulesTitle,
            onPressed: () => _showAllRules(context, l10n, scheme, textTheme),
          ),
        ],
      ),
    );
  }

  void _showAllRules(BuildContext context, AppLocalizations l10n,
      ColorScheme scheme, TextTheme textTheme) {
    final isTwinsExclusive = numChildren > 1 && ageGroup == 0;
    bool active(int bucket) => !isTwinsExclusive && ageGroup == bucket;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsMilkVolumeAgeRulesTitle,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _row(textTheme, scheme, l10n.settingsMilkVolumeAgeRule0to6,
                  active(0)),
              _row(textTheme, scheme, l10n.settingsMilkVolumeAgeRule6to12,
                  active(1)),
              _row(textTheme, scheme, l10n.settingsMilkVolumeAgeRule12plus,
                  active(2)),
              _row(textTheme, scheme, l10n.settingsMilkVolumeAgeRuleTwins,
                  isTwinsExclusive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
          TextTheme textTheme, ColorScheme scheme, String label, bool isActive) =>
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '• $label',
          style: textTheme.bodyMedium?.copyWith(
            color: isActive ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            height: 1.4,
          ),
        ),
      );
}
