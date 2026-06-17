import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../l10n/app_localizations.dart';
import '../models/meal_entry.dart';
import '../models/weight_entry.dart';
import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../services/calorie_target.dart';
import '../services/meal_aggregation.dart';
import '../services/micronutrient_targets.dart';
import '../theme/nourishme_colors.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import 'settings_screen.dart';

// TrendsScreen: first-pass reporting view introduced in TestFlight 1.1.
// Pure derivation from existing meal data, no new API calls. Cards:
//   1. 7-day kcal bar chart with sweet-spot colouring.
//   2. Sweet-spot streak counter.
//   3. Weekly average kcal + macros vs. target.
//   4. Tracking consistency (days with entries vs. total days observed).
//   5. Top 3 frequent meals.
class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final mealsAll = ref.watch(mealsProvider).valueOrNull ?? const <MealEntry>[];
    final targetKcal = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);

    final stats = _Stats.from(mealsAll, targetKcal, macroTargets);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trendsTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _WeekChartCard(stats: stats, scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 12),
          _StreakCard(stats: stats, scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 12),
          _MacroAveragesCard(
              stats: stats, scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 12),
          _MicronutrientWeekCard(
              scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 12),
          _ConsistencyCard(
              stats: stats, scheme: scheme, textTheme: textTheme),
          const SizedBox(height: 12),
          _WeightCard(scheme: scheme, textTheme: textTheme),
          if (stats.topMeals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TopMealsCard(
                stats: stats, scheme: scheme, textTheme: textTheme),
          ],
        ],
      ),
    );
  }
}

// -------- Stats aggregator -----------------------------------------------

class _DayTotal {
  final DateTime day;
  final int kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;
  const _DayTotal({
    required this.day,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
  });
}

class _Stats {
  final int targetKcal;
  final MacroTargets macroTargets;
  final List<_DayTotal> lastSevenDays; // oldest first
  final int streak;
  final int totalTrackedDays;
  final int totalDaysSinceStart;
  final int weekAvgKcal;
  final int weekAvgProtein;
  final int weekAvgCarbs;
  final int weekAvgFat;
  final int daysInSweetSpot;
  final List<MapEntry<String, int>> topMeals;

  const _Stats({
    required this.targetKcal,
    required this.macroTargets,
    required this.lastSevenDays,
    required this.streak,
    required this.totalTrackedDays,
    required this.totalDaysSinceStart,
    required this.weekAvgKcal,
    required this.weekAvgProtein,
    required this.weekAvgCarbs,
    required this.weekAvgFat,
    required this.daysInSweetSpot,
    required this.topMeals,
  });

  static _Stats from(
    List<MealEntry> meals,
    int targetKcal,
    MacroTargets macroTargets,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group meals by day (date only).
    final byDay = <DateTime, List<MealEntry>>{};
    for (final m in meals) {
      final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      byDay.putIfAbsent(d, () => []).add(m);
    }

    // Last 7 days totals (oldest first so the chart reads left-to-right).
    final lastSeven = <_DayTotal>[];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final t = dayTotal(byDay[d] ?? const []);
      lastSeven.add(_DayTotal(
        day: d,
        kcal: t.kcal,
        proteinG: t.proteinG,
        carbsG: t.carbsG,
        fatG: t.fatG,
        mealCount: t.mealCount,
      ));
    }

