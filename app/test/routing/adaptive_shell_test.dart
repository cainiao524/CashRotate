import 'package:cashrotate/layout/list_detail_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  testApp('compact window uses bottom navigation', (tester) async {
    await pumpApp(tester, width: 360);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  for (final width in [600.0, 840.0, 1280.0]) {
    testApp('${width.toInt()}dp window uses a navigation rail', (tester) async {
      await pumpApp(tester, width: width);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  }

  testApp('fixed expenses become two-pane only on wide windows', (
    tester,
  ) async {
    await pumpApp(tester, width: 360);
    await tester.tap(find.text('Fixed'));
    await tester.pump();
    expect(find.text('Fixed expenses'), findsOneWidget);
    expect(find.byType(ListDetailLayout), findsNothing);

    // Unfold: same page, now with a detail pane, without losing the tab.
    tester.view.physicalSize = const Size(700, 880);
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(ListDetailLayout), findsOneWidget);
    expect(find.text('Select an item to see its details'), findsOneWidget);
  });

  testApp('scroll position survives a window resize', (tester) async {
    await pumpApp(tester, width: 360, height: 400, textScale: 2);
    final list = find.byKey(const PageStorageKey('home'));
    await tester.drag(list, const Offset(0, -150));
    await tester.pump();
    final before = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position
        .pixels;
    expect(before, greaterThan(0));

    tester.view.physicalSize = const Size(620, 400); // rotate to landscape
    await tester.pump();
    final after = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const PageStorageKey('home')),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(after, before);
  });

  testApp('navigation labels follow system language', (tester) async {
    await pumpApp(tester, width: 360, locale: const Locale('zh', 'TW'));
    expect(find.text('固定支出'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
  });
}
