import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/meal_entry.dart';
import '../../models/user_profile_settings.dart';
import '../../providers/meal_providers.dart';
import '../../services/micronutrient_targets.dart';
import '../micronutrient/micronutrient_donut.dart'
    show MicronutrientState, micronutrientStateFor;

// Bottom sheet for tapped micronutrient cells. Carries the full
// per-design content: twin disclaimer when applicable, hero +
// intake/target/gap, awareness note for choline, breakdown of today's
// contributing meals, lactation framing (milk-dependent vs buffered),
// and the primary source label.
//
// Omitted from v1 (vs the full design): DGE-vs-EFSA disagreement table
// (we surface only the primary source - single row) and the LLM-
// generated suggestions list. Both are post-launch.

void showMicroDetailModal(BuildContext context, String nutrientKey) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _MicroDetailSheet(nutrientKey: nutrientKey),
  );
}

// Categorisation for the lactation "milk-dependent vs buffered" frame.
// Source: the Deep Research brief - milk content of these nutrients
// tracks maternal intake (so eating them reaches the baby), while the
// buffered set stays adequate in milk at the mother's own expense.
const _milkDependentKeys = {
  MicronutrientKey.iodineUg,
  MicronutrientKey.dhaMg,
  MicronutrientKey.b12Ug,
  MicronutrientKey.vitaminDUg,
  MicronutrientKey.cholineMg,
};
const _bufferedKeys = {
  MicronutrientKey.ironMg,
  MicronutrientKey.folateUg,
  MicronutrientKey.calciumMg,
  MicronutrientKey.zincMg,
};

class _MicroDetailSheet extends ConsumerWidget {
  final String nutrientKey;
  const _MicroDetailSheet({required this.nutrientKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final meals = ref.watch(todayMealsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull ??
        UserProfileSettings.defaults();

    final display = MicronutrientDisplay.forKey(nutrientKey);
    final target = MicronutrientTargets.forKey(nutrientKey, profile);
    if (display == null || target == null) {
      return const SizedBox.shrink();
    }

    final intake = dailyIntakeFor(nutrientKey, meals, profile);
    final pct = target.value > 0 ? (intake / target.value) * 100 : 0.0;
    final state = micronutrientStateFor(
      intake: intake,
      target: target.value,
      awareness: display.awareness,
      hasUpperLimit: display.hasUpperLimit,
    );
    final accent = _accentFor(state, scheme);
    final isAwareness = state == MicronutrientState.awareness;
    final isLactating = profile.numChildrenNursing > 0 && !profile.isPregnant;
    final isTwinPregnancy = profile.isPregnant && profile.numChildrenNursing >= 2;
    final isTwinNursing = profile.numChildrenNursing >= 2;
    final showTwinDisclaimer = isTwinPregnancy || isTwinNursing;
    final remaining = target.value - intake;
    final nutrientName = display.nameForLocale(locale);

    return SafeArea(
      child: SingleChildScrollView(
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
            if (showTwinDisclaimer) _TwinDisclaimer(),
            if (showTwinDisclaimer) const SizedBox(height: 16),
            // Hero. SF Pro semibold for the title (Newsreader italic gets
            // unwieldy on long names like "Kohlenhydrate"/"Pantothensäure";
            // reserve the serif for narrative copy).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroDonut(percent: pct, color: accent, dashed: isAwareness),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nutrientName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(intake)} / ${_fmt(target.value)} ${target.unitLabel}',
                        style: textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        remaining > 0
                            ? l10n.macroDetailRemaining(
                                _fmt(remaining), target.unitLabel)
                            : remaining == 0
                                ? l10n.macroDetailMet
                                : l10n.macroDetailOver(
                                    _fmt(-remaining), target.unitLabel),
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
            if (isAwareness) ...[
              _AwarenessNote(),
              const SizedBox(height: 20),
            ],
            if (isLactating) ...[
              _LactationFraming(
                nutrientKey: nutrientKey,
                nutrientName: nutrientName,
              ),
              const SizedBox(height: 20),
            ],
            // Breakdown
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
              nutrientKey: nutrientKey,
              nutrientName: nutrientName,
              meals: meals,
              target: target.value,
              unit: target.unitLabel,
              accent: accent,
            ),
            const SizedBox(height: 20),
            // Source & target - one row in v1 (DGE-vs-EFSA disagreement
            // table is post-launch).
            Text(
              l10n.microDetailSourceHeader,
              style: textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 0.08,
                color: scheme.outline,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            _SourceRow(
              source: target.source,
              value: '${_fmt(target.value)} ${target.unitLabel}',
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

  String _fmt(double v) {
    if (v >= 50) return v.round().toString();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  Color _accentFor(MicronutrientState s, ColorScheme scheme) {
    switch (s) {
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

class _TwinDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 16, color: scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.microDetailTwinDisclaimer,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AwarenessNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.microDetailAwarenessNote,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LactationFraming extends StatelessWidget {
  final String nutrientKey;
  final String nutrientName;
  const _LactationFraming({
    required this.nutrientKey,
    required this.nutrientName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final isMilkDependent = _milkDependentKeys.contains(nutrientKey);
    final isBuffered = _bufferedKeys.contains(nutrientKey);
    if (!isMilkDependent && !isBuffered) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMilkDependent ? Icons.water_drop_outlined : Icons.shield_outlined,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMilkDependent
                      ? l10n.microDetailMilkDependentTitle
                      : l10n.microDetailBufferedTitle,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMilkDependent
                      ? l10n.microDetailMilkDependentBody(nutrientName)
                      : l10n.microDetailBufferedBody(nutrientName),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  final String nutrientKey;
  final String nutrientName;
  final List<MealEntry> meals;
  final double target;
  final String unit;
  final Color accent;
  const _Breakdown({
    required this.nutrientKey,
    required this.nutrientName,
    required this.meals,
    required this.target,
    required this.unit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final rows = meals
        .map((m) => (m, m.micronutrients?[nutrientKey] ?? 0.0))
        .where((e) => e.$2 > 0)
        .toList();
    if (rows.isEmpty) {
      return Text(
        l10n.microDetailNoContributions(nutrientName),
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
                  '${value < 50 ? value.toStringAsFixed(1) : value.round()} $unit',
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

class _SourceRow extends StatelessWidget {
  final String source;
  final String value;
  const _SourceRow({required this.source, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            source,
            style: textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDonut extends StatelessWidget {
  final double percent;
  final Color color;
  final bool dashed;
  const _HeroDonut({
    required this.percent,
    required this.color,
    this.dashed = false,
  });

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
              backgroundColor: dashed
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontStyle: dashed ? FontStyle.italic : FontStyle.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
