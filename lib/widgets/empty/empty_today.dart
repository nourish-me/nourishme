import 'package:flutter/material.dart';

import '../../theme/nourishme_colors.dart';
import '../nm_icons.dart';

// First-meal-of-the-day empty state for the Tagebuch.
// Spec: handoff/testflight_1_1/README.md "Heute (leer)".
// Not yet wired into home_screen; ready for use when first-launch flow
// is restructured.
class EmptyToday extends StatelessWidget {
  const EmptyToday({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                child: NMIcons.meal(size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Was hast du heute gegessen?',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tipp einfach drauf los, der Coach erkennt den Rest.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: NMColors.inkSoft,
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

// Simple dashed-border container, no extra deps.
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: NMColors.rule),
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
