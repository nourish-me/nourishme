import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/meal_entry.dart';
import '../models/user_profile_settings.dart';
import '../providers/meal_providers.dart';
import '../providers/ui_providers.dart';
import '../services/calorie_target.dart';
import '../services/meal_aggregation.dart';
import '../services/micronutrient_targets.dart';
import '../utils/date_format.dart';
import '../widgets/empty/empty_history.dart';
import '../widgets/kcal_summary.dart';
import '../widgets/micronutrient/micronutrient_donut.dart';
import '../widgets/micronutrient/nutrient_cell.dart';
import 'settings_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(mealsByDayProvider);
    final target = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;
    final recentDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    void openDay(DateTime day) {
      // Single-day-view: jumping to a Verlauf day just flips focusedDay.
      // The diary body rebuilds from focusedDayThreadProvider and the
      // scrollToDayProvider signal moves the scroll position once the
      // new day's items have rendered.
      final normalized = DateTime(day.year, day.month, day.day);
      ref.read(focusedDayProvider.notifier).state = normalized;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      requestScroll(
        ref,
        target: normalized == today ? ScrollTarget.bottom : ScrollTarget.dayTop,
        day: normalized,
      );
      ref.read(selectedTabProvider.notifier).state = 0;
    }

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabHistory),
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
      body: recentDays.isEmpty
          ? const EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: recentDays.length,
              itemBuilder: (context, i) {
                final day = recentDays[i];
                final meals = grouped[day]!;
                final total = dayTotal(meals);
                final pills = profile == null
                    ? const <_MicroPill>[]
                    : _computeMicroPills(profile, meals, locale);
                return _DayCard(
                  day: day,
                  mealCount: total.mealCount,
                  totalKcal: total.kcal,
                  totalProtein: total.proteinG,
                  totalCarbs: total.carbsG,
                  totalFat: total.fatG,
                  target: target,
                  macroTargets: macroTargets,
                  microPills: pills,
                  onTap: () => openDay(day),
                );
              },
            ),
    );
  }
}

// _EmptyHistory removed, replaced by EmptyHistory widget per TestFlight 1.1
// design pass (see widgets/empty/empty_history.dart).

// Each day shows a compact tap-target card: the day header + the same
// KcalSummary used in the Tagebuch toolbar. Tapping it opens that day in
// the Tagebuch where the actual meal entries live (Slide-Actions, Coach
// bubbles etc. are handled there).
// One micronutrient pill: short label + percent of target reached, plus
// the single-accent state shared with the donut/cell widgets elsewhere.
// Pre-computed in the screen so _DayCard stays a pure presentation widget.
class _MicroPill {
  final String name;
  final int pct;
  final MicronutrientState state;
  const _MicroPill({
    required this.name,
    required this.pct,
    required this.state,
  });
}

List<_MicroPill> _computeMicroPills(
    UserProfileSettings profile, List<MealEntry> meals, String locale) {
  final keys = profile.selectedMicronutrients ??
      MicronutrientDefaults.forProfile(profile);
  final pills = <_MicroPill>[];
  for (final key in keys) {
    final t = MicronutrientTargets.forKey(key, profile);
    final d = MicronutrientDisplay.forKey(key);
    if (t == null || d == null || t.value <= 0) continue;
    final intake = dailyIntakeFor(key, meals, profile);
    final pct = (intake / t.value * 100).round();
    final state = micronutrientStateFor(
      intake: intake,
      target: t.value,
      awareness: false,
      hasUpperLimit: false,
    );
    pills.add(_MicroPill(
      name: d.nameForLocale(locale),
      pct: pct,
      state: state,
    ));
  }
  return pills;
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final int mealCount;
  final int totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int target;
  final MacroTargets macroTargets;
  final List<_MicroPill> microPills;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.mealCount,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.target,
    required this.macroTargets,
    required this.microPills,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDayHeader(context, day),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)
                                .historyEntryCount(mealCount),
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.outline,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                KcalSummary(
                  totalKcal: totalKcal,
                  targetKcal: target,
                  protein: totalProtein,
                  carbs: totalCarbs,
                  fat: totalFat,
                  macroTargets: macroTargets,
                ),
                if (microPills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < microPills.length; i++) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(
                          child: NutrientCell(
                            name: microPills[i].name,
                            percent: microPills[i].pct.toDouble(),
                            state: microPills[i].state,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
