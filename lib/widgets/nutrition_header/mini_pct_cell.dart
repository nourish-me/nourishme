import 'package:flutter/material.dart';

// Compact cell used by NutritionHeader for both macros and micros.
// Two-element layout: a name+pct row on top, a slim 2.5px bar below.
// The whole cell is one tap target ≥44pt → opens a detail modal.
//
// The cell is intentionally type-agnostic: color, markers, italic, and
// awareness behavior are passed in by the parent. Macros use the
// sweet-spot rule (corridor moss/amber); micros use the state rule
// (progress amber → met pine → over plum). One cell shape, one
// visual language, two coloring systems.
class MiniPctCell extends StatelessWidget {
  final String name;
  // Percent rounded to an integer (0..200+). The pct text itself is shown
  // unless [pctOverridesText] supplies a glyph (e.g. ✓ when met).
  final double percent;
  // Color shared by the pct text and the bar fill — passed in so the
  // parent owns the color rule.
  final Color color;
  // Bar track color, defaults to surfaceContainerHighest in build if
  // not provided.
  final Color? trackColor;
  // Replaces the "%" text with a widget — used for the ✓ met-state
  // glyph. When non-null, [percent] is ignored for the right-side
  // label (it's still used for the bar width).
  final Widget? pctOverridesText;
  // Optional trailing markers next to the name (leaf for diet-adapted,
  // "+" for supplement, "i" for awareness).
  final List<Widget> nameTrailing;
  // Italic name (awareness nutrient).
  final bool italic;
  // Awareness bar uses a dashed track + thinner solid fill instead of
  // the standard solid track + full-height fill.
  final bool dashedTrack;
  final VoidCallback? onTap;

  const MiniPctCell({
    super.key,
    required this.name,
    required this.percent,
    required this.color,
    this.trackColor,
    this.pctOverridesText,
    this.nameTrailing = const [],
    this.italic = false,
    this.dashedTrack = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pctClamped = percent.clamp(0.0, 200.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: scheme.onSurface,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                      height: 1.1,
                    ),
                  ),
                ),
                ...nameTrailing.map((w) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: w,
                    )),
                const Spacer(),
                if (pctOverridesText != null)
                  pctOverridesText!
                else
                  Text(
                    '${percent.round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                      height: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // The bar — solid track + solid fill for the normal case,
            // dashed track + thinner solid fill for awareness.
            SizedBox(
              height: 2.5,
              child: dashedTrack
                  ? CustomPaint(
                      painter: _DashedBarPainter(
                        trackColor:
                            (trackColor ?? scheme.surfaceContainerHighest)
                                .withValues(alpha: 0.5),
                        fillColor: color,
                        fillFraction: (pctClamped / 100).clamp(0.0, 1.0),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (pctClamped / 100).clamp(0.0, 1.0),
                        minHeight: 2.5,
                        backgroundColor:
                            trackColor ?? scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBarPainter extends CustomPainter {
  final Color trackColor;
  final Color fillColor;
  final double fillFraction; // 0..1

  _DashedBarPainter({
    required this.trackColor,
    required this.fillColor,
    required this.fillFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dashed track underneath.
    const dashLen = 3.0;
    const gapLen = 2.5;
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.butt;
    var x = 0.0;
    while (x < size.width) {
      final endX = (x + dashLen).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(endX, size.height / 2),
        trackPaint,
      );
      x += dashLen + gapLen;
    }
    // Solid fill over the dashes — keeps the "no hard target" cue
    // visible at the gap end while still reporting the value.
    if (fillFraction > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..strokeWidth = size.height
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width * fillFraction, size.height / 2),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBarPainter old) =>
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.fillFraction != fillFraction;
}
