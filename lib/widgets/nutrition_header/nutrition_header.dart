import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_profile_settings.dart';
import '../../providers/meal_providers.dart';
import '../../services/calorie_target.dart';
import '../../services/micronutrient_targets.dart';
import '../../theme/nourishme_colors.dart';
import '../../utils/number_format.dart';
import '../micronutrient/micronutrient_donut.dart' show
    MicronutrientState,
    micronutrientStateFor;
import 'mini_pct_cell.dart';

// Unified nutrition header — replaces the old standalone KcalSummary
// toolbar in the Tagebuch AppBar bottom. Three tiers in one ~58px band:
//
//   1. kcal headline + 3px progress bar (intake colored by sweet-spot
//      rule, bar fill in pine)
//   2. Macros (Protein / Kohlenh. / Fett) as MiniPctCells, colored by
//      the sweet-spot corridor rule (under 80% neutral, 80-110% moss,
//      over 110% amber)
//   3. Hairline + Micros (2-3 phase-default nutrients) as MiniPctCells,
//      colored by the state rule (progress amber / met pine / over
//      plum / awareness italic dashed)
//
// Macros + micros share the same MiniPctCell shape so they read as one
// "% of today" system. Per the Variant E design handoff (v2).
//
// Tap any cell → opens a detail modal (wired in a follow-up commit;
// callbacks exposed now).
//
// The micros tier auto-hides when MicronutrientDefaults.forProfile
// returns nothing (i.e. neither-phase users) — header still shows kcal
// + macros, just shorter.
class NutritionHeader extends ConsumerWidget {
  final ValueChanged<String>? onMacroTap; // 'protein' | 'carbs' | 'fat' | 'kcal'
  final ValueChanged<String>? onMicroTap; // MicronutrientKey

