import 'package:flutter/material.dart';

// Subtle trailing affordance that says "tap this row to edit it". Used on
// cards whose body looks read-only (ThreadMealCard, FavoriteListTile,
// supplements list item) so the user actually discovers the edit sheet
// behind the tap. Not a button: the card itself owns the tap target,
// this is just the visual hint.
//
// Convention across the app:
//   "+"            = add a new thing            (DaySeparator, EmptyDayRange)
//   edit_outlined  = tap this row opens edit    (this widget)
//   chevron_right  = drill into a separate page (Settings hub tiles)
//
// Keep it small and outline-colored so it reads as metadata, not as a
// CTA competing with the row's primary content (title + kcal).
class EditHintIcon extends StatelessWidget {
  const EditHintIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Icon(
        Icons.edit_outlined,
        size: 16,
        color: scheme.outline,
      ),
    );
  }
}
