import 'package:flutter/material.dart';

import '../../models/meal_entry.dart';
import '../../models/user_profile_settings.dart';
import '../../services/micronutrient_targets.dart';
import 'micronutrient_donut.dart';

// Compact bar-style cell for the strip. Two lines: name + percent row
// on top, a thin horizontal progress bar with the absolute value line
// underneath. Matches the visual language of the existing
// KcalSummary toolbar (also a linear progress + value pattern) so the
// two sit cleanly stacked at the top of the diary without competing
// for visual weight.
//
// Total cell height ~32px (vs. the donut variant's ~80px) — was a
// direct response to beta feedback that the donut strip ate too much
// screen real estate, especially with the keyboard open.
//
// The full donut treatment lives in MicronutrientDonut; it stays
// available for the detail modal (where a single large donut at 48px
// fits the modal's hero area).
class MicronutrientCell extends StatelessWidget {
  final String nutrientKey; // matches MicronutrientKey
  final double intake;
  final UserProfileSettings profile;
  final String locale;
  final bool hasSupplement;
  final bool dietAdapted; // leaf glyph next to name
  final VoidCallback? onTap;

  const MicronutrientCell({
    super.key,
    required this.nutrientKey,
    required this.intake,
    required this.profile,
    required this.locale,
    this.hasSupplement = false,
    this.dietAdapted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = MicronutrientDisplay.forKey(nutrientKey);
    final target = MicronutrientTargets.forKey(nutrientKey, profile);
    if (display == null || target == null) {
      return const SizedBox.shrink();
    }
    final pct = target.value > 0 ? (intake / target.value) * 100 : 0.0;
    final state = micronutrientStateFor(
      intake: intake,
      target: target.value,
      awareness: display.awareness,
      hasUpperLimit: display.hasUpperLimit,
    );
    final name = display.nameForLocale(locale);

    final isAwareness = state == MicronutrientState.awareness;
    final isMet = state == MicronutrientState.met;
    final isOver = state == MicronutrientState.over;

    // Bar fill color follows state, not nutrient — single accent rule.
    final fillColor = isOver
        ? scheme.tertiary
        : isMet
            ? scheme.primary
            : scheme.secondary;
    // Percent text color matches the fill so the eye reads name → bar
    // → value as one unit.
    final pctColor = isOver
        ? scheme.tertiary
        : isMet
            ? scheme.primary
            : scheme.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name (with markers) + percent on the right.
            Row(
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: scheme.onSurface,
                            fontStyle: isAwareness
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (dietAdapted) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.eco_outlined,
                            size: 11, color: scheme.primary),
                      ],
                      if (hasSupplement) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.add_circle,
                            size: 10, color: scheme.secondary),
                      ],
                      if (isAwareness) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.info_outline,
                            size: 10, color: scheme.outline),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (isMet)
                  Icon(Icons.check, size: 13, color: pctColor, weight: 700)
                else
                  Text(
                    '${pct.round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pctColor,
                      fontStyle:
                          isAwareness ? FontStyle.italic : FontStyle.normal,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Progress bar — visually consistent with the kcal toolbar's
            // LinearProgressIndicator. For awareness nutrients the bar
            // gets a dashed background hint via reduced opacity to keep
            // the "no hard target" cue without being too noisy.
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: isAwareness
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
            const SizedBox(height: 2),
            // Value line — tabular-nums so digits align across cells.
            Text(
              '${_formatIntake(intake, target.value)} / ${_formatTarget(target.value)} ${target.unitLabel}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: scheme.outline,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatIntake(double intake, double target) {
    if (intake == 0) return '0';
    if (target >= 50) return intake.round().toString();
    if (intake >= 10) return intake.toStringAsFixed(0);
    return intake.toStringAsFixed(1);
  }

  String _formatTarget(double target) {
    if (target >= 50) return target.round().toString();
    if (target == target.roundToDouble()) return target.toStringAsFixed(0);
    return target.toStringAsFixed(1);
  }
}

bool nutrientHasSupplementContribution(
    String nutrientKey, UserProfileSettings profile) {
  final v = profile.activeSupplement?.values[nutrientKey];
  return v != null && v > 0;
}

double dailyIntakeFor(
    String nutrientKey, Iterable<MealEntry> meals, UserProfileSettings profile) {
  final mealsSum = meals.fold<double>(0, (sum, m) {
    final v = m.micronutrients?[nutrientKey];
    return sum + (v ?? 0);
  });
  final supplementSum = profile.activeSupplement?.values[nutrientKey] ?? 0;
  return mealsSum + supplementSum;
}
