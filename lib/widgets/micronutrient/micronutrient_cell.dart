import 'package:flutter/material.dart';

import '../../models/meal_entry.dart';
import '../../models/user_profile_settings.dart';
import '../../services/micronutrient_targets.dart';
import 'micronutrient_donut.dart';

// One nutrient column: donut + name + value. The whole cell is one tap
// target ≥44pt that opens the detail modal (modal wired in a follow-up
// commit — for now the tap callback is exposed so the parent decides).
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
      // Nutrient not known to the targets table — defensively skip
      // rendering rather than throw.
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
    final isOver = state == MicronutrientState.over;
    final isEmpty = state == MicronutrientState.empty;
    final isAwareness = state == MicronutrientState.awareness;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      // Padding pads the tap target out to 44pt+ even though the visible
      // donut is 44 — total min height with labels is well above HIG.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MicronutrientDonut(
              state: state,
              percent: pct,
              hasSupplement: hasSupplement,
            ),
            const SizedBox(height: 4),
            // Name line — italic for awareness, leaf for diet-adapted, info
            // glyph for awareness. " · über UL" suffix only for the over
            // state (rare, iron-only in practice).
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOver ? '$name · über UL' : name,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: isEmpty ? scheme.onSurfaceVariant : scheme.onSurface,
                    fontStyle:
                        isAwareness ? FontStyle.italic : FontStyle.normal,
                    height: 1.1,
                  ),
                ),
                if (dietAdapted) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.eco_outlined,
                    size: 12,
                    color: scheme.primary,
                  ),
                ],
                if (isAwareness) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.info_outline,
                    size: 11,
                    color: scheme.outline,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 1),
            // Value line — tabular-nums so the digits line up across
            // cells. Color shifts to tertiary only for the over state.
            Text(
              '${_formatIntake(intake, target.value)} / ${_formatTarget(target.value)} ${target.unitLabel}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isOver ? scheme.tertiary : scheme.outline,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display formatting for the intake — avoids "12.0" / "12.5"
  // inconsistency by rounding to whole when the target is in whole-
  // number territory, one decimal otherwise. The 0-state always shows
  // "0" (not "0.0").
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

// Resolves whether to render the supplement "+" badge for [nutrientKey]
// given the user's active supplement. True when the supplement actually
// contributes a value for this nutrient (non-zero, non-absent).
bool nutrientHasSupplementContribution(
    String nutrientKey, UserProfileSettings profile) {
  final v = profile.activeSupplement?.values[nutrientKey];
  return v != null && v > 0;
}

// Aggregate a day's meals into per-nutrient totals plus the active
// supplement contribution. Returns total intake for [nutrientKey] —
// the value the donut + cell render against the target.
double dailyIntakeFor(
    String nutrientKey, Iterable<MealEntry> meals, UserProfileSettings profile) {
  final mealsSum = meals.fold<double>(0, (sum, m) {
    final v = m.micronutrients?[nutrientKey];
    return sum + (v ?? 0);
  });
  final supplementSum = profile.activeSupplement?.values[nutrientKey] ?? 0;
  return mealsSum + supplementSum;
}