  const NutritionHeader({super.key, this.onMacroTap, this.onMicroTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    final meals = ref.watch(todayMealsProvider);
    final targetKcal = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull ??
        UserProfileSettings.defaults();

    final totalKcal = meals.fold<int>(0, (s, m) => s + m.kcal);
    final totalProtein =
        meals.fold<double>(0, (s, m) => s + m.proteinG);
    final totalCarbs = meals.fold<double>(0, (s, m) => s + m.carbsG);
    final totalFat = meals.fold<double>(0, (s, m) => s + m.fatG);

    // User-picked list wins; otherwise fall back to the phase/diet default.
    // An explicit empty list (user opted out of all micros) hides the strip.
    final microKeys =
        profile.selectedMicronutrients ?? MicronutrientDefaults.forProfile(profile);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KcalTier(
              totalKcal: totalKcal,
              targetKcal: targetKcal,
              l10n: l10n,
              onTap: onMacroTap == null ? null : () => onMacroTap!('kcal'),
            ),
            const SizedBox(height: 7),
            _MacrosRow(
              protein: totalProtein,
              carbs: totalCarbs,
              fat: totalFat,
              targets: macroTargets,
              l10n: l10n,
              onMacroTap: onMacroTap,
            ),
            if (microKeys.isNotEmpty) ...[
              const SizedBox(height: 7),
              Divider(
                height: 0.5,
                thickness: 0.5,
                color: scheme.outlineVariant,
              ),
              const SizedBox(height: 7),
              _MicrosRow(
                keys: microKeys,
                meals: meals,
                profile: profile,
                locale: locale,
                onMicroTap: onMicroTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Tier 1: kcal headline + inline progress bar ------------------------------

class _KcalTier extends StatelessWidget {
  final int totalKcal;
  final int targetKcal;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _KcalTier({
    required this.totalKcal,
    required this.targetKcal,
    required this.l10n,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = targetKcal > 0 ? (totalKcal / targetKcal) * 100 : 0.0;
    final status = sweetSpotStatusFor(totalKcal.toDouble(), targetKcal.toDouble());
    final intakeColor = sweetSpotColorFor(status, scheme);
    // Target-preview mode for the empty state: instead of "0 / 2.100 kcal
    // · 0%" (which reads cold and "sad"), the headline shows the day's
    // goal as the anchor. The bar stays at 0% so the progress meaning
    // is unchanged; only the label content shifts.
    final isEmpty = totalKcal == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          children: [
            // Headline text — intake colored by corridor, rest muted. In
            // empty state, swap to "{target} kcal Ziel" so the day reads
            // as a target rather than a deficit.
            RichText(
              text: isEmpty
                  ? TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(
                          text: formatKcal(targetKcal),
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const TextSpan(text: ' kcal Ziel'),
                      ],
                    )
                  : TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.outline,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(
                          text: formatKcal(totalKcal),
                          style: TextStyle(
                            color: intakeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        TextSpan(text: ' / ${formatKcal(targetKcal)} kcal · '),
                        TextSpan(
                          text: '${pct.round()}%',
                          style: TextStyle(
                            color: intakeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 10),
            // Inline progress bar — always primary (pine) fill regardless
            // of corridor; the corridor signal lives in the headline color.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tier 2: macros row -------------------------------------------------------

class _MacrosRow extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final MacroTargets targets;
  final AppLocalizations l10n;
  final ValueChanged<String>? onMacroTap;

  const _MacrosRow({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targets,
    required this.l10n,
    this.onMacroTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _macroCell(context, l10n.nutritionMacroProtein, protein,
              targets.proteinG.toDouble(), 'protein'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroCell(context, l10n.nutritionMacroCarbs, carbs,
              targets.carbsG.toDouble(), 'carbs'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroCell(context, l10n.nutritionMacroFat, fat,
              targets.fatG.toDouble(), 'fat'),
        ),
      ],
    );
  }

  Widget _macroCell(BuildContext context, String name, double grams,
      double target, String tapKey) {
    final scheme = Theme.of(context).colorScheme;
    final pct = target > 0 ? (grams / target) * 100 : 0.0;
    final status = sweetSpotStatusFor(grams, target);
    final color = sweetSpotColorFor(status, scheme);
    // Empty-state target preview: when nothing's logged yet for this
    // macro, swap the "0%" pct text for the day's target ("95 g") so
    // the cell anchors on the goal instead of the deficit.
    final isEmpty = grams == 0;
    return MiniPctCell(
      name: name,
      percent: pct,
      color: color,
      pctOverridesText: isEmpty
          ? Text(
              '${target.round()} g',
              style: TextStyle(
                // Match the name + pct fontSize (11.5) so the Row's
                // center-alignment keeps all three columns of preview
                // text on the same visual baseline.
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          : null,
      onTap: onMacroTap == null ? null : () => onMacroTap!(tapKey),
    );
  }
}

// --- Tier 3: micros row -------------------------------------------------------

class _MicrosRow extends StatelessWidget {
  final List<String> keys; // MicronutrientKey list
  final Iterable<dynamic> meals; // MealEntry, but typed loosely to avoid extra import
  final UserProfileSettings profile;
  final String locale;
  final ValueChanged<String>? onMicroTap;

  const _MicrosRow({
    required this.keys,
    required this.meals,
    required this.profile,
    required this.locale,
    this.onMicroTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: _microCell(context, keys[i])),
        ],
      ],
    );
  }

  Widget _microCell(BuildContext context, String key) {
    final scheme = Theme.of(context).colorScheme;
    final display = MicronutrientDisplay.forKey(key);
    final target = MicronutrientTargets.forKey(key, profile);
    if (display == null || target == null) return const SizedBox.shrink();
    final intake = dailyIntakeFor(key, meals.cast(), profile);
    final pct = target.value > 0 ? (intake / target.value) * 100 : 0.0;
    final state = micronutrientStateFor(
      intake: intake,
      target: target.value,
      awareness: display.awareness,
      hasUpperLimit: display.hasUpperLimit,
    );
    final color = _microColor(state, scheme);
    final isMet = state == MicronutrientState.met;
    final isOver = state == MicronutrientState.over;
    final isAwareness = state == MicronutrientState.awareness;
    final isEmpty = state == MicronutrientState.empty;
    // Empty-state target preview: same logic as macros — show the
    // day's reference value (e.g. "230 µg") instead of "0%" so the
    // cell anchors on the goal. Awareness nutrients keep the italic
    // treatment in the preview too.
    Widget? overrideText;
    if (isMet) {
      overrideText = Icon(Icons.check, size: 14, color: color, weight: 700);
    } else if (isEmpty) {
      overrideText = Text(
        '${_formatTargetValue(target.value)} ${target.unitLabel}',
        style: TextStyle(
          // Match the name + pct fontSize (11.5) — see _macroCell note.
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          fontStyle: isAwareness ? FontStyle.italic : FontStyle.normal,
          height: 1.1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }
    return MiniPctCell(
      name: isOver ? '${display.nameForLocale(locale)} · UL' : display.nameForLocale(locale),
      percent: pct,
      color: color,
      italic: isAwareness,
      dashedTrack: isAwareness,
      pctOverridesText: overrideText,
      nameTrailing: [
        // Diet-adapted glyph only meaningful when the slot was chosen by
        // the default rule (vegan/vegetarian B12 swap). Once the user
        // hand-picks micros, the glyph is misleading — suppress it.
        if (profile.selectedMicronutrients == null &&
            MicronutrientDefaults.isDietAdaptedSlot(key, profile))
          Icon(Icons.eco_outlined, size: 11, color: scheme.primary),
        if (nutrientHasSupplementContribution(key, profile))
          Icon(Icons.add, size: 10, color: scheme.secondary),
        if (isAwareness)
          Icon(Icons.info_outline, size: 10, color: scheme.outline),
      ],
      onTap: onMicroTap == null ? null : () => onMicroTap!(key),
    );
  }

  // Same rule as MicronutrientCell used previously: integer when ≥50,
  // otherwise let the source decide (most micronutrient targets are
  // whole numbers anyway).
  String _formatTargetValue(double target) {
    if (target >= 50) return target.round().toString();
    if (target == target.roundToDouble()) return target.toStringAsFixed(0);
    return target.toStringAsFixed(1);
  }

  Color _microColor(MicronutrientState state, ColorScheme scheme) {
    switch (state) {
      case MicronutrientState.empty:
        return scheme.outline;
      case MicronutrientState.progress:
      case MicronutrientState.awareness:
        return scheme.secondary;
      case MicronutrientState.met:
        return scheme.primary;
      case MicronutrientState.over:
        return scheme.tertiary;
    }
  }
}

// --- Macro sweet-spot color rule ---------------------------------------------

enum SweetSpotStatus { neutral, sweet, over }

SweetSpotStatus sweetSpotStatusFor(double current, double target) {
  if (target <= 0) return SweetSpotStatus.neutral;
  final ratio = current / target;
  if (ratio > 1.10) return SweetSpotStatus.over;
  if (ratio >= 0.80) return SweetSpotStatus.sweet;
  return SweetSpotStatus.neutral;
}

Color sweetSpotColorFor(SweetSpotStatus status, ColorScheme scheme) {
  switch (status) {
    case SweetSpotStatus.over:
      return scheme.secondary; // amber (gentle "over" caution)
    case SweetSpotStatus.sweet:
      return NMColors.moss; // sweet-spot green
    case SweetSpotStatus.neutral:
      return scheme.onSurface; // still building
  }
}
