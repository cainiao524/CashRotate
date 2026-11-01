import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate/data/security/app_lock.dart';
import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sodium/sodium_sumo.dart';

import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

const cheap = KdfParams(opsLimit: 1, memLimit: 8 << 20);

class FakeBiometric implements BiometricAuth {
  FakeBiometric({this.result = false});
  bool result;
  int asked = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return result;
  }
}

List<Override> lockOverrides(FakeBiometric bio) => [
  appLockRepositoryProvider.overrideWith(
    (ref) async => AppLockRepository(
      ref.watch(appDatabaseProvider).requireValue,
      await ref.watch(sodiumProvider.future),
      kdf: cheap,
    ),
  ),
  biometricAuthProvider.overrideWithValue(bio),
];

Future<void> seedPin(TestData d, String pin, {bool biometric = false}) async {
  final repo = AppLockRepository(d.db, await SodiumSumoInit.init(), kdf: cheap);
  await repo.setPin(pin);
  if (biometric) await repo.update((c) => c.copyWith(biometric: true));
}

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-$d')));
    await tester.pump();
  }
  await settle(tester, frames: 8);
}

void main() {
  testApp('a locked app opens on the PIN pad; the right PIN unlocks', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: lockOverrides(FakeBiometric()),
      seed: (d) async {
        await d.seedItems();
        await seedPin(d, '2468');
      },
    );
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    // The app is not readable underneath.
    expect(find.bySemanticsLabel(RegExp('Netflix')), findsNothing);

    await typePin(tester, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    await typePin(tester, '2468');
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    expect(find.byKey(const Key('home-total')), findsOneWidget);
  });

  testApp('fingerprint or face unlocks without the PIN', (tester) async {
    final bio = FakeBiometric(result: true);
    await pumpApp(
      tester,
      overrides: lockOverrides(bio),
      seed: (d) => seedPin(d, '2468', biometric: true),
    );
    expect(bio.asked, 1);
    expect(find.byKey(const Key('lock-screen')), findsNothing);
  });

  testApp('too many wrong PINs pause the pad', (tester) async {
    await pumpApp(
      tester,
      overrides: lockOverrides(FakeBiometric()),
      seed: (d) => seedPin(d, '2468'),
    );
    for (var i = 0; i < 5; i++) {
      await typePin(tester, '0000');
    }
    expect(find.textContaining('Too many tries'), findsOneWidget);
    await typePin(tester, '2468'); // ignored while paused
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
  });

  testApp('turn it on in settings; leaving the app locks it again', (
    tester,
  ) async {
    await pumpApp(tester, overrides: lockOverrides(FakeBiometric()));
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-app-lock')));
    await tester.tap(find.byKey(const Key('settings-app-lock')));
    await settle(tester);
    await typePin(tester, '1357');
    await tester.tap(find.byKey(const Key('pin-ok')));
    await settle(tester);
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await typePin(tester, '1357');
    await settle(tester, frames: 8);
    expect(find.textContaining('a PIN is needed'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    await typePin(tester, '1357');
    expect(find.byKey(const Key('lock-screen')), findsNothing);
    // Still on the settings page: nothing was lost.
    expect(find.byKey(const Key('settings-app-lock')), findsOneWidget);
  });
}
