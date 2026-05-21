import 'package:flutter/material.dart';

import '../../theme/nourishme_colors.dart';
import '../nm_icons.dart';

// Empty state for the Verlauf tab when no day has data yet.
// Spec: handoff/testflight_1_1/README.md "Verlauf (leer)".
class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
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
              child: NMIcons.journal(size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Der Verlauf beginnt heute.',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            const _GhostChart(),
          ],
        ),
      ),
    );
  }
}

class _GhostChart extends StatelessWidget {
  const _GhostChart();

  static const _labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const _heights = [22.0, 36.0, 18.0, 44.0, 30.0, 26.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in _heights)
                Container(
                  width: 22,
                  height: h,
                  decoration: BoxDecoration(
                    color: NMColors.paperLo,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _labels)
                SizedBox(
                  width: 22,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: NMColors.inkMute,
                      fontFeatures: const [],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
