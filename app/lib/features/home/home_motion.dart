import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../widgets/money_text.dart';

/// Motion on the home page. Every animation here goes still when the system
/// "remove animations" setting is on.
abstract final class HomeMotion {
  static const move = Duration(milliseconds: 380);
  static const fade = Duration(milliseconds: 260);
  static const entrance = Duration(milliseconds: 460);
  static const count = Duration(milliseconds: 820);
  static const ring = Duration(milliseconds: 760);

  /// Delay between tiles when the grid first fills, and its cap.
  static const stagger = Duration(milliseconds: 28);
  static const maxStagger = Duration(milliseconds: 280);

  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero with animations off.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Fades, rises and grows its child into place once, after [delay].
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HomeMotion.entrance,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (HomeMotion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

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
        final t = _t.value;
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
        );
      },
    );
  }
}

/// Sinks slightly while pressed, springs back on release.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: HomeMotion.of(
          context,
          Duration(milliseconds: _down ? 90 : 260),
        ),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// An amount that counts up from zero when it first appears, and glides to
/// each new value after that.
class CountingMoneyText extends StatelessWidget {
  const CountingMoneyText(this.money, {super.key, this.style});

  final Money money;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // A new currency starts over rather than gliding between currencies.
      key: ValueKey(money.currency),
      tween: Tween(begin: 0, end: money.minor.toDouble()),
      duration: HomeMotion.of(context, HomeMotion.count),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) =>
          MoneyText(Money(value.round(), money.currency), style: style),
    );
  }
}
