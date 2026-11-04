import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

/// CLAUDE.md: touch targets ≥ 48dp, every tappable thing labelled for
/// TalkBack, text contrast ≥ 4.5:1, in light and dark mode.
void main() {
  final screens = <String, Future<void> Function(WidgetTester)?>{
    'home': null,
    'fixed': (tester) async {
      await tester.tap(find.byIcon(Icons.event_repeat_outlined));
      await settle(tester);
    },
    'reports': (tester) async {
      await tester.tap(find.byIcon(Icons.insert_chart_outlined));
      await settle(tester);
    },
    'reports month': (tester) async {
      await tester.tap(find.byIcon(Icons.insert_chart_outlined));
      await settle(tester);
      await tester.tap(find.byKey(const Key('reports-tab-month')));
      await settle(tester);
    },
    'item detail': (tester) async {
      await tester.tap(find.text('Rent').first);
      await settle(tester);
    },
    'add item': (tester) async {
      await tester.tap(find.byIcon(Icons.event_repeat_outlined));
      await settle(tester);
      await tester.tap(find.byKey(const Key('items-add')));
      await settle(tester);
    },
    'settings': (tester) async {
      await tester.tap(find.byKey(const Key('nav-settings')));
      await settle(tester);
    },
  };

  for (final MapEntry(key: name, value: open) in screens.entries) {
    for (final brightness in Brightness.values) {
      testApp('$name (${brightness.name}) meets the guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpApp(
          tester,
          brightness: brightness,
          disableAnimations: true,
          seed: (d) => d.seedItems(),
        );
        await open?.call(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
