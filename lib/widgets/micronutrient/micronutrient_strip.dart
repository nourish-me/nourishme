import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/meal_providers.dart';
import '../../services/micronutrient_targets.dart';
import 'micronutrient_cell.dart';

// Always-visible daily micronutrient strip. Sits between the kcal
// toolbar (pinned above) and the scrolling diary. Auto-hides for
// neither-phase users.
//
// Compact bar-style cells (~32px each, total strip ~44px) — the
// donut variant tested too tall against the keyboard. Phase caption
// removed: testers know whether they're pregnant or lactating; the
// app still uses the phase internally to pick the right top-3.
//
// Renders nothing (zero height) when:
//   - profile is in the "neither pregnant nor lactating" phase
//   - no nutrients resolve from the defaults
class MicronutrientStrip extends ConsumerWidget {
  final String locale;
  final ValueChanged<String>? onCellTap;

  const MicronutrientStrip({
    super.key,
    required this.locale,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();

    final keys = MicronutrientDefaults.forProfile(profile);
    if (keys.isEmpty) return const SizedBox.shrink();

    final meals = ref.watch(todayMealsProvider);
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: MicronutrientCell(
                  nutrientKey: keys[i],
                  intake: dailyIntakeFor(keys[i], meals, profile),
                  profile: profile,
                  locale: locale,
                  hasSupplement:
                      nutrientHasSupplementContribution(keys[i], profile),
                  dietAdapted: MicronutrientDefaults.isDietAdaptedSlot(
                      keys[i], profile),
                  onTap: onCellTap == null ? null : () => onCellTap!(keys[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
