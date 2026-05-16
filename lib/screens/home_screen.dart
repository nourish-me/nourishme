import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/meal_providers.dart';
import 'history_screen.dart';
import 'input_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMeals = ref.watch(todayMealsProvider);
    final totalKcal = todayMeals.fold<int>(0, (sum, m) => sum + m.kcal);
    final target = ref.watch(calorieTargetProvider);
    final remaining = target - totalKcal;
    final progress = target > 0 ? (totalKcal / target).clamp(0.0, 1.0) : 0.0;
    final statusText = remaining > 0
        ? 'Noch $remaining kcal'
        : remaining == 0
            ? 'Ziel erreicht'
            : '${-remaining} kcal über Ziel';
    final overTarget = remaining < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heute'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Verlauf',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalorien heute',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$totalKcal / $target kcal',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: overTarget ? Colors.orange : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: overTarget ? Colors.orange.shade800 : null,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: todayMeals.isEmpty
                ? const Center(child: Text('Noch keine Einträge heute.'))
                : ListView.separated(
                    itemCount: todayMeals.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final meal = todayMeals[i];
                      final time = TimeOfDay.fromDateTime(meal.createdAt);
                      final timeLabel =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        title: Text(meal.summary),
                        subtitle: Text('$timeLabel  •  ${meal.kcal} kcal'),
                        trailing: meal.safetyWarnings.isEmpty
                            ? null
                            : const Icon(Icons.warning_amber,
                                color: Colors.orange),
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
                            await ref
                                .read(mealRepositoryProvider)
                                .delete(meal.id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InputScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
    );
  }
}
