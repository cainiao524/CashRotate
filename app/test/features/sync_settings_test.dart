import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate/data/sync/sync_service.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sodium/sodium_sumo.dart';

import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

const fast = KdfParams(opsLimit: 1, memLimit: 8 << 20);

/// Sync against an in-memory folder instead of a WebDAV server.
Override syncWith(MemoryFolder folder) => syncServiceProvider.overrideWith(
  (ref) async => SyncService(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    await ref.watch(sodiumProvider.future),
    remoteFor: (_) => folder,
    kdf: fast,
  ),
);

Future<void> openSync(WidgetTester tester) async {
  await openSettings(tester);
  await scrollTo(tester, find.byKey(const Key('settings-sync')));
  await tester.tap(find.byKey(const Key('settings-sync')));
  await settle(tester);
}

Future<void> connect(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('sync-url')),
    'https://dav.example.com/',
  );
  await tester.enterText(find.byKey(const Key('sync-user')), 'me');
  await tester.enterText(
    find.byKey(const Key('sync-server-password')),
    'app-pass',
  );
  await settle(tester);
  await tester.tap(find.byKey(const Key('sync-connect')));
  await settle(tester, frames: 10);
}

Future<void> tapVisible(WidgetTester tester, Key key) async {
  await scrollTo(
    tester,
    find.byKey(key),
    list: const PageStorageKey('settings-sync'),
  );
  await tester.tap(find.byKey(key));
  await settle(tester, frames: 12);
}

void main() {
  testApp('first device: connect, set password and recovery code, sync', (
    tester,
  ) async {
    final folder = MemoryFolder();
    await pumpApp(
      tester,
      seed: (d) => d.seedItems(),
      overrides: [syncWith(folder)],
    );
    await openSync(tester);
    await connect(tester);
    expect(find.text('Set up encrypted sync'), findsOneWidget);
    expect(find.byKey(const Key('sync-recovery-code')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sync-password')), 'secret-1');
    await tester.enterText(
      find.byKey(const Key('sync-password-again')),
      'secret-1',
    );
    await settle(tester);
    // Not until the recovery code is confirmed as saved.
    await scrollTo(
      tester,
      find.byKey(const Key('sync-create')),
      list: const PageStorageKey('settings-sync'),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('sync-create')))
          .onPressed,
      isNull,
    );
    await tapVisible(tester, const Key('sync-recovery-saved'));
    await tapVisible(tester, const Key('sync-create'));

    expect(find.byKey(const Key('sync-now')), findsOneWidget);
    expect(folder.files.keys, contains('manifest.json'));
    expect(
      folder.files.keys.where((k) => k.endsWith('/1.chg')),
      hasLength(1),
      reason: 'the seeded items were uploaded',
    );
    expect(find.textContaining('Last synced'), findsOneWidget);
    expect(find.text('Everything is uploaded'), findsOneWidget);
  });

  testApp('second device: joins with the password; a wrong one is refused', (
    tester,
  ) async {
    final folder = MemoryFolder();
    await pumpApp(
      tester,
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
    await openSync(tester);
    await connect(tester);
    expect(find.textContaining('already has CashRotate data'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sync-password')), 'wrong-pw');
    await settle(tester);
    await tapVisible(tester, const Key('sync-join'));
    expect(find.text('Wrong sync password'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sync-password')), 'secret-1');
    await settle(tester);
    await tapVisible(tester, const Key('sync-join'));
    expect(find.byKey(const Key('sync-now')), findsOneWidget);
  });

  testApp('a weak recovery code of your own is not accepted', (tester) async {
    await pumpApp(tester, overrides: [syncWith(MemoryFolder())]);
    await openSync(tester);
    await connect(tester);
    await tapVisible(tester, const Key('sync-recovery-own'));
    await tester.enterText(
      find.byKey(const Key('sync-recovery-input')),
      'password1234',
    );
    await tester.enterText(find.byKey(const Key('sync-password')), 'secret-1');
    await tester.enterText(
      find.byKey(const Key('sync-password-again')),
      'secret-1',
    );
    await settle(tester);
    expect(find.textContaining('Too weak'), findsOneWidget);
  });
}
