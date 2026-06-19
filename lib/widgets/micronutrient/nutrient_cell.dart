import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'micronutrient_donut.dart';

// One-line inline micronutrient cell: name + percent + thin progress bar.
// Sister widget to MicronutrientDonut. Same single-accent state logic,
// different layout: horizontal for constrained spaces like the Verlauf
// day-tiles. Stays on ONE line; the name ellipsises if needed.
//
// State -> colour mapping (single-accent rule shared with the donut):
//   empty     -> outline (track only)
//   progress  -> secondary (amber)
//   met       -> primary (pine)
//   over      -> tertiary (plum)
//   awareness -> secondary italic (rendered like progress, sustained)
//
// Bar fill clamps to 100 even for extreme values (e.g. DHA 3250% from a
// salmon meal stays as a full pine bar, percent text remains legible).
class NutrientCell extends StatelessWidget {
  final String name;
  final double percent;
  final MicronutrientState state;

  const NutrientCell({
    super.key,
    required this.name,
    required this.percent,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stateColor = switch (state) {
      MicronutrientState.empty => scheme.outline,
      MicronutrientState.progress => scheme.secondary,
      MicronutrientState.awareness => scheme.secondary,
      MicronutrientState.met => scheme.primary,
      MicronutrientState.over => scheme.tertiary,
    };
    final fill = math.min(100, math.max(0, percent)) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                name,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${percent.round()}%',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: stateColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              Container(
                height: 2.5,
                color: scheme.surfaceContainerHighest,
              ),
              if (state != MicronutrientState.empty)
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(
                    height: 2.5,
                    color: stateColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
