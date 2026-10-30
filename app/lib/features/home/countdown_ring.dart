import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'home_motion.dart';

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
    final overdue = days != null && days < 0 && !paused;
    final label = paused || days == null
        ? '–'
        : days < 0
        ? '!'
        : days > 99
        ? '99+'
        : '$days';
    final reduced = HomeMotion.reduced(context);
    final ringDuration = HomeMotion.of(context, HomeMotion.ring);
    // Draws in from empty when the tile appears, then glides to each new
    // length and colour (a charge paid, a new day).
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: _grey, end: color),
        duration: ringDuration,
        curve: HomeMotion.curve,
        builder: (context, animatedColor, _) =>
            TweenAnimationBuilder<(double, double)>(
              tween: _ArcTween(
                begin: (0, 0),
                end: (paused ? 0 : elapsed, paused ? 0 : overdueLap),
              ),
              duration: ringDuration,
              curve: HomeMotion.curve,
              builder: (context, arcs, _) {
                final ring = CustomPaint(
                  painter: _RingPainter(
                    color: animatedColor ?? color,
                    progress: arcs.$1,
                    lap: arcs.$2,
                  ),
                  child: Center(
                    // A fixed-size glyph inside the ring; the tile's label
                    // carries the same information for screen readers and
                    // large text.
                    child: MediaQuery.withNoTextScaling(
                      child: AnimatedSwitcher(
                        duration: HomeMotion.of(context, HomeMotion.fade),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.6,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          label,
                          key: ValueKey(label),
                          style: TextStyle(
                            fontSize: size * 0.33,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: overdue ? color : textColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                return overdue && !reduced
                    ? _OverduePulse(color: color, child: ring)
                    : ring;
              },
            ),
      ),
    );
  }
}

/// Tweens the main arc and the overdue lap together.
class _ArcTween extends Tween<(double, double)> {
  _ArcTween({required super.begin, required super.end});

  @override
  (double, double) lerp(double t) => (
    begin!.$1 + (end!.$1 - begin!.$1) * t,
    begin!.$2 + (end!.$2 - begin!.$2) * t,
  );
}

/// A slow red glow breathing behind an overdue ring.
class _OverduePulse extends StatefulWidget {
  const _OverduePulse({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_OverduePulse> createState() => _OverduePulseState();
}

class _OverduePulseState extends State<_OverduePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + 0.3 * t),
                blurRadius: 4 + 6 * t,
                spreadRadius: 0.5 * t,
              ),
            ],
          ),
          child: child,
        );
      },
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
