import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/meal_providers.dart';
import '../../services/micronutrient_targets.dart';
import 'micronutrient_cell.dart';

// Always-visible daily micronutrient strip — phase caption + 2-3 donut
// cells. Sits between the kcal toolbar (pinned above) and today's first
// meal in the diary; rendered as a SliverToBoxAdapter from
// home_screen's diary builder.
//
// Renders nothing (zero height) when:
//   - the user is in the "neither pregnant nor lactating" phase
//   - or no nutrients are configured / enabled in the profile
// — per the design contract: the strip MUST disappear entirely when
// disabled, not show a placeholder.
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
    final isDe = locale.toLowerCase().startsWith('de');
    final caption =
        isDe ? MicronutrientDefaults.captionDe(profile) : MicronutrientDefaults.captionEn(profile);
    final hasCaption = caption.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: hasCaption ? 7 : 8,
          left: 16,
          right: 16,
          bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasCaption) ...[
              Text(
                caption,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.08,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final key in keys)
                  Flexible(
                    child: MicronutrientCell(
                      nutrientKey: key,
                      intake: dailyIntakeFor(key, meals, profile),
                      profile: profile,
                      locale: locale,
                      hasSupplement:
                          nutrientHasSupplementContribution(key, profile),
                      dietAdapted:
                          MicronutrientDefaults.isDietAdaptedSlot(key, profile),
                      onTap: onCellTap == null ? null : () => onCellTap!(key),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
