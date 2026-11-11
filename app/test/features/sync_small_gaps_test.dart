import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate/features/items/item_draft.dart';
import 'package:cashrotate/features/items/item_editor_page.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sodium/sodium_sumo.dart';

import '../helpers/pump_app.dart';
import 'sync_settings_test.dart'
    show connect, fast, openSync, syncWith, tapVisible;

void main() {
  group('hourly-billed servers', () {
    test('hours per cycle', () {
      expect(hoursPerCycle(Cycle.monthly), 730);
      expect(hoursPerCycle(Cycle.yearly), 8766);
      expect(hoursPerCycle(Cycle.weekly), 168);
      expect(hoursPerCycle(Cycle(CycleUnit.day, 30)), 720);
    });

    test('a rate below one cent still adds up per charge', () {
      final d = ItemDraft(
        type: ItemType.subscription,
        currency: Currency.eur,
        cycle: Cycle.monthly,
        fields: {'hourly': true, 'hourlyRate': '0.007'},
      );
      final e = hourlyEstimate(d)!;
      expect(e.hours, 730);
      expect(e.amount, const Money(511, Currency.eur)); // €5.11
      d.fields['hourlyRate'] = '';
      expect(hourlyEstimate(d), isNull);
    });
  });

  testApp('home shows sync status once sync is set up', (tester) async {
    final folder = MemoryFolder();
    final privacy = FakeScreenPrivacy();
    await pumpApp(
      tester,
      privacy: privacy,
      overrides: [syncWith(folder)],
      seed: (d) async {
        final sodium = await SodiumSumoInit.init();
        await SyncSetup(SyncKeys(sodium, kdf: fast), folder).create(
          password: 'secret-1',
          recoveryCode: 'gT7#qL2v!Wm9@zR4xK8&',
          deviceId: 'other',
          deviceName: 'Pixel',
        );
      },
    );
    expect(find.byKey(const Key('home-sync-status')), findsNothing);
    expect(privacy.hidden, false, reason: 'no app lock: shown in recents');

    await openSync(tester);
    await connect(tester);
    await tester.enterText(find.byKey(const Key('sync-password')), 'secret-1');
    await settle(tester);
    await tapVisible(tester, const Key('sync-join'));
    await tester.tap(find.text('Home'));
    await settle(tester, frames: 8);
    expect(find.byKey(const Key('home-sync-status')), findsOneWidget);
  });
}
