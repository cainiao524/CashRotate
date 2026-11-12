import 'package:material_ui/material_ui.dart';

import 'palette.dart';

/// The app's typeface for Latin letters and figures (bundled); other
/// scripts fall back to the system font.
const appFontFamily = 'Manrope';

/// Builds the flat monochrome Material theme from a [Palette].
ThemeData buildTheme(Palette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: p.error,
    onError: p.onError,
    surface: p.background,
    onSurface: p.text,
    onSurfaceVariant: p.secondaryText,
    surfaceContainerLowest: p.card,
    surfaceContainerLow: p.card,
    surfaceContainer: p.card,
    surfaceContainerHigh: p.pressed,
    surfaceContainerHighest: p.selected,
    outline: p.outline,
    outlineVariant: p.divider,
    surfaceTint: Colors.transparent,
  );

  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.divider),
      ),
    ),
    // The design's add button: an ink pill on a soft, low shadow (Material's
    // default elevation reads as a dark halo on the pearl-white page).
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      highlightElevation: 1,
      shape: const StadiumBorder(),
      extendedTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: p.selected,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.card,
      indicatorColor: p.selected,
      labelType: NavigationRailLabelType.all,
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: p.text,
      selectedTileColor: p.selected,
      iconColor: p.secondaryText,
    ),
    extensions: [p],
  );
  return theme.copyWith(textTheme: _manropeWeights(theme.textTheme));
}

/// Manrope's regular strokes are thinner than the system font's, so small
/// text reads faint: body and label text use its medium weight, titles a
/// step heavier, keeping the same contrast and visual weight as before.
TextTheme _manropeWeights(TextTheme t) {
  TextStyle? at(TextStyle? s, FontWeight w) => s?.copyWith(fontWeight: w);
  return t.copyWith(
    bodySmall: at(t.bodySmall, FontWeight.w500),
    bodyMedium: at(t.bodyMedium, FontWeight.w500),
    bodyLarge: at(t.bodyLarge, FontWeight.w500),
    labelSmall: at(t.labelSmall, FontWeight.w600),
    labelMedium: at(t.labelMedium, FontWeight.w600),
    labelLarge: at(t.labelLarge, FontWeight.w600),
    titleSmall: at(t.titleSmall, FontWeight.w700),
    titleMedium: at(t.titleMedium, FontWeight.w600),
    titleLarge: at(t.titleLarge, FontWeight.w600),
  );
}

/// Amounts must line up in columns: always render digits with equal widths.
TextStyle tabularFigures(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
