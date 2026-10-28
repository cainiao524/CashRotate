@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// Every width × text scale × brightness from CLAUDE.md, for each top-level
/// screen built so far. Layout overflow throws during pumping, so these also
/// prove nothing breaks at 200% text.
///
/// Regenerate with: flutter test --update-goldens test/goldens
void main() {
  final screens = <String, Future<void> Function(WidgetTester)>{
    'home': (_) async {},
    'items': (tester) async {
      await tester.tap(find.byIcon(Icons.event_repeat_outlined));
      await tester.pump();
    },
  };

  for (final MapEntry(key: screen, value: open) in screens.entries) {
    for (final width in goldenWidths) {
      for (final scale in goldenTextScales) {
        for (final brightness in goldenBrightnesses) {
          final name =
              '${screen}_${width.toInt()}_x${scale}_${brightness.name}';
          testWidgets(name, (tester) async {
            await pumpApp(
              tester,
              width: width,
              textScale: scale,
              brightness: brightness,
            );
            await open(tester);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('$screen/$name.png'),
            );
          });
        }
      }
    }
  }
}
