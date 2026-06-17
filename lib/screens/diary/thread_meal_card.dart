import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../models/meal_entry.dart';
import '../../services/safety_rules.dart';
import '../../utils/number_format.dart';

// Per-meal row in the diary thread — Time-Ledger layout (phase 3 of the
// Claude Design diary refactor). NOT a card any more: a flat row with a
// fixed ~44 px time column on the left (Mono digits), name in the middle,
// kcal on the right. Rows are separated by a hairline divider; the time
// column reads top-to-bottom as a single column across the whole day.
//
// Tap = edit. Swipe left for edit / duplicate / delete (Slidable). The
// row keeps the warning-icon button when the meal has safety hints; it
// sits between the name and kcal so it doesn't push the kcal column off
// alignment with neighbouring rows.

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
      child: InkWell(
        onTap: onEdit,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fixed ~44 px time column. Mono digits, outline color,
                // uppercase letter-spacing so the column reads as a
                // single vertical track when stacked.
                SizedBox(
                  width: 44,
                  child: Text(
                    timeLabel,
                    style: GoogleFonts.jetBrainsMono(
                      textStyle: textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                // Breathing gap between time column and meal name - 44 px
                // alone reads cramped against a long summary.
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.summary,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (meal.safetyWarnings.isNotEmpty) ...[
                  _WarningIconButton(warnings: meal.safetyWarnings),
                  const SizedBox(width: 2),
                ],
                Text(
                  '${formatKcal(meal.kcal)} kcal',
                  style: GoogleFonts.jetBrainsMono(
                    textStyle: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
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
    final isCritical = SafetyRules.highestSeverity(warnings) ==
        SafetyWarningSeverity.critical;
    final headerColor = isCritical ? scheme.error : scheme.tertiary;
    final headerIcon = isCritical ? Icons.error : Icons.warning_amber;
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
                  Icon(headerIcon, color: headerColor),
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
    final scheme = Theme.of(context).colorScheme;
    final isCritical = SafetyRules.highestSeverity(warnings) ==
        SafetyWarningSeverity.critical;
    return IconButton(
      icon: Icon(isCritical ? Icons.error : Icons.warning_amber, size: 20),
      color: isCritical ? scheme.error : scheme.tertiary,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: 'Hinweis ansehen',
      onPressed: () => _show(context),
    );
  }
}
