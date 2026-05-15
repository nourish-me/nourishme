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

    return Scaffold(
      appBar: AppBar(title: const Text('Verlauf')),
      body: recentDays.isEmpty
          ? const Center(child: Text('Noch keine Einträge.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
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
    final remaining = target - totalKcal;
    final overTarget = remaining < 0;
    final statusText = remaining > 0
        ? 'Noch $remaining kcal'
        : remaining == 0
            ? 'Ziel erreicht'
            : '${-remaining} kcal über Ziel';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDayHeader(day),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalKcal / $target kcal  •  $statusText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overTarget ? Colors.orange.shade800 : null,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...meals.map(
              (meal) => ListTile(
                dense: true,
                title: Text(meal.summary),
                subtitle: Text(
                  '${formatTime(meal.createdAt)}  •  ${meal.kcal} kcal',
                ),
                trailing: meal.safetyWarnings.isEmpty
                    ? null
                    : const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 20),
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
                        TextButton(
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
          ],
        ),
      ),
    );
  }
}
