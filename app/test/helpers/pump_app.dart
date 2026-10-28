import 'package:cashrotate/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Golden matrix required by CLAUDE.md: widths × text scales × brightness.
const goldenWidths = [360.0, 411.0, 600.0, 840.0, 1280.0];
const goldenTextScales = [1.0, 1.3, 2.0];
const goldenBrightnesses = [Brightness.light, Brightness.dark];

/// Representative window height for each golden width (phone, large phone,
/// unfolded inner screen, small tablet, tablet landscape).
double _heightFor(double width) => switch (width) {
  360 => 760,
  840 => 900,
  1280 => 800,
  _ => 880,
};

/// Sets the test window and system settings, then pumps the whole app.
Future<void> pumpApp(
  WidgetTester tester, {
  double width = 411,
  double? height,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en', 'US'),
  bool disableAnimations = false,
}) async {
  final view = tester.view;
  final dispatcher = tester.platformDispatcher;
  view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height ?? _heightFor(width));
  dispatcher
    ..textScaleFactorTestValue = textScale
    ..platformBrightnessTestValue = brightness
    ..localesTestValue = [locale]
    ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: disableAnimations,
    );
  addTearDown(view.reset);
  addTearDown(dispatcher.clearAllTestValues);

  await tester.pumpWidget(const ProviderScope(child: CashRotateApp()));
  // Not pumpAndSettle: overflowing MarqueeText animates forever by design.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
