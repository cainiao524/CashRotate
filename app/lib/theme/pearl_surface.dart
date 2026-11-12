import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/providers.dart';
import 'palette.dart';

/// The pearl sheen surface. Only for the home total card and the Pro badge;
/// everything else in the UI stays flat.
///
/// With [sheen], a band of light sweeps across once when the surface
/// appears; after that a softer band follows the phone's tilt, as light on
/// pearl would (CLAUDE.md: optional tilt sheen). Under the system "remove
/// animations" setting neither runs and the sensor stays off.
class PearlSurface extends ConsumerStatefulWidget {
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
  ConsumerState<PearlSurface> createState() => _PearlSurfaceState();
}

class _PearlSurfaceState extends ConsumerState<PearlSurface>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _sweep;

  /// Eases the band toward the latest tilt so sensor noise never shows.
  AnimationController? _follow;
  StreamSubscription<Offset>? _tilt;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _tilted = false;

  bool get _moving => widget.sheen && !_reduced;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_moving) {
      _stopTilt();
      return;
    }
    if (_sweep == null) {
      final sweep = _sweep = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      );
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (mounted) sweep.forward();
      });
    }
    _startTilt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No sensor work while the app is in the background.
    if (state == AppLifecycleState.resumed) {
      if (_moving) _startTilt();
    } else {
      _stopTilt();
    }
  }

  void _startTilt() {
    if (_tilt != null) return;
    _follow ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _tilt = ref.read(tiltSourceProvider).tilt.listen((t) {
      if (!mounted) return;
      final follow = _follow!;
      _from = _current;
      _to = t;
      _tilted = true;
      follow.forward(from: 0);
    }, onError: (Object _) {});
  }

  void _stopTilt() {
    _tilt?.cancel();
    _tilt = null;
  }

  Offset get _current {
    final follow = _follow;
    if (follow == null) return _to;
    return Offset.lerp(_from, _to, Curves.easeOut.transform(follow.value))!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTilt();
    _sweep?.dispose();
    _follow?.dispose();
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
    final follow = _follow;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: AnimatedBuilder(
        animation: Listenable.merge([sweep, ?follow]),
        child: surface,
        builder: (context, child) {
          final _SheenPainter? painter;
          if (sweep.isAnimating) {
            painter = _SheenPainter(
              t: Curves.easeInOutCubic.transform(sweep.value),
              color: light ? const Color(0x8CFFFFFF) : const Color(0x14FFFFFF),
            );
          } else if (_tilted) {
            // Tilting right moves the light right; forward, up.
            final tilt = _current;
            painter = _SheenPainter(
              t: (0.5 - tilt.dx * 0.45).clamp(0.05, 0.95),
              slope: 0.4 - tilt.dy * 0.3,
              color: light ? const Color(0x59FFFFFF) : const Color(0x0FFFFFFF),
            );
          } else {
            painter = null;
          }
          return CustomPaint(foregroundPainter: painter, child: child);
        },
      ),
    );
  }
}

/// A diagonal band of light at position [t] (0 = off the left, 1 = off the
/// right), leaning by [slope].
class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.t, required this.color, this.slope = 0.4});

  final double t;
  final double slope;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.45;
    final x = -band + (size.width + band * 2) * t;
    final clear = color.withValues(alpha: 0);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1, -slope),
        end: Alignment(1, slope),
        colors: [clear, color, clear],
      ).createShader(Rect.fromLTWH(x - band, 0, band * 2, size.height));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.t != t || old.slope != slope || old.color != color;
}
