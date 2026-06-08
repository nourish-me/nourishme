import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/meal_entry.dart';
import '../../providers/meal_providers.dart';
import '../../services/calorie_target.dart';
import '../../theme/nourishme_colors.dart';
import 'nutrition_header.dart' show sweetSpotStatusFor, SweetSpotStatus;

// Bottom sheet shown when the user taps a macro (or kcal) cell in the
// NutritionHeader. Deliberately lighter than the micro modal — macros
// have no DGE/EFSA disagreement to surface, no milk-dependent split, no
// awareness rule. Just: anchor on the day's target with a sweet-spot
// note, then show which meals contributed.

enum MacroKey { kcal, protein, carbs, fat }

void showMacroDetailModal(BuildContext context, MacroKey key) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _MacroDetailSheet(macro: key),
  );
}

class _MacroDetailSheet extends ConsumerWidget {
  final MacroKey macro;
  const _MacroDetailSheet({required this.macro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final meals = ref.watch(todayMealsProvider);
    final targetKcal = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);

    final intake = _intakeFor(macro, meals);
    final target = _targetFor(macro, targetKcal, macroTargets);
    final unit = _unitFor(macro);
    final name = _nameFor(macro, l10n);
    final pct = target > 0 ? (intake / target) * 100 : 0.0;
    final status = sweetSpotStatusFor(intake.toDouble(), target.toDouble());
    final accent = _accentFor(status, scheme);
    final remaining = target - intake;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero: donut + name + values. SF Pro semibold for the title
            // (Newsreader italic gets unwieldy on long words like
            // "Kohlenhydrate"; reserve the serif for narrative copy).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroDonut(percent: pct, color: accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$intake / $target $unit',
                        style: textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        remaining > 0
                            ? l10n.macroDetailRemaining(
                                remaining.toString(), unit)
                            : remaining == 0
                                ? l10n.macroDetailMet
                                : l10n.macroDetailOver(
                                    (-remaining).toString(), unit),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sweet-spot note (tone calm, never scolding).
            _SweetSpotNote(
              status: status,
              macro: macro,
              target: target,
              unit: unit,
            ),
            const SizedBox(height: 24),
            // Breakdown of today's contributing meals.
            Text(
              l10n.nutritionDetailContributions,
              style: textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.08,
                color: scheme.outline,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            _Breakdown(
              macro: macro,
              meals: meals,
              target: target,
              accent: accent,
              unit: unit,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.nutritionDetailClose),
            ),
          ],
        ),
      ),
    );
  }

  num _intakeFor(MacroKey k, List<MealEntry> meals) {
    switch (k) {
      case MacroKey.kcal:
        return meals.fold<int>(0, (s, m) => s + m.kcal);
      case MacroKey.protein:
        return meals.fold<double>(0, (s, m) => s + m.proteinG).round();
      case MacroKey.carbs:
        return meals.fold<double>(0, (s, m) => s + m.carbsG).round();
      case MacroKey.fat:
        return meals.fold<double>(0, (s, m) => s + m.fatG).round();
    }
  }

  num _targetFor(MacroKey k, int kcal, MacroTargets m) {
    switch (k) {
      case MacroKey.kcal:
        return kcal;
      case MacroKey.protein:
        return m.proteinG;
      case MacroKey.carbs:
        return m.carbsG;
      case MacroKey.fat:
        return m.fatG;
    }
  }

  String _unitFor(MacroKey k) => k == MacroKey.kcal ? 'kcal' : 'g';

  String _nameFor(MacroKey k, AppLocalizations l10n) {
    switch (k) {
      case MacroKey.kcal:
        return l10n.macroDetailKcalName;
      case MacroKey.protein:
        return l10n.macroDetailProteinName;
      case MacroKey.carbs:
        return l10n.macroDetailCarbsName;
      case MacroKey.fat:
        return l10n.macroDetailFatName;
    }
  }

  Color _accentFor(SweetSpotStatus s, ColorScheme scheme) {
    switch (s) {
      case SweetSpotStatus.over:
        return scheme.secondary;
      case SweetSpotStatus.sweet:
        return NMColors.moss;
      case SweetSpotStatus.neutral:
        return scheme.onSurface;
    }
  }
}

class _HeroDonut extends StatelessWidget {
  final double percent;
  final Color color;
  const _HeroDonut({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              strokeWidth: 5,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SweetSpotNote extends StatelessWidget {
  final SweetSpotStatus status;
  final MacroKey macro;
  final num target;
  final String unit;
  const _SweetSpotNote({
    required this.status,
    required this.macro,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final (text, dotColor) = _noteFor(scheme, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _noteFor(ColorScheme scheme, AppLocalizations l10n) {
    final macroName = switch (macro) {
      MacroKey.kcal => l10n.macroDetailKcalName,
      MacroKey.protein => l10n.macroDetailProteinName,
      MacroKey.carbs => l10n.macroDetailCarbsName,
      MacroKey.fat => l10n.macroDetailFatName,
    };
    final targetStr = target.toString();
    switch (status) {
      case SweetSpotStatus.sweet:
        return (
          l10n.macroDetailSweetNote(targetStr, unit),
          NMColors.moss,
        );
      case SweetSpotStatus.over:
        return (
          l10n.macroDetailOverNote(macroName),
          scheme.secondary,
        );
      case SweetSpotStatus.neutral:
        return (
          l10n.macroDetailNeutralNote(targetStr, unit),
          scheme.outline,
        );
    }
  }
}

class _Breakdown extends StatelessWidget {
  final MacroKey macro;
  final List<MealEntry> meals;
  final num target;
  final Color accent;
  final String unit;
  const _Breakdown({
    required this.macro,
    required this.meals,
    required this.target,
    required this.accent,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final rows = meals
        .map((m) {
          final value = switch (macro) {
            MacroKey.kcal => m.kcal.toDouble(),
            MacroKey.protein => m.proteinG,
            MacroKey.carbs => m.carbsG,
            MacroKey.fat => m.fatG,
          };
          return (m, value);
        })
        .where((e) => e.$2 > 0)
        .toList();
    if (rows.isEmpty) {
      return Text(
        l10n.nutritionDetailNoContributions,
        style: textTheme.bodySmall?.copyWith(color: scheme.outline),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (meal, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        meal.summary,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (value / target).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${value.round()} $unit',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
