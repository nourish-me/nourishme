import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/nutrition_facts.dart';

// Small ⓘ button that opens a bottom sheet with a short scientific
// explanation plus the source. Used in Onboarding and Settings to make the
// app's scientific basis transparent without crowding the input fields.
class InfoButton extends StatelessWidget {
  final NutritionFact fact;
  final String? overrideTitle;

  const InfoButton({super.key, required this.fact, this.overrideTitle});

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _InfoSheet(
        fact: fact,
        title: overrideTitle ?? fact.topic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.info_outline, color: scheme.outline, size: 20),
      tooltip: 'Hintergrund',
      visualDensity: VisualDensity.compact,
      onPressed: () => _open(context),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  final NutritionFact fact;
  final String title;
  const _InfoSheet({required this.fact, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fact.summary,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              fact.detail,
              style: textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 14, color: scheme.outline),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${AppLocalizations.of(context).infoSourceLabel}: ${fact.source}',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Convenience: a labeled row with the field label on the left and an
// InfoButton on the right. Use above a TextField/SegmentedButton when you
// want the ⓘ to sit next to its label.
class LabelWithInfo extends StatelessWidget {
  final String label;
  final NutritionFact fact;

  const LabelWithInfo({super.key, required this.label, required this.fact});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        InfoButton(fact: fact, overrideTitle: label),
      ],
    );
  }
}
