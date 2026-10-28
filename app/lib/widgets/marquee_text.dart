import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:material_ui/material_ui.dart';

/// Single-line text that never truncates with an ellipsis.
///
/// - Fits: rendered statically.
/// - Overflows: pauses, scrolls slowly to the end, pauses, scrolls back, repeats.
/// - Overflows with system "remove animations" on: wraps onto as many lines
///   as needed instead of moving.
///
/// Screen readers always get the full text.
class MarqueeText extends StatefulWidget {
  const MarqueeText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static const pause = Duration(milliseconds: 1500);

  /// Scroll speed in logical pixels per second; slow enough to read.
  static const speed = 30.0;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _overflow = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Runs after layout: starting the controller during build is not allowed.
  void _setOverflow(double overflow) {
    if (!mounted || overflow == _overflow) return;
    setState(() => _overflow = overflow);
    if (overflow <= 0) {
      _controller.stop();
      return;
    }
    final travel = Duration(
      milliseconds: (overflow / MarqueeText.speed * 1000).round(),
    );
    _controller
      ..duration = MarqueeText.pause * 2 + travel * 2
      ..repeat();
  }

  double _offsetAt(double t) {
    final total = _controller.duration!.inMicroseconds;
    final pause = MarqueeText.pause.inMicroseconds / total;
    final travel = (1 - 2 * pause) / 2;
    if (t < pause) return 0;
    if (t < pause + travel) {
      return Curves.easeInOut.transform((t - pause) / travel) * _overflow;
    }
    if (t < 2 * pause + travel) return _overflow;
    return (1 - Curves.easeInOut.transform((t - 2 * pause - travel) / travel)) *
        _overflow;
  }

  @override
  Widget build(BuildContext context) {
    var style = DefaultTextStyle.of(context).style.merge(widget.style);
    if (MediaQuery.boldTextOf(context)) {
      style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          textDirection: direction,
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: 1,
        )..layout();
        final overflow = constraints.hasBoundedWidth
            ? (painter.width - constraints.maxWidth).clamp(0.0, double.infinity)
            : 0.0;
        painter.dispose();

        if (overflow > 0 && MediaQuery.disableAnimationsOf(context)) {
          return Text(widget.text, style: widget.style, softWrap: true);
        }

        final line = Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        );
        if (overflow != _overflow) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _setOverflow(overflow),
          );
        }
        if (overflow == 0) return line;

        final sign = direction == TextDirection.ltr ? -1.0 : 1.0;
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: AlignmentDirectional.centerStart,
            fit: OverflowBoxFit.deferToChild,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  sign * (_overflow > 0 ? _offsetAt(_controller.value) : 0),
                  0,
                ),
                child: child,
              ),
              child: line,
            ),
          ),
        );
      },
    );
  }
}
