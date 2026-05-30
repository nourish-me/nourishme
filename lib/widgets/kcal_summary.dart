import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/calorie_target.dart';
import '../theme/nourishme_colors.dart';
import '../utils/number_format.dart';

// Shared kcal/macros summary used in both the Tagebuch toolbar and the
// Verlauf day card. Keeping the layout identical across screens so the user
// doesn't have to re-parse the numbers in two different formats.
//
// Color coding rule (per metric): 80-110% of target = green sweet spot,
// over 110% = orange, otherwise neutral. Same logic for kcal and all three
// macros so the visual cue is consistent.
class KcalSummary extends StatelessWidget {
  final int totalKcal;
  final int targetKcal;
  final double protein;
  final double carbs;
  final double fat;
  final MacroTargets macroTargets;
  final bool showProgress;

  const KcalSummary({
    super.key,
    required this.totalKcal,
    required this.targetKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.macroTargets,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final remaining = targetKcal - totalKcal;
    final progress = targetKcal > 0
        ? (totalKcal / targetKcal).clamp(0.0, 1.0)
        : 0.0;
    final kcalStatus = _statusFor(totalKcal.toDouble(), targetKcal.toDouble());
    final kcalColor = _colorFor(kcalStatus, scheme);
    final progressColor = kcalStatus == _MetricStatus.over
        ? NMColors.amber
        : kcalStatus == _MetricStatus.green
            ? NMColors.moss
            : scheme.primary;
    final remainingText = remaining > 0
        ? l10n.kcalRemainingPositive(formatKcal(remaining))
        : remaining == 0
            ? l10n.kcalRemainingZero
            : l10n.kcalRemainingNegative(formatKcal(-remaining));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.kcalCombined(
                      formatKcal(totalKcal),
                      formatKcal(targetKcal),
                    ),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kcalColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remainingText,
                    style: textTheme.bodySmall?.copyWith(
                      color: kcalStatus == _MetricStatus.over
                          ? NMColors.amber
                          : scheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _MacrosColumn(
              protein: protein,
              carbs: carbs,
              fat: fat,
              targets: macroTargets,
              scheme: scheme,
              textTheme: textTheme,
              proteinLabel: l10n.macroLabelProtein,
              carbsLabel: l10n.macroLabelCarbs,
              fatLabel: l10n.macroLabelFat,
            ),
          ],
        ),
        if (showProgress) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: progressColor,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}

enum _MetricStatus { neutral, green, over }

_MetricStatus _statusFor(double current, double target) {
  if (target <= 0) return _MetricStatus.neutral;
  final ratio = current / target;
  // Strict: anything over the target turns orange. Sweet-spot 80–100 % green.
  // Anything below 80 % neutral. Same rule for kcal and all macros so the
  // colors stay consistent in the toolbar.
  if (ratio > 1.00) return _MetricStatus.over;
  if (ratio >= 0.80) return _MetricStatus.green;
  return _MetricStatus.neutral;
}

Color _colorFor(_MetricStatus status, ColorScheme scheme) {
  // Field Manual palette: moss for sweet spot, amber-warm for over target.
  switch (status) {
    case _MetricStatus.over:
      return NMColors.amber;
    case _MetricStatus.green:
      return NMColors.moss;
    case _MetricStatus.neutral:
      return scheme.onSurface;
  }
}

class _MacrosColumn extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final MacroTargets targets;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;

  const _MacrosColumn({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targets,
    required this.scheme,
    required this.textTheme,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _macroLine(proteinLabel, protein, targets.proteinG.toDouble()),
        _macroLine(carbsLabel, carbs, targets.carbsG.toDouble()),
        _macroLine(fatLabel, fat, targets.fatG.toDouble()),
      ],
    );
  }

  Widget _macroLine(String label, double grams, double target) {
    final status = _statusFor(grams, target);
    final color = _colorFor(status, scheme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          children: [
            TextSpan(text: '$label  '),
            // Current amount stays the visual anchor (coloured + bold);
            // target follows in muted text so the relationship reads as
            // "12 of 100 g" without competing with the live number.
            TextSpan(
              text: grams.toStringAsFixed(0),
              style: textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (target > 0)
              TextSpan(text: ' / ${target.toStringAsFixed(0)} g')
            else
              const TextSpan(text: ' g'),
          ],
        ),
      ),
    );
  }
}
