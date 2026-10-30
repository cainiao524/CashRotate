import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The countdown ring on a home tile: its length is the share of the
/// billing period already gone, the centre shows the days left.
///
/// More than 14 days out it is grey; within 14 days its hue runs from
/// yellow through orange to red; overdue it is a full red ring plus an
/// extra lap that grows with the days overdue. Paused shows only the faint
/// track. This is the only component allowed a shifting hue.
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.daysLeft,
    required this.elapsed,
    required this.overdueLap,
    required this.onDark,
    required this.textColor,
    this.paused = false,
    this.size = 32,
  });

  /// Null without a next charge; negative once overdue.
  final int? daysLeft;
  final double elapsed;
  final double overdueLap;

  /// Drawn on a dark tile: lighter hues keep their contrast.
  final bool onDark;
  final Color textColor;
  final bool paused;
  final double size;

  static const _grey = Color(0xFF8E8E93);

  /// Ring colour for [daysLeft] on a light or dark tile.
  static Color colorFor(int? daysLeft, {required bool onDark}) {
    if (daysLeft == null || daysLeft > 14) return _grey;
    if (daysLeft < 0) {
      return onDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    }
    final t = (14 - daysLeft) / 14;
    final (from, to) = onDark
        ? (const (50.0, 1.0, 0.52), const (3.0, 1.0, 0.61))
        : (const (48.0, 1.0, 0.50), const (3.0, 1.0, 0.59));
    double lerp(double a, double b) => a + (b - a) * t;
    return HSLColor.fromAHSL(
      1,
      lerp(from.$1, to.$1),
      lerp(from.$2, to.$2),
      lerp(from.$3, to.$3),
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(daysLeft, onDark: onDark);
    final days = daysLeft;
    final label = paused || days == null
        ? '–'
        : days < 0
        ? '!'
        : days > 99
        ? '99+'
        : '$days';
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          color: color,
          progress: paused ? 0 : elapsed,
          lap: paused ? 0 : overdueLap,
        ),
        child: Center(
          // A fixed-size glyph inside the ring; the tile's label carries the
          // same information for screen readers and large text.
          child: MediaQuery.withNoTextScaling(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.33,
                fontWeight: FontWeight.w800,
                height: 1,
                color: days != null && days < 0 && !paused ? color : textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.color,
    required this.progress,
    required this.lap,
  });

  final Color color;
  final double progress;
  final double lap;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 8;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + size.width / 32);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      paint..color = color.withValues(alpha: 0.22),
    );
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint..color = color,
      );
    }
    if (lap > 0) {
      // A thin shadow separates the second lap from the full ring under it.
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * lap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 1.5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x73000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * lap,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.progress != progress || old.lap != lap;
}