    // Sweet-spot streak: consecutive days from today backwards where kcal is
    // in [80%, 110%] of target. Today only counts if user has eaten enough
    // already to be in-range; otherwise we look at completed days.
    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final d = today.subtract(Duration(days: i));
      final items = byDay[d] ?? const [];
      if (items.isEmpty) {
        // No tracking → break the streak unless it's today and still early.
        if (i == 0) continue;
        break;
      }
      final kcal = dayTotal(items).kcal;
      final ratio = targetKcal > 0 ? kcal / targetKcal : 0;
      if (ratio >= 0.80 && ratio <= 1.10) {
        streak++;
      } else {
        break;
      }
    }

    // Tracking consistency: from first meal date to today.
    int totalTracked = 0;
    int daysSinceStart = 0;
    if (meals.isNotEmpty) {
      final first = meals
          .map((m) => DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      daysSinceStart = today.difference(first).inDays + 1;
      totalTracked = byDay.length;
    }

    // Weekly averages (over the 7-day window, including empty days).
    final daysWithData = lastSeven.where((d) => d.mealCount > 0).toList();
    final divisor = daysWithData.isEmpty ? 1 : daysWithData.length;
    final weekAvgKcal = daysWithData.isEmpty
        ? 0
        : (daysWithData.fold<int>(0, (s, d) => s + d.kcal) / divisor).round();
    final weekAvgProtein = daysWithData.isEmpty
        ? 0
        : (daysWithData.fold<double>(0, (s, d) => s + d.proteinG) / divisor)
            .round();
    final weekAvgCarbs = daysWithData.isEmpty
        ? 0
        : (daysWithData.fold<double>(0, (s, d) => s + d.carbsG) / divisor)
            .round();
    final weekAvgFat = daysWithData.isEmpty
        ? 0
        : (daysWithData.fold<double>(0, (s, d) => s + d.fatG) / divisor).round();

    final daysInSweetSpot = lastSeven.where((d) {
      if (d.kcal == 0) return false;
      final r = targetKcal > 0 ? d.kcal / targetKcal : 0;
      return r >= 0.80 && r <= 1.10;
    }).length;

    // Top meals frequency over the last 7 days.
    final freq = <String, int>{};
    for (final d in lastSeven) {
      final items = byDay[d.day] ?? const <MealEntry>[];
      for (final m in items) {
        final key = m.summary.trim();
        if (key.isEmpty) continue;
        freq[key] = (freq[key] ?? 0) + 1;
      }
    }
    final topMeals = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Stats(
      targetKcal: targetKcal,
      macroTargets: macroTargets,
      lastSevenDays: lastSeven,
      streak: streak,
      totalTrackedDays: totalTracked,
      totalDaysSinceStart: daysSinceStart,
      weekAvgKcal: weekAvgKcal,
      weekAvgProtein: weekAvgProtein,
      weekAvgCarbs: weekAvgCarbs,
      weekAvgFat: weekAvgFat,
      daysInSweetSpot: daysInSweetSpot,
      topMeals: topMeals.where((e) => e.value > 1).take(3).toList(),
    );
  }
}

