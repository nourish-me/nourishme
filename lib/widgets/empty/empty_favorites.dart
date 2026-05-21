import 'package:flutter/material.dart';

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
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star_outline_rounded,
              size: 48,
              color: scheme.secondary,
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
              'Tippe beim Mahlzeit-Loggen auf den Stern, um eine '
              'Mahlzeit als Favorit zu speichern.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Inline example row showing the affordance.
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.surfaceContainerLow,
                  child: Icon(
                    Icons.lunch_dining_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
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
                  color: scheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
