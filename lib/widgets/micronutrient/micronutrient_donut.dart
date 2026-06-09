import 'dart:math' as math;

import 'package:flutter/material.dart';

// Five visual states for the micronutrient progress ring. The cell's
// label appearance follows from this too - see MicronutrientCell.
enum MicronutrientState {
  empty,      // 0% - track only, no arc
  progress,   // 0 < pct < 100 - amber arc
  met,        // pct >= 100 - full arc + check
  over,       // pct > UL - full arc in tertiary (plum)
  awareness,  // no DGE target (e.g. choline) - dashed track + slim arc
}

// Computes the state from raw intake/target. Caller decides whether
// awareness applies (driven by MicronutrientDisplay.awareness from the
// targets table); when awareness=true, the over case is suppressed
// because awareness nutrients don't have ULs we surface here.
MicronutrientState micronutrientStateFor({
  required double intake,
  required double target,
  required bool awareness,
  required bool hasUpperLimit,
  double upperLimitMultiplier = 1.0,
}) {
  if (awareness) return MicronutrientState.awareness;
  if (intake <= 0) return MicronutrientState.empty;
  if (hasUpperLimit && intake > target * upperLimitMultiplier) {
    return MicronutrientState.over;
  }
  if (intake >= target) return MicronutrientState.met;
  return MicronutrientState.progress;
}

// 44 × 44 donut showing one micronutrient's progress toward its daily
// target. Per the design handoff: stroke 6, arc starts at 12 o'clock
// clockwise, single accent (secondary / amber) across all nutrients
// regardless of which one. State carries the meaning; the label
// distinguishes which nutrient.
//
// supplementContribution renders a tiny "+" badge top-right when the
// intake total includes any logged daily-supplement value. Same amber
// hue so we keep the single-accent rule.
class MicronutrientDonut extends StatelessWidget {
  final MicronutrientState state;
  final double percent; // 0..100+ - for the center label only
  final bool hasSupplement;
  // Override the default 44px size. Used by the collapsed mini-strip
  // (24px) where the same visual rules apply but at a smaller scale.
  final double size;
  // Stroke width - defaults to 6 for the full strip donut, 3.5 for the
  // mini-strip donut.
  final double strokeWidth;
  // The mini-strip variant drops the center label entirely (the label
  // is rendered as a separate row beneath the donut).
  final bool showCenterLabel;

  const MicronutrientDonut({
    super.key,
    required this.state,
    required this.percent,
    this.hasSupplement = false,
    this.size = 44,
    this.strokeWidth = 6,
    this.showCenterLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              state: state,
              percent: percent,
              trackColor: scheme.surfaceContainerHighest,
              accentColor: scheme.secondary,
              overColor: scheme.tertiary,
              awarenessOutlineColor: scheme.outline,
              strokeWidth: strokeWidth,
            ),
          ),
          if (showCenterLabel) _CenterLabel(state: state, percent: percent),
          if (hasSupplement)
            Positioned(
              top: -2,
              right: -2,
              child: _SupplementBadge(color: scheme.secondary),
            ),
        ],
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  final MicronutrientState state;
  final double percent;
  const _CenterLabel({required this.state, required this.percent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (state) {
      case MicronutrientState.empty:
        // Nothing - track-only donut reads as "no intake yet".
        return const SizedBox.shrink();
      case MicronutrientState.met:
        return Icon(Icons.check, size: 20, color: scheme.primary, weight: 700);
      case MicronutrientState.over:
        return _PercentText(
          percent: percent,
          color: scheme.tertiary,
          italic: false,
        );
      case MicronutrientState.awareness:
        return _PercentText(
          percent: percent,
          color: scheme.secondary,
          italic: true,
        );
      case MicronutrientState.progress:
        return _PercentText(
          percent: percent,
          color: scheme.secondary,
          italic: false,
        );
    }
  }
}

class _PercentText extends StatelessWidget {
  final double percent;
  final Color color;
  final bool italic;
  const _PercentText({
    required this.percent,
    required this.color,
    required this.italic,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${percent.round()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: '%',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              height: 1.0,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SupplementBadge extends StatelessWidget {
  final Color color;
  const _SupplementBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
      child: Center(
        child: Icon(Icons.add, size: 10, color: scheme.onSecondary),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final MicronutrientState state;
  final double percent;
  final Color trackColor;
  final Color accentColor;
  final Color overColor;
  final Color awarenessOutlineColor;
  final double strokeWidth;

  _DonutPainter({
    required this.state,
    required this.percent,
    required this.trackColor,
    required this.accentColor,
    required this.overColor,
    required this.awarenessOutlineColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Track ring - solid for normal states, dashed for awareness.
    if (state == MicronutrientState.awareness) {
      _drawDashedCircle(
        canvas,
        rect,
        awarenessOutlineColor.withValues(alpha: 0.6),
        // Thinner outline for awareness so the slim arc still stands out.
        strokeWidth * 0.34,
        dashLen: 2.5,
        gapLen: 3.5,
      );
    } else {
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawCircle(rect.center, rect.width / 2, trackPaint);
    }

    // Progress arc - color and thickness vary by state.
    if (state == MicronutrientState.empty) return;
    final arcColor = state == MicronutrientState.over ? overColor : accentColor;
    final arcStroke = state == MicronutrientState.awareness
        ? strokeWidth * 0.67 // slim solid arc layered over dashed track
        : strokeWidth;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcStroke
      ..strokeCap = StrokeCap.round
      ..color = arcColor;
    final clampedPct = math.min(100, math.max(0, percent)) / 100;
    final sweep = clampedPct * 2 * math.pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2, // start at 12 o'clock
      sweep,
      false,
      arcPaint,
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Rect rect,
    Color color,
    double stroke, {
    required double dashLen,
    required double gapLen,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = color;
    final radius = rect.width / 2;
    final circumference = 2 * math.pi * radius;
    final segmentLen = dashLen + gapLen;
    final segmentCount = (circumference / segmentLen).floor();
    if (segmentCount <= 0) return;
    final actualGap = (circumference - segmentCount * dashLen) / segmentCount;
    final dashAngle = (dashLen / circumference) * 2 * math.pi;
    final gapAngle = (actualGap / circumference) * 2 * math.pi;
    var startAngle = -math.pi / 2;
    for (var i = 0; i < segmentCount; i++) {
      canvas.drawArc(rect, startAngle, dashAngle, false, paint);
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.state != state ||
      old.percent != percent ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.accentColor != accentColor ||
      old.overColor != overColor ||
      old.awarenessOutlineColor != awarenessOutlineColor;
}
