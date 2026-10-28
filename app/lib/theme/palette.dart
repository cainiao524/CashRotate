import 'package:material_ui/material_ui.dart';

/// Pearl monochrome design tokens. Every colour in the app comes from here.
///
/// Contrast figures are against [card] (light) or [card] (dark) and were
/// checked when the tokens were chosen; keep them at or above 4.5:1 for text.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.primary,
    required this.onPrimary,
    required this.text,
    required this.secondaryText,
    required this.outline,
    required this.divider,
    required this.pressed,
    required this.selected,
    required this.warning,
    required this.error,
    required this.onError,
    required this.pearl,
  });

  final Brightness brightness;

  /// Page background (pearl white / pearl black).
  final Color background;

  /// Cards, sheets and the navigation surfaces.
  final Color card;

  /// Near-black in light mode, pearl white in dark mode.
  final Color primary;
  final Color onPrimary;

  final Color text;
  final Color secondaryText;

  /// Borders that carry meaning (text fields, chips); ≥ 3:1.
  final Color outline;

  /// Decorative separators.
  final Color divider;

  /// Fill for pressed list rows and similar flat surfaces.
  final Color pressed;

  /// Navigation indicator and selected-row fill.
  final Color selected;

  /// The only two functional colours: amber for warnings, red for overdue and errors.
  final Color warning;
  final Color error;
  final Color onError;

  /// Pearl sheen stops. Only for the app icon, the home total card and the Pro badge.
  final List<Color> pearl;

  static const light = Palette(
    brightness: Brightness.light,
    background: Color(0xFFF7F7F5),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF111111), // 18.9:1
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF111111),
    secondaryText: Color(0xFF5F6368), // ~6:1
    outline: Color(0xFF80868B),
    divider: Color(0xFFE3E3E0),
    pressed: Color(0xFFEDEDEB),
    selected: Color(0xFFE6E6E3),
    warning: Color(0xFFB45309),
    error: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    pearl: [Color(0xFFFFFFFF), Color(0xFFECEEF1), Color(0xFFF3EFEA)],
  );

  static const dark = Palette(
    brightness: Brightness.dark,
    background: Color(0xFF0B0B0C),
    card: Color(0xFF161618),
    primary: Color(0xFFF2F2F0), // 17.5:1
    onPrimary: Color(0xFF000000),
    text: Color(0xFFF2F2F0),
    secondaryText: Color(0xFFA1A1A6), // ~7.6:1
    outline: Color(0xFF8E8E93),
    divider: Color(0xFF2C2C2F),
    pressed: Color(0xFF222225),
    selected: Color(0xFF2A2A2E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFF87171),
    onError: Color(0xFF000000),
    pearl: [Color(0xFF1A1A1D), Color(0xFF2A2A2F), Color(0xFF1F1E23)],
  );

  static Palette of(BuildContext context) =>
      Theme.of(context).extension<Palette>()!;

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
