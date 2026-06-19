import 'package:flutter/material.dart';

// Shared "Calculated for you" card. Used wherever the app surfaces a
// value derived from the user's profile (kcal target in onboarding
// Schritt 7, daily milk volume estimate in Schritt 5, future "we
// computed this" surfaces). Replaces the +36 green-tinted box + ✨
// icon + "Schätzung" badge.
//
// Anatomy:
//   surfaceContainerLow background, 16px radius, hairline outlineVariant
//   eyebrow row: small functional icon (primary) + Mono uppercase label
//   optional titleMedium under the eyebrow
//   child slot for the actual content (read-only value, or value + slider)
class ComputedCard extends StatelessWidget {
  final String eyebrow;
  final String? title;
  final Widget child;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  const ComputedCard({
    super.key,
    required this.eyebrow,
    this.title,
    required this.child,
    this.icon = Icons.calculate_outlined,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: scheme.primary),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
