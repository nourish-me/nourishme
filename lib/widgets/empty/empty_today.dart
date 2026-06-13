import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../nm_icons.dart';

// First-meal-of-the-day empty state for the Tagebuch.
// Spec: handoff/testflight_1_1/README.md "Heute (leer)".
//
// The [isPast] flag swaps in past-tense copy so a past day that's empty
// reads as a recap ("Nothing logged") instead of an active prompt
// ("What did you eat today?"). Visual treatment - dotted border, icon
// tile, italic headline - stays identical so the empty state feels
// consistent regardless of which day the user is on.
class EmptyToday extends StatelessWidget {
  final bool isPast;
  const EmptyToday({super.key, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final headline = isPast ? l10n.emptyPastDayHeadline : l10n.emptyTodayHeadline;
    final body = isPast ? l10n.emptyPastDayBody : l10n.emptyTodayBody;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: _DottedBorderBox(
        color: scheme.outlineVariant,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                child: NMIcons.meal(size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;
  const _DottedBorderBox({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    const radius = 16.0;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance = end + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
