import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_notice_platform.dart';
import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

Future<void> openDetection(WidgetTester tester) async {
  await openSettings(tester);
  await scrollTo(tester, find.byKey(const Key('settings-detection')));
  await tester.tap(find.byKey(const Key('settings-detection')));
  await settle(tester);
}

void main() {
  testApp('turn on, pick apps, then a charge arrives and can be undone', (
    tester,
  ) async {
    final platform = FakeNoticePlatform()..granted = false;
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      notices: platform,
      seed: (d) async => ids = await d.seedItems(),
    );
    await openDetection(tester);
    await tester.tap(find.byKey(const Key('detect-enabled')));
    await settle(tester);
    expect(platform.enabled, isTrue);
    expect(find.byKey(const Key('detect-no-access')), findsOneWidget);

    await tester.tap(find.byKey(const Key('detect-apps')));
    await settle(tester);
    expect(find.text('3 notifications looked like charges'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('detect-app-com.bank.app')));
    await tester.tap(find.byKey(const Key('detect-apps-save')));
    await settle(tester);
    expect(platform.packages, ['com.bank.app']);

    platform.post('您的信用卡在 NETFLIX.COM 消費新臺幣390元', DateTime(2026, 3, 18, 9));
    await settle(tester, frames: 10);
    expect(find.text('Recorded automatically'), findsOneWidget);
    final netflix = ids['netflix']!;
    var view = await tester.runAsync(() => data.items.view(netflix));
    expect(view!.nextDue!.dueOn, LocalDate(2026, 4, 18));

    await tester.tap(find.textContaining('Undo'));
    await settle(tester, frames: 10);
    view = await tester.runAsync(() => data.items.view(netflix));
    expect(view!.nextDue!.dueOn, LocalDate(2026, 3, 18));
  });

  testApp('a charge to confirm is assigned from the list', (tester) async {
    final platform = FakeNoticePlatform();
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      notices: platform,
      seed: (d) async => ids = await d.seedItems(),
    );
    await openDetection(tester);
    platform.post('信用卡消費 NT\$18,000', DateTime(2026, 4, 5, 9));
    await settle(tester, frames: 10);
    expect(find.text('To confirm'), findsOneWidget);
    await tester.tap(find.textContaining('Payment for Rent'));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('detect-item-${ids['rent']}')));
    await settle(tester, frames: 10);
    final rent = await tester.runAsync(() => data.items.view(ids['rent']!));
    expect(rent!.nextDue!.dueOn, LocalDate(2026, 5, 5));
  });
}
