import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../l10n/app_localizations.dart';
import '../../models/meal_entry.dart';
import '../../utils/number_format.dart';
import '../../widgets/edit_hint_icon.dart';

// Per-meal row in the diary thread. Tap = edit (acts as a read-only
// detail-view since the edit sheet shows macros + portion + time), swipe
// left for edit / duplicate / delete actions.

class ThreadMealCard extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ThreadMealCard({
    super.key,
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
        extentRatio: 0.55,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit_outlined,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            icon: Icons.copy_outlined,
            backgroundColor: scheme.tertiaryContainer,
            foregroundColor: scheme.onTertiaryContainer,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete_outline,
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
          // Tap opens the same sheet as the slidable "edit" action so the
          // full nutrition values and meal time become visible without
          // committing to changes. Subtitle stays minimal (just time) -
          // macros are one tap away in the detail sheet.
          onTap: onEdit,
          title: Text(meal.summary),
          subtitle: Text(timeLabel),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (meal.safetyWarnings.isNotEmpty) ...[
                _WarningIconButton(warnings: meal.safetyWarnings),
                const SizedBox(width: 4),
              ],
              Text(
                '${formatKcal(meal.kcal)} kcal',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Trailing edit hint so the user discovers that the whole
              // row is tappable. Beta feedback: testers thought the meal
              // title was read-only without this cue.
              const EditHintIcon(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningIconButton extends StatelessWidget {
  final List<String> warnings;
  const _WarningIconButton({required this.warnings});

  void _show(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).homeMealHintsHeader,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: scheme.outline)),
                      Expanded(
                        child: Text(w,
                            style: textTheme.bodyMedium?.copyWith(height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.warning_amber, size: 20),
      color: Theme.of(context).colorScheme.tertiary,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Hinweis ansehen',
      onPressed: () => _show(context),
    );
  }
}
