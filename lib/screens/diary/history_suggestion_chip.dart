import 'package:flutter/material.dart';

import '../../models/meal_entry.dart';

// One chip in the history-suggestion row above the diary input. Uses the
// same InputChip shape and height as the favourites row so the two rows
// stack visually as one consistent suggestion strip - distinguished only
// by the icon (history vs star) so the user knows the source. No delete
// affordance because the user can't "unsuggest" a past meal log.
class HistorySuggestionChip extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onTap;
  const HistorySuggestionChip(
      {super.key, required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final amount = meal.portionAmount > 0
        ? ', ${meal.portionAmount.toStringAsFixed(0)} ${meal.portionUnit}'
        : '';
    return InputChip(
      // History icon (vs star on favourites) is the only differentiator -
      // the relative-time suffix on the label felt like a data-record;
      // the icon already conveys "from before" without the timestamp.
      avatar: Icon(Icons.history, size: 14, color: scheme.secondary),
      label: Text(
        '${meal.summary}$amount',
        style: textTheme.labelSmall,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: onTap,
    );
  }
}
