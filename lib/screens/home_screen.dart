import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/meal_entry.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import 'confirm_screen.dart';
import 'input_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _insightKickedOff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadInsight());
  }

  Future<void> _maybeLoadInsight() async {
    if (_insightKickedOff) return;
    final existing = ref.read(dailyInsightProvider);
    if (existing != null && existing.isNotEmpty) return;

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final lastDate = settingsRepo.getLastInsightDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstToday = lastDate == null || lastDate.isBefore(today);

    final todayMeals = ref.read(todayMealsProvider);
    final yesterdayMeals = ref.read(yesterdayMealsProvider);

    // Only generate if we have something to talk about, or it's first open of the day
    if (!firstToday && todayMeals.isEmpty) return;
    _insightKickedOff = true;
    ref.read(insightLoadingProvider.notifier).state = true;

    final target = ref.read(calorieTargetProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final total = todayMeals.fold<int>(0, (s, m) => s + m.kcal);

    final todayBlock = todayMeals.isEmpty
        ? 'Heute noch keine Einträge.'
        : todayMeals
            .map((m) =>
                '- ${m.summary} (${m.kcal} kcal${m.safetyWarnings.isEmpty ? '' : ', Warnung: ${m.safetyWarnings.join("; ")}'})')
            .join('\n');

    String? yesterdayBlock;
    if (firstToday && yesterdayMeals.isNotEmpty) {
      yesterdayBlock = yesterdayMeals
          .map((m) => '- ${m.summary} (${m.kcal} kcal)')
          .join('\n');
    }

    try {
      final insight = await ref.read(claudeClientProvider).generateDailyInsight(
            targetKcal: target,
            totalKcalToday: total,
            todayMealsBlock: todayBlock,
            yesterdayMealsBlock: yesterdayBlock,
            numChildrenNursing: profile?.numChildrenNursing ?? 0,
            milkSharePercent: profile?.milkSharePercent ?? 0,
          );
      if (!mounted) return;
      ref.read(dailyInsightProvider.notifier).state = insight.trim();
      await settingsRepo.setLastInsightDate(today);
    } catch (_) {
      // silent: card just stays empty
    } finally {
      if (mounted) {
        ref.read(insightLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayMeals = ref.watch(todayMealsProvider);
    final totalKcal = todayMeals.fold<int>(0, (sum, m) => sum + m.kcal);
    final totalProtein =
        todayMeals.fold<double>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = todayMeals.fold<double>(0, (sum, m) => sum + m.carbsG);
    final totalFat = todayMeals.fold<double>(0, (sum, m) => sum + m.fatG);
    final target = ref.watch(calorieTargetProvider);
    final insight = ref.watch(dailyInsightProvider);
    final insightLoading = ref.watch(insightLoadingProvider);
    final remaining = target - totalKcal;
    final progress = target > 0 ? (totalKcal / target).clamp(0.0, 1.0) : 0.0;
    final overTarget = remaining < 0;
    final statusText = remaining > 0
        ? 'Noch ${formatKcal(remaining)} kcal heute'
        : remaining == 0
            ? 'Tagesziel erreicht'
            : '${formatKcal(-remaining)} kcal über Ziel';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
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
          const SizedBox(height: 12),
          _MacrosRow(
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
          ),
          if (insight != null || insightLoading) ...[
            const SizedBox(height: 12),
            _InsightCard(
              text: insight,
              loading: insightLoading,
              onDismiss: () =>
                  ref.read(dailyInsightProvider.notifier).state = null,
            ),
          ],
          const SizedBox(height: 24),
          Text('Einträge', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          if (todayMeals.isEmpty)
            _EmptyState(scheme: scheme, textTheme: textTheme)
          else
            ...todayMeals.map(
              (meal) => _SlidableMealRow(
                meal: meal,
                onEdit: () => _editMeal(context, meal),
                onDuplicate: () => _duplicateMeal(ref, meal),
                onDelete: () => _confirmDelete(context, ref, meal),
                child: _MealTile(
                  summary: meal.summary,
                  kcal: meal.kcal,
                  createdAt: meal.createdAt,
                  hasWarning: meal.safetyWarnings.isNotEmpty,
                ),
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
                        formatKcal(totalKcal),
                        style: textTheme.displaySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'von ${formatKcal(target)} kcal',
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

class _MacrosRow extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  const _MacrosRow({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MacroTile(label: 'Protein', grams: protein)),
        const SizedBox(width: 8),
        Expanded(child: _MacroTile(label: 'KH', grams: carbs)),
        const SizedBox(width: 8),
        Expanded(child: _MacroTile(label: 'Fett', grams: fat)),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double grams;
  const _MacroTile({required this.label, required this.grams});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 4),
            Text(
              '${grams.toStringAsFixed(grams >= 100 ? 0 : 1)} g',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String? text;
  final bool loading;
  final VoidCallback onDismiss;

  const _InsightCard({
    required this.text,
    required this.loading,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fg = scheme.onTertiaryContainer;
    return Card(
      elevation: 0,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 20, color: fg),
                const SizedBox(width: 8),
                Text(
                  'Tagesüberblick',
                  style: textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (text != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Ausblenden',
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (loading && text == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Überblick wird erstellt...',
                      style: TextStyle(color: fg.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              )
            else if (text != null) ...[
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'wird aktualisiert...',
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (text != null && !(loading && text == null))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MarkdownBody(
                  data: text!,
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(color: fg, height: 1.35),
                    strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
                    em: TextStyle(color: fg, fontStyle: FontStyle.italic),
                    listBullet: TextStyle(color: fg),
                    h1: TextStyle(
                        color: fg, fontSize: 17, fontWeight: FontWeight.w700),
                    h2: TextStyle(
                        color: fg, fontSize: 16, fontWeight: FontWeight.w700),
                    h3: TextStyle(
                        color: fg, fontSize: 15, fontWeight: FontWeight.w600),
                    blockSpacing: 6,
                  ),
                ),
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

  const _MealTile({
    required this.summary,
    required this.kcal,
    required this.createdAt,
    required this.hasWarning,
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
        subtitle: Text(timeLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasWarning) ...[
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              '${formatKcal(kcal)} kcal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidableMealRow extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Widget child;

  const _SlidableMealRow({
    required this.meal,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Slidable(
      key: ValueKey('home-${meal.id}'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.78,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit_outlined,
            label: 'Bearbeiten',
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            icon: Icons.copy_outlined,
            label: 'Kopieren',
            backgroundColor: scheme.tertiaryContainer,
            foregroundColor: scheme.onTertiaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete_outline,
            label: 'Löschen',
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
        ],
      ),
      child: child,
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

void _editMeal(BuildContext context, MealEntry meal) {
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

Future<void> _duplicateMeal(WidgetRef ref, MealEntry meal) async {
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

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, MealEntry meal) async {
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
    await ref.read(mealRepositoryProvider).delete(meal.id);
  }
}
