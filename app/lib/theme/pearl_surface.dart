import 'package:material_ui/material_ui.dart';

import 'palette.dart';

/// The pearl sheen surface. Only for the home total card and the Pro badge;
/// everything else in the UI stays flat.
///
/// The gradient is static for now. The optional tilt-driven sheen (disabled
/// under the system "remove animations" setting) needs a sensor package and
/// is scheduled for M7 polish.
class PearlSurface extends StatelessWidget {
  const PearlSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: palette.divider),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.pearl,
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
