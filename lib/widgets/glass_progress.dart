import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// GlassProgress: "el vaso", a glass that fills with liquid as people pay.
///
/// It is drawn by hand with a [CustomPainter] (no images) and the liquid
/// level is animated with a [TweenAnimationBuilder]: when [percent] changes,
/// the level slides smoothly from the old value to the new one.
///
/// Parameters:
/// - [percent]: 0..100 (values outside are clamped).
/// - [width] / [height]: size of the glass; the painter scales to fit.
///
/// Used in: CollectedCard (results screen, big) and VacaTile (home list, small).
class GlassProgress extends StatelessWidget {
  const GlassProgress({
    super.key,
    required this.percent,
    this.width = 110,
    this.height = 140,
    this.showLabel = true,
  });

  final int percent;
  final double width;
  final double height;

  /// Small glasses (in lists) hide the number to avoid tiny text.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0, 100);

    return Semantics(
      label: 'Recogido $value por ciento',
      child: SizedBox(
        width: width,
        height: height,
        child: TweenAnimationBuilder<double>(
          // The fraction is a double only for drawing; money stays int.
          tween: Tween(end: value / 100),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, level, _) => CustomPaint(
            painter: _GlassPainter(level: level),
            child: showLabel
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: height * 0.15),
                      child: Text(
                        '$value%',
                        style: TextStyle(
                          fontSize: height * 0.18,
                          fontWeight: FontWeight.w800,
                          // White text once the liquid is behind it.
                          color: level > 0.45 ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Draws the glass: a tumbler wider at the top, the liquid inside, a light
/// surface line on the liquid and the outline on top of everything.
class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.level});

  /// 0.0 (empty) .. 1.0 (full).
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = w * 0.12; // how much narrower the bottom is
    final r = w * 0.13; // radius of the bottom corners, scales with size

    // Shape of the glass: trapezoid with rounded bottom corners.
    final glass = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - inset, h - r)
      ..quadraticBezierTo(w - inset, h, w - inset - r, h)
      ..lineTo(inset + r, h)
      ..quadraticBezierTo(inset, h, inset, h - r)
      ..close();

    // 1. Glass background.
    canvas.drawPath(glass, Paint()..color = AppColors.primarySoft);

    // 2. Liquid: a rectangle from the bottom up to the level, clipped to
    //    the glass shape so it follows the slanted walls.
    if (level > 0) {
      final top = h - h * level;
      canvas.save();
      canvas.clipPath(glass);
      canvas.drawRect(
        Rect.fromLTRB(0, top, w, h),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B5CF6), AppColors.primary],
          ).createShader(Rect.fromLTRB(0, top, w, h)),
      );
      // Light line on the surface of the liquid.
      canvas.drawLine(
        Offset(0, top + 2),
        Offset(w, top + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 3,
      );
      canvas.restore();
    }

    // 3. Outline of the glass, drawn last so it stays on top.
    canvas.drawPath(
      glass,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // Repaint only when the level actually changed.
  @override
  bool shouldRepaint(_GlassPainter oldDelegate) => oldDelegate.level != level;
}
