import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/meal_entry_source.dart';
import '../../services/claude_client.dart';
import '../confirm_screen.dart';

// One item in the multi-photo review list (Task #105). Held by value so
// the parent can rebuild the list on edit/discard without losing state
// of items not touched. Discarded items are KEPT in the list with
// `discarded = true` so the discard action is undoable while the user
// is still on this screen; the bulk-save filters them out.
class MultiPhotoItem {
  final Uint8List bytes;
  final MealParseResult parsed;
  final DateTime mealTime;
  final String rawText;
  final bool discarded;

  // null means parseMeal succeeded; non-null is the reason this item is
  // shown greyed-out with a "skipped" badge instead of an editable row.
  final String? skippedReason;

  const MultiPhotoItem({
    required this.bytes,
    required this.parsed,
    required this.mealTime,
    this.rawText = '',
    this.discarded = false,
    this.skippedReason,
  });

  MultiPhotoItem copyWith({
    MealParseResult? parsed,
    DateTime? mealTime,
    String? rawText,
    bool? discarded,
  }) =>
      MultiPhotoItem(
        bytes: bytes,
        parsed: parsed ?? this.parsed,
        mealTime: mealTime ?? this.mealTime,
        rawText: rawText ?? this.rawText,
        discarded: discarded ?? this.discarded,
        skippedReason: skippedReason,
      );
}

// Full-screen review for the bulk-photo flow. Shows each parsed item as
// a row with thumbnail, auto-detected title + kcal + time + edit + discard
// toggle. Per-item edit opens ConfirmScreen in editOnly mode (#112) which
// pops with a ConfirmScreenDraft (no Hive write); the merged draft lands
// back in the item list. Save All emits the non-discarded list to the
// caller, which routes them through meal-repository + coach session.
class MultiPhotoReviewScreen extends StatefulWidget {
  final List<MultiPhotoItem> items;
  const MultiPhotoReviewScreen({super.key, required this.items});

  @override
  State<MultiPhotoReviewScreen> createState() => _MultiPhotoReviewScreenState();
}

class _MultiPhotoReviewScreenState extends State<MultiPhotoReviewScreen> {
  late List<MultiPhotoItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  int get _liveCount =>
      _items.where((i) => !i.discarded && i.skippedReason == null).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initialCount = widget.items
        .where((i) => i.skippedReason == null)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.multiPhotoReviewTitle(initialCount)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.multiPhotoReviewHint,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Builder(builder: (_) {
                // Show date prefix on each row only when the picked set
                // spans more than one day - otherwise the time alone
                // already tells the user everything they need.
                final liveDays = _items
                    .where((i) => i.skippedReason == null)
                    .map((i) => DateTime(i.mealTime.year, i.mealTime.month,
                        i.mealTime.day))
                    .toSet();
                final crossDay = liveDays.length > 1;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _ItemRow(
                    item: _items[index],
                    showDate: crossDay,
                    onEdit: () => _editItem(index),
                    onDiscard: () => _toggleDiscard(index),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _liveCount == 0 ? null : _saveAll,
              child: Text(l10n.multiPhotoReviewSaveAll(_liveCount)),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDiscard(int index) {
    final item = _items[index];
    if (item.skippedReason != null) return;
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i == index) item.copyWith(discarded: !item.discarded) else _items[i],
      ];
    });
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    if (item.skippedReason != null) return;
    // Opens the existing ConfirmScreen in editOnly mode (#112). Pops with
    // a ConfirmScreenDraft (parsed + mealTime) without persisting; we
    // merge the edits back into the list item so the bulk save picks
    // them up. Dismissing the sheet (returning null) leaves the item
    // unchanged.
    final draft = await showModalBottomSheet<ConfirmScreenDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfirmScreen(
        rawText: item.rawText,
        parsed: item.parsed,
        imageBytes: item.bytes,
        suggestedCreatedAt: item.mealTime,
        editOnly: true,
        asSheet: true,
        source: MealEntrySource.photo,
      ),
    );
    if (!mounted || draft == null) return;
    setState(() {
      _items = [
        for (var i = 0; i < _items.length; i++)
          if (i == index)
            _items[i].copyWith(parsed: draft.parsed, mealTime: draft.mealTime)
          else
            _items[i],
      ];
    });
  }

  void _saveAll() {
    final keepers =
        _items.where((i) => !i.discarded && i.skippedReason == null).toList();
    Navigator.of(context).pop(keepers);
  }
}

class _ItemRow extends StatelessWidget {
  final MultiPhotoItem item;
  // When the picked set spans multiple days, render a short date prefix
  // before the time so the user can tell apart "yesterday 18:30" from
  // "today 18:30" without opening each row.
  final bool showDate;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;
  const _ItemRow({
    required this.item,
    required this.showDate,
    required this.onEdit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSkipped = item.skippedReason != null;
    final isDiscarded = item.discarded;
    final muted = isSkipped || isDiscarded;
    final timeStr =
        '${item.mealTime.hour.toString().padLeft(2, '0')}:${item.mealTime.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mealDay =
        DateTime(item.mealTime.year, item.mealTime.month, item.mealTime.day);
    final isDe = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('de');
    String dayPrefix = '';
    if (showDate) {
      final dayDiff = today.difference(mealDay).inDays;
      if (dayDiff == 0) {
        dayPrefix = isDe ? 'heute · ' : 'today · ';
      } else if (dayDiff == 1) {
        dayPrefix = isDe ? 'gestern · ' : 'yesterday · ';
      } else if (dayDiff == -1) {
        dayPrefix = isDe ? 'morgen · ' : 'tomorrow · ';
      } else {
        dayPrefix = '${mealDay.day}.${mealDay.month}. · ';
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: muted ? scheme.outlineVariant : scheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Opacity(
        opacity: muted ? 0.55 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                item.bytes,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSkipped
                        ? item.skippedReason!
                        : item.parsed.summary.isEmpty
                            ? '...'
                            : item.parsed.summary,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isDiscarded ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSkipped) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$dayPrefix$timeStr · ${item.parsed.kcal} kcal',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                if (!isSkipped)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.multiPhotoReviewEditItem,
                    onPressed: onEdit,
                  ),
                IconButton(
                  icon: Icon(
                    isDiscarded ? Icons.restore : Icons.close,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.multiPhotoReviewDiscardItem,
                  onPressed: isSkipped ? null : onDiscard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