// -------- Card widgets ---------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;
  const _Card({required this.child, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _Eyebrow({
    required this.text,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: scheme.outline,
        letterSpacing: 1.3,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WeekChartCard extends StatelessWidget {
  final _Stats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _WeekChartCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxKcal = stats.lastSevenDays
        .map((d) => d.kcal)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxKcal == 0 ? 1.0 : maxKcal.toDouble();
    final l10n = AppLocalizations.of(context);
    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: l10n.trendsWeekEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            l10n.trendsWeekTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.trendsWeekSummary(
              stats.daysInSweetSpot,
              formatKcal(stats.weekAvgKcal),
            ),
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final d in stats.lastSevenDays)
                  _ChartBar(
                    day: d,
                    targetKcal: stats.targetKcal,
                    scale: scale,
                    scheme: scheme,
                    textTheme: textTheme,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final _DayTotal day;
  final int targetKcal;
  final double scale;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _ChartBar({
    required this.day,
    required this.targetKcal,
    required this.scale,
    required this.scheme,
    required this.textTheme,
  });

  static const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final ratio = targetKcal > 0 ? day.kcal / targetKcal : 0.0;
    final Color barColor;
    if (day.kcal == 0) {
      barColor = scheme.outlineVariant;
    } else if (ratio > 1.10) {
      barColor = NMColors.amber;
    } else if (ratio >= 0.80) {
      barColor = NMColors.moss;
    } else {
      barColor = scheme.surfaceContainerHighest;
    }

    final maxBarHeight = 100.0;
    final h = scale > 0
        ? (day.kcal / scale * maxBarHeight).clamp(2.0, maxBarHeight)
        : 2.0;
    final weekday = _weekdays[(day.day.weekday - 1) % 7];
    final isToday = isSameDay(day.day, DateTime.now());

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          day.kcal > 0 ? formatKcal(day.kcal) : '-',
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: h,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weekday,
          style: textTheme.labelSmall?.copyWith(
            color: isToday ? scheme.primary : scheme.outline,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final _Stats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _StreakCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      scheme: scheme,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NMColors.moss.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              stats.streak.toString(),
              style: textTheme.displaySmall?.copyWith(
                color: NMColors.moss,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Eyebrow(
                    text: AppLocalizations.of(context).trendsStreakEyebrow,
                    scheme: scheme,
                    textTheme: textTheme),
                const SizedBox(height: 4),
                Text(
                  stats.streak == 0
                      ? AppLocalizations.of(context).trendsStreakZero
                      : stats.streak == 1
                          ? AppLocalizations.of(context).trendsStreakOne
                          : AppLocalizations.of(context)
                              .trendsStreakMany(stats.streak),
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontStyle: FontStyle.italic,
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

class _MacroAveragesCard extends StatelessWidget {
  final _Stats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _MacroAveragesCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: l10n.trendsAveragesEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            l10n.trendsAveragesTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _StatRow(
              label: l10n.trendsLabelKcal,
              value: '${formatKcal(stats.weekAvgKcal)} kcal',
              target: '${formatKcal(stats.targetKcal)} kcal',
              scheme: scheme,
              textTheme: textTheme),
          Divider(color: scheme.outlineVariant, height: 18),
          _StatRow(
              label: l10n.trendsLabelProtein,
              value: '${stats.weekAvgProtein} g',
              target: '${stats.macroTargets.proteinG} g',
              scheme: scheme,
              textTheme: textTheme),
          Divider(color: scheme.outlineVariant, height: 18),
          _StatRow(
              label: l10n.trendsLabelCarbs,
              value: '${stats.weekAvgCarbs} g',
              target: '${stats.macroTargets.carbsG} g',
              scheme: scheme,
              textTheme: textTheme),
          Divider(color: scheme.outlineVariant, height: 18),
          _StatRow(
              label: l10n.trendsLabelFat,
              value: '${stats.weekAvgFat} g',
              target: '${stats.macroTargets.fatG} g',
              scheme: scheme,
              textTheme: textTheme),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _StatRow({
    required this.label,
    required this.value,
    required this.target,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
        Text(
          value,
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          AppLocalizations.of(context).trendsTargetPrefix(target),
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final _Stats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _ConsistencyCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = stats.totalDaysSinceStart == 0
        ? l10n.trendsConsistencyEmpty
        : l10n.trendsConsistencyBody(
            stats.totalDaysSinceStart, stats.totalTrackedDays);
    final ratio = stats.totalDaysSinceStart > 0
        ? stats.totalTrackedDays / stats.totalDaysSinceStart
        : 0.0;
    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: l10n.trendsConsistencyEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            l10n.trendsConsistencyTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              // Match the other cards' empty-state convention
              // (scheme.outline) for consistency. Vanessa Build+30:
              // "Consistency body wirkte fast weiß im Vergleich zu
              // Wochenschnitt + Mikro Empty-States".
              color: stats.totalDaysSinceStart == 0
                  ? scheme.outline
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMealsCard extends StatelessWidget {
  final _Stats stats;
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _TopMealsCard({
    required this.stats,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: AppLocalizations.of(context).trendsTopMealsEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).trendsTopMealsTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stats.topMeals.length; i++) ...[
            if (i > 0)
              Divider(color: scheme.outlineVariant, height: 18),
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.topMeals[i].key,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${stats.topMeals[i].value}×',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Weight history card. Visualization only, no interpretation: a sparkline
// of all entries, the latest value, and the delta against the earliest
// entry in the window. The user adds entries implicitly by editing their
// weight in Settings, which appends to weightHistoryProvider on save.
class _WeightCard extends ConsumerWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _WeightCard({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightHistoryProvider).valueOrNull ??
        const <WeightEntry>[];
    final l10n = AppLocalizations.of(context);
    final dateFmt = intl.DateFormat.yMMMd();

    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: l10n.trendsWeightEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            l10n.trendsWeightTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (entries.length < 2)
            Text(
              l10n.trendsWeightEmpty,
              style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${entries.last.weightKg.toStringAsFixed(1)} kg',
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDelta(
                      entries.last.weightKg - entries.first.weightKg),
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.outline,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.trendsWeightSince(dateFmt.format(entries.first.recordedAt)),
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: CustomPaint(
                size: const Size(double.infinity, 72),
                painter: _SparklinePainter(
                  entries: entries,
                  lineColor: NMColors.pine,
                  dotColor: NMColors.amber,
                  gridColor: scheme.outlineVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDelta(double delta) {
    if (delta.abs() < 0.05) return '±0.0 kg';
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)} kg';
  }
}

// Plain sparkline painter for the weight history card. Connects the
// entries with a line and dots each entry. Y range auto-scales to the
// min/max of the data with a small padding so a flat trajectory still
// has visible vertical room.
class _SparklinePainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;

  _SparklinePainter({
    required this.entries,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final minW =
        entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxW =
        entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).abs() < 0.001 ? 1.0 : (maxW - minW);

    final minMs = entries.first.recordedAt.millisecondsSinceEpoch.toDouble();
    final maxMs = entries.last.recordedAt.millisecondsSinceEpoch.toDouble();
    final tRange = (maxMs - minMs).abs() < 1 ? 1.0 : (maxMs - minMs);

    const padding = EdgeInsets.fromLTRB(6, 10, 6, 10);
    final w = size.width - padding.horizontal;
    final h = size.height - padding.vertical;

    final points = <Offset>[];
    for (final e in entries) {
      final x = padding.left +
          ((e.recordedAt.millisecondsSinceEpoch - minMs) / tRange) * w;
      final y = padding.top + (1 - (e.weightKg - minW) / range) * h;
      points.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(padding.left, size.height - padding.bottom),
      Offset(size.width - padding.right, size.height - padding.bottom),
      gridPaint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = dotColor;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.entries != entries ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}

// -------- Micronutrient week overview (#107) -----------------------------

// One row in the week-overview list: nutrient key, name, % filled vs.
// daily target (averaged over the last 7 days), unit label, intake/target
// values for the detail sheet.
class _MicroWeekRow {
  final String key;
  final String name;
  final double pct; // 0..>100 (can exceed 100 with active supplements)
  final double avgIntake;
  final double target;
  final String unitLabel;
  // True when the user explicitly picked this nutrient to follow in the
  // diary (or it's part of the phase-default set when the user hasn't
  // customised). Used to surface tracked nutrients above untracked ones
  // with a hairline divider between the two groups.
  final bool isTracked;
  const _MicroWeekRow({
    required this.key,
    required this.name,
    required this.pct,
    required this.avgIntake,
    required this.target,
    required this.unitLabel,
    required this.isTracked,
  });
}

class _MicronutrientWeekCard extends ConsumerWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _MicronutrientWeekCard({
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final meals = ref.watch(mealsProvider).valueOrNull ?? const <MealEntry>[];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    final rows = _computeRows(meals, profile, locale);
    return _Card(
      scheme: scheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(
              text: l10n.trendsAveragesEyebrow,
              scheme: scheme,
              textTheme: textTheme),
          const SizedBox(height: 6),
          Text(
            l10n.trendsMicronutrientWeekTitle,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trendsMicronutrientWeekHint,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              l10n.trendsMicronutrientEmpty,
              style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              // Hairline between the tracked group and the rest. Falls only
              // at the FIRST untracked row (so a layout with only tracked
              // or only untracked rows has no extra divider).
              if (i > 0 &&
                  rows[i - 1].isTracked &&
                  !rows[i].isTracked) ...[
                Divider(
                  height: 18,
                  thickness: 0.5,
                  color: scheme.outlineVariant,
                ),
              ],
              _MicroBarRow(
                row: rows[i],
                scheme: scheme,
                textTheme: textTheme,
                onTap: () =>
                    _openDetail(context, ref, rows[i], profile, locale),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  List<_MicroWeekRow> _computeRows(
      List<MealEntry> allMeals, UserProfileSettings profile, String locale) {
    if (allMeals.isEmpty) return const [];
    // Group meals into the last 7 days. A day with zero meals still counts
    // as a real day in the denominator so a quiet day doesn't artificially
    // inflate the average. But: if the user has logged NOTHING in the
    // entire 7-day window, drop the section (no signal worth showing).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(const Duration(days: 6));
    final lastWeek = allMeals
        .where((m) => !m.createdAt.isBefore(cutoff))
        .toList(growable: false);
    if (lastWeek.isEmpty) return const [];
    // Build per-day buckets.
    final byDay = <DateTime, List<MealEntry>>{};
    for (final m in lastWeek) {
      final day = DateTime(
          m.createdAt.year, m.createdAt.month, m.createdAt.day);
      byDay.putIfAbsent(day, () => []).add(m);
    }
    // The user's actively-tracked nutrients land above the rest with a
    // hairline divider between the two groups. Falls back to the phase
    // defaults if the user hasn't customised, so a brand-new profile
    // still gets a sensible "primary" group.
    final trackedKeys = (profile.selectedMicronutrients ??
            MicronutrientDefaults.forProfile(profile))
        .toSet();
    final out = <_MicroWeekRow>[];
    for (final key in MicronutrientKey.all) {
      final target = MicronutrientTargets.forKey(key, profile);
      final display = MicronutrientDisplay.forKey(key);
      if (target == null || display == null || target.value <= 0) continue;
      // Average daily intake across the 7 days we have data for.
      double sum = 0;
      var nDays = 0;
      for (var i = 0; i < 7; i++) {
        final day = cutoff.add(Duration(days: i));
        final dayMeals = byDay[day] ?? const <MealEntry>[];
        sum += dailyIntakeFor(key, dayMeals, profile);
        nDays++;
      }
      if (nDays == 0) continue;
      final avg = sum / nDays;
      final pct = (avg / target.value) * 100;
      out.add(_MicroWeekRow(
        key: key,
        name: display.nameForLocale(locale),
        pct: pct,
        avgIntake: avg,
        target: target.value,
        unitLabel: target.unitLabel,
        isTracked: trackedKeys.contains(key),
      ));
    }
    // Sort: tracked rows first, within each group strictly alphabetical
    // by display name. Earlier iteration sorted by % within the group
    // (Vanessa Build+29 feedback: "verwirrend, lieber nur alphabetisch
    // in den zwei Buckets").
    out.sort((a, b) {
      if (a.isTracked != b.isTracked) return a.isTracked ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  void _openDetail(BuildContext context, WidgetRef ref, _MicroWeekRow row,
      UserProfileSettings profile, String locale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        final sheetL10n = AppLocalizations.of(sheetCtx);
        final sheetTheme = Theme.of(sheetCtx);
        final sheetScheme = sheetTheme.colorScheme;
        final sources = MicronutrientSources.forKey(row.key, locale);
        // Supplement contribution figure for this nutrient (sums across
        // ALL active supplements). null when supplement has no entry.
        double supplementContribution = 0;
        for (final s in profile.activeSupplements) {
          supplementContribution += s.values[row.key] ?? 0;
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: sheetTheme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${row.pct.round()}% · Ø ${_fmtNumLocal(row.avgIntake)}/${_fmtNumLocal(row.target)} ${row.unitLabel}',
                  style: sheetTheme.textTheme.bodyMedium
                      ?.copyWith(color: _barColorFor(row.pct, sheetScheme)),
                ),
                if (supplementContribution > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    sheetL10n.trendsMicronutrientSheetSupplementCovered(
                      _fmtNumLocal(supplementContribution),
                      row.unitLabel,
                    ),
                    style: sheetTheme.textTheme.bodySmall
                        ?.copyWith(color: sheetScheme.tertiary),
                  ),
                ],
                if (sources.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    sheetL10n.trendsMicronutrientSheetSourcesTitle,
                    style: sheetTheme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  // Task B13, Build +34: prose-style top sources, capped
                  // at 2 with a "+N weitere" link that reveals the rest.
                  // The full list was overwhelming when the user only
                  // wanted a quick "where do I get this from" cue.
                  _MicroSourcesProse(sources: sources),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(sheetL10n.trendsMicronutrientSheetClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MicroBarRow extends StatelessWidget {
  final _MicroWeekRow row;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  const _MicroBarRow({
    required this.row,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _barColorFor(row.pct, scheme);
    final fill = (row.pct / 100).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${row.pct.round()}%',
                  style: textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    color: scheme.surfaceContainerHighest,
                  ),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(
                      height: 6,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _barColorFor(double pct, ColorScheme scheme) {
  if (pct >= 85) return Colors.green.shade600;
  if (pct >= 60) return Colors.amber.shade700;
  return scheme.error;
}

String _fmtNumLocal(double v) {
  if (v >= 100) return v.toStringAsFixed(0);
  if (v >= 10) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

// Top-sources prose for the micronutrient detail sheet. Renders the first
// two sources joined by a comma; if more exist a "+N weitere" link reveals
// the rest. Local stateful widget because the modal sheet itself is
// stateless and rebuilds whole-cloth on toggle.
class _MicroSourcesProse extends StatefulWidget {
  final List<String> sources;
  const _MicroSourcesProse({required this.sources});

  @override
  State<_MicroSourcesProse> createState() => _MicroSourcesProseState();
}

class _MicroSourcesProseState extends State<_MicroSourcesProse> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final all = widget.sources;
    final visible =
        _expanded || all.length <= 2 ? all : all.take(2).toList();
    final hidden = all.length - visible.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          visible.join(', '),
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        if (hidden > 0) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.trendsMicronutrientSheetSourcesMore(hidden),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
