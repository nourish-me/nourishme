import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/meal_providers.dart';
import '../services/calorie_target.dart';
import '../utils/date_format.dart';
import '../widgets/empty/empty_history.dart';
import '../widgets/kcal_summary.dart';
import 'settings_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(mealsByDayProvider);
    final target = ref.watch(calorieTargetProvider);
    final macroTargets = ref.watch(macroTargetsProvider);
    final recentDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    void openDay(DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      final loaded = ref.read(loadedDaysProvider);
      if (!loaded.any((d) => isSameDay(d, normalized))) {
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final days = <DateTime>[];
        var cursor = normalized;
        while (!cursor.isAfter(todayDate)) {
          days.add(cursor);
          cursor = cursor.add(const Duration(days: 1));
        }
        ref.read(loadedDaysProvider.notifier).state = days;
      }
      ref.read(scrollToDayProvider.notifier).state = normalized;
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
                final total = meals.fold<int>(0, (sum, m) => sum + m.kcal);
                final protein =
                    meals.fold<double>(0, (sum, m) => sum + m.proteinG);
                final carbs =
                    meals.fold<double>(0, (sum, m) => sum + m.carbsG);
                final fat = meals.fold<double>(0, (sum, m) => sum + m.fatG);
                return _DayCard(
                  day: day,
                  mealCount: meals.length,
                  totalKcal: total,
                  totalProtein: protein,
                  totalCarbs: carbs,
                  totalFat: fat,
                  target: target,
                  macroTargets: macroTargets,
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
class _DayCard extends StatelessWidget {
  final DateTime day;
  final int mealCount;
  final int totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int target;
  final MacroTargets macroTargets;
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
                            '$mealCount Eintr${mealCount == 1 ? 'ag' : 'äge'}',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
