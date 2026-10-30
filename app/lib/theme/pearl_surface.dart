import 'package:material_ui/material_ui.dart';

import 'palette.dart';

/// The pearl sheen surface. Only for the home total card and the Pro badge;
/// everything else in the UI stays flat.
///
/// With [sheen], a soft band of light sweeps across once when the surface
/// appears (not under the system "remove animations" setting). The optional
/// tilt-driven sheen needs a sensor package and is scheduled for M7 polish.
class PearlSurface extends StatefulWidget {
  const PearlSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(20),
    this.sheen = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool sheen;

  @override
  State<PearlSurface> createState() => _PearlSurfaceState();
}

class _PearlSurfaceState extends State<PearlSurface>
    with SingleTickerProviderStateMixin {
  AnimationController? _sweep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.sheen || reduced || _sweep != null) return;
    final sweep = _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) sweep.forward();
    });
  }

  @override
  void dispose() {
    _sweep?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(color: palette.divider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.pearl,
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
    final sweep = _sweep;
    if (sweep == null) return surface;
    final light = palette.brightness == Brightness.light;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AnimatedBuilder(
        animation: sweep,
        child: surface,
        builder: (context, child) => CustomPaint(
          foregroundPainter: sweep.isAnimating
              ? _SheenPainter(
                  t: Curves.easeInOutCubic.transform(sweep.value),
                  color: light
                      ? const Color(0x8CFFFFFF)
                      : const Color(0x14FFFFFF),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

/// A diagonal band of light at position [t] (0 = off the left, 1 = off the
/// right).
class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.45;
    final x = -band + (size.width + band * 2) * t;
    final clear = color.withValues(alpha: 0);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-1, -0.4),
        end: const Alignment(1, 0.4),
        colors: [clear, color, clear],
      ).createShader(Rect.fromLTWH(x - band, 0, band * 2, size.height));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t || old.color != color;
}
