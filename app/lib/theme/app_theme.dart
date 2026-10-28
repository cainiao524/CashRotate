import 'package:material_ui/material_ui.dart';

import 'palette.dart';

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

  return ThemeData(
    useMaterial3: true,
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
}

/// Amounts must line up in columns: always render digits with equal widths.
TextStyle tabularFigures(TextStyle style) =>
    style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
