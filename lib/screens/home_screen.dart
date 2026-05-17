import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import 'confirm_screen.dart';
import 'input_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMeals = ref.watch(todayMealsProvider);
    final totalKcal = todayMeals.fold<int>(0, (sum, m) => sum + m.kcal);
    final totalProtein =
        todayMeals.fold<double>(0, (sum, m) => sum + m.proteinG);
    final totalCarbs = todayMeals.fold<double>(0, (sum, m) => sum + m.carbsG);
    final totalFat = todayMeals.fold<double>(0, (sum, m) => sum + m.fatG);
    final target = ref.watch(calorieTargetProvider);
    final thread = ref.watch(todayThreadProvider).valueOrNull ?? const [];
    final coachLoading = ref.watch(insightLoadingProvider);
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 18, color: scheme.outline),
              const SizedBox(width: 6),
              Text(
                'Heute',
                style: textTheme.titleSmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (thread.isEmpty && !coachLoading)
            _EmptyThread(scheme: scheme, textTheme: textTheme)
          else
            ..._buildThreadItems(
              context: context,
              ref: ref,
              thread: thread,
              meals: todayMeals,
            ),
          if (coachLoading) _CoachLoading(scheme: scheme),
        ],
      ),
      bottomNavigationBar: const _HomeChatInput(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InputScreen()),
            );
          },
          tooltip: 'Neuer Eintrag',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Widget> _buildThreadItems({
    required BuildContext context,
    required WidgetRef ref,
    required List<ThreadItem> thread,
    required List<MealEntry> meals,
  }) {
    final mealsById = {for (final m in meals) m.id: m};
    final widgets = <Widget>[];
    for (final item in thread) {
      switch (item.type) {
        case ThreadItemType.meal:
          final meal = mealsById[item.mealId];
          if (meal == null) continue;
          widgets.add(_ThreadMealCard(
            meal: meal,
            onEdit: () => _editMeal(context, meal),
            onDuplicate: () => _duplicateMeal(ref, meal),
            onDelete: () => _confirmDelete(context, ref, meal),
          ));
        case ThreadItemType.coachResponse:
          widgets.add(_CoachBubble(text: item.text ?? '', isAnswer: false));
        case ThreadItemType.userQuestion:
          widgets.add(_UserBubble(text: item.text ?? ''));
        case ThreadItemType.coachAnswer:
          widgets.add(_CoachBubble(text: item.text ?? '', isAnswer: true));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
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
                color: overTarget
                    ? Colors.orange.shade900
                    : scheme.onPrimaryContainer,
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

class _EmptyThread extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _EmptyThread({required this.scheme, required this.textTheme});

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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CoachLoading extends StatelessWidget {
  final ColorScheme scheme;
  const _CoachLoading({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Coach denkt nach...',
            style: TextStyle(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ThreadMealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ThreadMealCard({
    required this.meal,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = TimeOfDay.fromDateTime(meal.createdAt);
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        child: ListTile(
          title: Text(meal.summary),
          subtitle: Text(timeLabel),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (meal.safetyWarnings.isNotEmpty) ...[
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
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
    );
  }
}

class _CoachBubble extends StatelessWidget {
  final String text;
  final bool isAnswer;
  const _CoachBubble({required this.text, required this.isAnswer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fg = scheme.onTertiaryContainer;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  isAnswer ? 'Coach' : 'Coach-Antwort',
                  style: textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            MarkdownBody(
              data: text,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: TextStyle(color: fg, height: 1.35),
                strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
                em: TextStyle(color: fg, fontStyle: FontStyle.italic),
                listBullet: TextStyle(color: fg),
                tableHead: TextStyle(color: fg, fontWeight: FontWeight.w700),
                tableBody: TextStyle(color: fg),
                tableBorder: TableBorder.all(
                  color: fg.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                tableCellsPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                blockSpacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeChatInput extends ConsumerStatefulWidget {
  const _HomeChatInput();

  @override
  ConsumerState<_HomeChatInput> createState() => _HomeChatInputState();
}

class _HomeChatInputState extends ConsumerState<_HomeChatInput> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<ChatTurn> _buildHistory(
    List<ThreadItem> thread,
    Map<String, MealEntry> mealsById,
  ) {
    final turns = <ChatTurn>[];
    for (final item in thread) {
      switch (item.type) {
        case ThreadItemType.meal:
          final m = mealsById[item.mealId];
          if (m == null) continue;
          turns.add(ChatTurn(
            isUser: true,
            text:
                'Eintrag um ${_formatTime(m.createdAt)}: ${m.summary} (${m.kcal} kcal, Protein ${m.proteinG.toStringAsFixed(0)} g, KH ${m.carbsG.toStringAsFixed(0)} g, Fett ${m.fatG.toStringAsFixed(0)} g).',
          ));
        case ThreadItemType.coachResponse:
        case ThreadItemType.coachAnswer:
          if ((item.text ?? '').isEmpty) continue;
          turns.add(ChatTurn(isUser: false, text: item.text!));
        case ThreadItemType.userQuestion:
          if ((item.text ?? '').isEmpty) continue;
          turns.add(ChatTurn(isUser: true, text: item.text!));
      }
    }
    return turns;
  }

  String _buildContext() {
    final meals = ref.read(todayMealsProvider);
    final target = ref.read(calorieTargetProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final total = meals.fold<int>(0, (s, m) => s + m.kcal);
    final protein = meals.fold<double>(0, (s, m) => s + m.proteinG);
    final remaining = target - total;
    final hour = DateTime.now().hour;
    final buffer = StringBuffer();
    if (profile != null) {
      buffer.writeln(ClaudeClient.describeProfile(
          profile.numChildrenNursing, profile.milkSharePercent));
    }
    buffer
      ..writeln('Aktuelle Uhrzeit: $hour Uhr.')
      ..writeln(
          'Tagesziel: $target kcal. Bisher heute: $total kcal. Verbleibend: $remaining kcal.')
      ..writeln('Protein heute: ${protein.toStringAsFixed(0)} g.');
    return buffer.toString();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final threadRepo = ref.read(threadRepositoryProvider);
    final loadingNotifier = ref.read(insightLoadingProvider.notifier);
    final client = ref.read(claudeClientProvider);
    final meals = ref.read(todayMealsProvider);
    final mealsById = {for (final m in meals) m.id: m};
    final priorThread = ref.read(todayThreadProvider).valueOrNull ?? [];

    // Build history from the current state, then append the new question
    // explicitly so we don't race with the Hive stream.
    final history = _buildHistory(priorThread, mealsById)
      ..add(ChatTurn(isUser: true, text: text));
    final todayContext = _buildContext();

    _controller.clear();
    FocusScope.of(context).unfocus();

    await threadRepo
        .add(ThreadItem.userQuestion(text: text, at: DateTime.now()));
    loadingNotifier.state = true;

    try {
      final reply = await client.chat(
        history: history,
        todayContext: todayContext,
      );
      await threadRepo.add(ThreadItem.coachAnswer(
        text: reply.trim(),
        at: DateTime.now(),
      ));
    } catch (e) {
      await threadRepo.add(ThreadItem.coachAnswer(
        text: 'Fehler bei der Anfrage: $e',
        at: DateTime.now(),
      ));
    } finally {
      loadingNotifier.state = false;
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Frage an den Coach...',
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
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
  await ref
      .read(threadRepositoryProvider)
      .add(ThreadItem.meal(mealId: clone.id, at: clone.createdAt));
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
    await ref
        .read(threadRepositoryProvider)
        .removeMeal(meal.id, meal.createdAt);
  }
}
