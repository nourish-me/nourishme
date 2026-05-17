import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal_entry.dart';
import '../providers/meal_providers.dart';
import '../utils/date_format.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(mealsByDayProvider);
    final target = ref.watch(calorieTargetProvider);
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final recentDays = sortedDays.take(14).toList();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Verlauf'),
            Text(
              'Letzte 14 Tage',
              style: textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: recentDays.isEmpty
          ? _EmptyHistory(scheme: scheme, textTheme: textTheme)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: recentDays.length,
              itemBuilder: (context, i) {
                final day = recentDays[i];
                final meals = grouped[day]!;
                meals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                final total = meals.fold<int>(0, (sum, m) => sum + m.kcal);
                return _DaySection(
                  day: day,
                  meals: meals,
                  totalKcal: total,
                  target: target,
                  onDelete: (id) =>
                      ref.read(mealRepositoryProvider).delete(id),
                );
              },
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _EmptyHistory({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text('Noch keine Einträge', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Verlauf füllt sich, sobald du Einträge speicherst.',
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<MealEntry> meals;
  final int totalKcal;
  final int target;
  final Future<void> Function(String id) onDelete;

  const _DaySection({
    required this.day,
    required this.meals,
    required this.totalKcal,
    required this.target,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = target - totalKcal;
    final overTarget = remaining < 0;
    final progress = target > 0 ? (totalKcal / target).clamp(0.0, 1.0) : 0.0;
    final statusText = remaining > 0
        ? 'Noch $remaining kcal'
        : remaining == 0
            ? 'Ziel erreicht'
            : '${-remaining} kcal über Ziel';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDayHeader(day),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$totalKcal / $target kcal',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: overTarget ? Colors.orange.shade700 : scheme.primary,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: textTheme.bodySmall?.copyWith(
                      color: overTarget ? Colors.orange.shade800 : scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            ...meals.map(
              (meal) => ListTile(
                dense: true,
                title: Text(meal.summary),
                subtitle: Text(
                  '${formatTime(meal.createdAt)}  •  ${meal.kcal} kcal',
                ),
                trailing: meal.safetyWarnings.isEmpty
                    ? null
                    : Icon(Icons.warning_amber,
                        color: Colors.orange.shade700, size: 20),
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Eintrag löschen?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          child: const Text('Abbrechen'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await onDelete(meal.id);
                  }
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
