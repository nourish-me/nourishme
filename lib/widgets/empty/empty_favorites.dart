import 'package:flutter/material.dart';

import '../../theme/nourishme_colors.dart';

// Empty state for the Favoriten section in Settings.
// Spec: handoff/testflight_1_1/README.md "Favoriten (leer)".
class EmptyFavorites extends StatelessWidget {
  const EmptyFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: NMColors.paperHi,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NMColors.rule, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star_outline_rounded,
              size: 48,
              color: NMColors.amber,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Favoriten.',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Tippe in einer Mahlzeit auf den Stern, um sie zu speichern.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: NMColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Inline example row showing the affordance.
          Container(
            decoration: BoxDecoration(
              color: NMColors.paperHi,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NMColors.rule, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: NMColors.paperLo,
                  child: Icon(
                    Icons.lunch_dining_outlined,
                    size: 16,
                    color: NMColors.inkSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Müsli mit Beeren',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.star_outline_rounded,
                  size: 18,
                  color: NMColors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
