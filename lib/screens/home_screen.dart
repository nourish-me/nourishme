import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/meal_providers.dart';
import '../utils/date_format.dart';
import 'input_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMeals = ref.watch(todayMealsProvider);
    final totalKcal = todayMeals.fold<int>(0, (sum, m) => sum + m.kcal);
    final target = ref.watch(calorieTargetProvider);
    final latestTip = ref.watch(latestTipProvider);
    final remaining = target - totalKcal;
    final progress = target > 0 ? (totalKcal / target).clamp(0.0, 1.0) : 0.0;
    final overTarget = remaining < 0;
    final statusText = remaining > 0
        ? 'Noch $remaining kcal heute'
        : remaining == 0
            ? 'Tagesziel erreicht'
            : '${-remaining} kcal über Ziel';

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Heute'),
            Text(
              formatFullDate(DateTime.now()),
              style: textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _HeroKcalCard(
            totalKcal: totalKcal,
            target: target,
            progress: progress,
            overTarget: overTarget,
            statusText: statusText,
            scheme: scheme,
            textTheme: textTheme,
          ),
          if (latestTip != null) ...[
            const SizedBox(height: 12),
            _TipCard(
              tip: latestTip,
              onDismiss: () =>
                  ref.read(latestTipProvider.notifier).state = null,
            ),
          ],
          const SizedBox(height: 24),
          Text('Einträge', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          if (todayMeals.isEmpty)
            _EmptyState(scheme: scheme, textTheme: textTheme)
          else
            ...todayMeals.map(
              (meal) => _MealTile(
                summary: meal.summary,
                kcal: meal.kcal,
                createdAt: meal.createdAt,
                hasWarning: meal.safetyWarnings.isNotEmpty,
                onDelete: () async {
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
                    await ref.read(mealRepositoryProvider).delete(meal.id);
                  }
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InputScreen()),
          );
        },
        tooltip: 'Neuer Eintrag',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeroKcalCard extends StatelessWidget {
  final int totalKcal;
  final int target;
  final double progress;
  final bool overTarget;
  final String statusText;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _HeroKcalCard({
    required this.totalKcal,
    required this.target,
    required this.progress,
    required this.overTarget,
    required this.statusText,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = overTarget ? Colors.orange.shade700 : scheme.primary;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: scheme.surface.withValues(alpha: 0.4),
                      color: progressColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalKcal',
                        style: textTheme.displaySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'von $target kcal',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: textTheme.titleMedium?.copyWith(
                color: overTarget ? Colors.orange.shade900 : scheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final VoidCallback onDismiss;

  const _TipCard({required this.tip, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates_outlined,
                size: 20, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  tip,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Tipp ausblenden',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _EmptyState({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.restaurant_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text('Noch keine Einträge heute', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tippe unten auf das Plus um zu starten.',
            style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final String summary;
  final int kcal;
  final DateTime createdAt;
  final bool hasWarning;
  final VoidCallback onDelete;

  const _MealTile({
    required this.summary,
    required this.kcal,
    required this.createdAt,
    required this.hasWarning,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(createdAt);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        title: Text(summary),
        subtitle: Text('$timeLabel  •  $kcal kcal'),
        trailing: hasWarning
            ? const Icon(Icons.warning_amber, color: Colors.orange)
            : null,
        onLongPress: onDelete,
      ),
    );
  }
}
