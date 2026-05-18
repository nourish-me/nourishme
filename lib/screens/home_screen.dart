import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';

import '../models/favorite_meal.dart';
import '../models/meal_entry.dart';
import '../models/thread_item.dart';
import '../providers/meal_providers.dart';
import '../services/claude_client.dart';
import '../utils/date_format.dart';
import '../utils/number_format.dart';
import 'confirm_screen.dart';
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
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
      ),
      bottomNavigationBar: const _HomeInput(),
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
            'Tippe unten was du isst, oder stell eine Frage.',
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

class _HomeInput extends ConsumerStatefulWidget {
  const _HomeInput();

  @override
  ConsumerState<_HomeInput> createState() => _HomeInputState();
}

class _HomeInputState extends ConsumerState<_HomeInput> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (_) {}
  }

  Future<void> _showPhotoPicker() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useFavorite(FavoriteMeal favorite) async {
    if (_sending) return;
    setState(() => _sending = true);
    final meal = MealEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      rawText: '',
      summary: favorite.summary,
      kcal: favorite.kcal,
      proteinG: favorite.proteinG,
      carbsG: favorite.carbsG,
      fatG: favorite.fatG,
      safetyWarnings: favorite.safetyWarnings,
    );
    await _saveAndCoach(meal, rawText: '');
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _confirmDeleteFavorite(FavoriteMeal favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('„${favorite.summary}" entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(favoriteRepositoryProvider).delete(favorite.id);
    }
  }

  Future<void> _saveAndCoach(MealEntry meal, {required String rawText}) async {
    final mealRepo = ref.read(mealRepositoryProvider);
    final threadRepo = ref.read(threadRepositoryProvider);
    final client = ref.read(claudeClientProvider);
    final loadingNotifier = ref.read(insightLoadingProvider.notifier);

    await mealRepo.save(meal);
    await threadRepo.add(ThreadItem.meal(mealId: meal.id, at: meal.createdAt));

    final target = ref.read(calorieTargetProvider);
    final today = ref.read(todayMealsProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final mealsForTotal =
        today.any((m) => m.id == meal.id) ? today : [...today, meal];
    final totalKcal = mealsForTotal.fold<int>(0, (s, m) => s + m.kcal);
    final totalProtein =
        mealsForTotal.fold<double>(0, (s, m) => s + m.proteinG);
    final proteinTargetG =
        profile != null ? (profile.weightKg * 1.8).round() : 100;

    loadingNotifier.state = true;
    client
        .generatePerMealResponse(
      mealRawText: rawText,
      mealSummary: meal.summary,
      mealKcal: meal.kcal,
      mealProteinG: meal.proteinG,
      mealCarbsG: meal.carbsG,
      mealFatG: meal.fatG,
      safetyWarnings: meal.safetyWarnings,
      totalKcalToday: totalKcal,
      targetKcal: target,
      totalProteinToday: totalProtein,
      proteinTargetG: proteinTargetG,
      numChildrenNursing: profile?.numChildrenNursing ?? 0,
      milkSharePercent: profile?.milkSharePercent ?? 0,
    )
        .then((response) async {
      await threadRepo.add(ThreadItem.coachResponse(
        text: response.trim(),
        at: DateTime.now(),
      ));
      loadingNotifier.state = false;
    }).catchError((_) {
      loadingNotifier.state = false;
    });
  }

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

  Future<void> _askAsQuestion(String text) async {
    final threadRepo = ref.read(threadRepositoryProvider);
    final client = ref.read(claudeClientProvider);
    final loadingNotifier = ref.read(insightLoadingProvider.notifier);
    final meals = ref.read(todayMealsProvider);
    final mealsById = {for (final m in meals) m.id: m};
    final priorThread = ref.read(todayThreadProvider).valueOrNull ?? [];

    final history = _buildHistory(priorThread, mealsById)
      ..add(ChatTurn(isUser: true, text: text));
    final todayContext = _buildContext();

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
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasImage = _imageBytes != null;
    if (text.isEmpty && !hasImage) return;
    if (_sending) return;

    setState(() => _sending = true);
    FocusScope.of(context).unfocus();

    try {
      final client = ref.read(claudeClientProvider);

      if (hasImage) {
        // Photo entry: always show confirm sheet for portion review.
        final parsed = await client.parseMeal(text, imageBytes: _imageBytes);
        if (!mounted) return;
        if (!parsed.isMeal) {
          // Photo doesn't classify as meal; rare. Treat as question with note.
          await _askAsQuestion(text.isEmpty
              ? 'Konnte das Foto nicht als Mahlzeit erkennen.'
              : text);
        } else {
          await showModalBottomSheet<MealEntry>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => ConfirmScreen(
              rawText: text,
              parsed: parsed,
              imageBytes: _imageBytes,
              asSheet: true,
            ),
          );
        }
      } else {
        // Text only: route based on Claude classification.
        final parsed = await client.parseMeal(text);
        if (!mounted) return;
        if (parsed.isMeal) {
          final meal = MealEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            rawText: text,
            summary: parsed.summary,
            kcal: parsed.kcal,
            proteinG: parsed.proteinG,
            carbsG: parsed.carbsG,
            fatG: parsed.fatG,
            safetyWarnings: parsed.safetyWarnings,
          );
          await _saveAndCoach(meal, rawText: text);
        } else {
          await _askAsQuestion(text);
        }
      }
      _controller.clear();
      if (mounted) setState(() => _imageBytes = null);
    } catch (e) {
      // Surface error as coach answer so user sees something happened
      await ref.read(threadRepositoryProvider).add(ThreadItem.coachAnswer(
            text: 'Fehler: $e',
            at: DateTime.now(),
          ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final favorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <FavoriteMeal>[];

    return Material(
      color: scheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (favorites.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final f = favorites[i];
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteFavorite(f),
                        child: ActionChip(
                          avatar: Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber.shade700),
                          label: Text(f.summary),
                          onPressed: _sending ? null : () => _useFavorite(f),
                        ),
                      );
                    },
                  ),
                ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _sending
                              ? null
                              : () => setState(() => _imageBytes = null),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.close,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _sending ? null : _showPhotoPicker,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    tooltip: 'Foto hinzufügen',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText:
                            'Eintrag oder Frage an den Coach...',
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
                  const SizedBox(width: 6),
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
            ],
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
