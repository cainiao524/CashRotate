import 'package:material_ui/material_ui.dart';

/// Round badge with the first letter of a name on its brand colour. No logos
/// are shipped; this is the only brand mark the app draws.
class InitialBadge extends StatelessWidget {
  const InitialBadge({
    super.key,
    required this.name,
    required this.color,
    this.size = 40,
  });

  final String name;

  /// `#RRGGBB`.
  final String color;
  final double size;

  static Color parse(String hex) =>
      Color(int.parse('FF${hex.substring(1)}', radix: 16));

  /// Black or white, whichever contrasts more with [background].
  static Color foregroundFor(Color background) {
    final l = background.computeLuminance();
    final onWhite = (1.05) / (l + 0.05);
    final onBlack = (l + 0.05) / 0.05;
    return onWhite >= onBlack ? Colors.white : Colors.black;
  }

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final background = parse(color);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Center(
            // The badge is a fixed-size glyph; it must not grow with text scale.
            child: MediaQuery.withNoTextScaling(
              child: Text(
                _initial,
                style: TextStyle(
                  color: foregroundFor(background),
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
