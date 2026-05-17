import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/meal_entry.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import 'confirm_screen.dart';

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

MealParseResult _toParseResult(MealEntry meal) => MealParseResult(
      isMeal: true,
      rejectionReason: null,
      summary: meal.summary,
      kcal: meal.kcal,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
      portionAmount: 0,
      portionUnit: 'g',
      safetyWarnings: meal.safetyWarnings,
    );

void _editMealEntry(BuildContext context, MealEntry meal) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ConfirmScreen(
        rawText: meal.rawText,
        parsed: _toParseResult(meal),
        existingMealId: meal.id,
        existingCreatedAt: meal.createdAt,
      ),
    ),
  );
}

Future<void> _duplicateMealEntry(WidgetRef ref, MealEntry meal) async {
  final clone = MealEntry(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    createdAt: DateTime.now(),
    rawText: meal.rawText,
    summary: meal.summary,
    kcal: meal.kcal,
    proteinG: meal.proteinG,
    carbsG: meal.carbsG,
    fatG: meal.fatG,
    safetyWarnings: meal.safetyWarnings,
  );
  await ref.read(mealRepositoryProvider).save(clone);
}

Future<void> _confirmDeleteEntry(
  BuildContext context,
  WidgetRef ref,
  MealEntry meal,
  Future<void> Function(String id) onDelete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('„${meal.summary}" löschen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Löschen'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await onDelete(meal.id);
  }
}

class _DaySection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = target - totalKcal;
    final overTarget = remaining < 0;
    final progress = target > 0 ? (totalKcal / target).clamp(0.0, 1.0) : 0.0;
    final statusText = remaining > 0
        ? 'Noch ${formatKcal(remaining)} kcal'
        : remaining == 0
            ? 'Ziel erreicht'
            : '${formatKcal(-remaining)} kcal über Ziel';

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
                    '${formatKcal(totalKcal)} / ${formatKcal(target)} kcal',
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
              (meal) => Slidable(
                key: ValueKey('history-${meal.id}'),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.78,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _editMealEntry(context, meal),
                      icon: Icons.edit_outlined,
                      label: 'Bearbeiten',
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                    ),
                    SlidableAction(
                      onPressed: (_) => _duplicateMealEntry(ref, meal),
                      icon: Icons.copy_outlined,
                      label: 'Kopieren',
                      backgroundColor: scheme.tertiaryContainer,
                      foregroundColor: scheme.onTertiaryContainer,
                    ),
                    SlidableAction(
                      onPressed: (_) =>
                          _confirmDeleteEntry(context, ref, meal, onDelete),
                      icon: Icons.delete_outline,
                      label: 'Löschen',
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                    ),
                  ],
                ),
                child: ListTile(
                  dense: true,
                  title: Text(meal.summary),
                  subtitle: Text(formatTime(meal.createdAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (meal.safetyWarnings.isNotEmpty) ...[
                        Icon(Icons.warning_amber,
                            color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${formatKcal(meal.kcal)} kcal',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
