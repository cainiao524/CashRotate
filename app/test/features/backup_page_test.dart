import 'dart:io';
import 'dart:typed_data';

import 'package:cashrotate/data/backup/backup_service.dart';
import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate/platform/files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

class FakePicker implements FilePicker {
  Uint8List? saved;
  String? savedName;

  @override
  Future<bool> save(String name, Uint8List bytes) async {
    saved = bytes;
    savedName = name;
    return true;
  }

  @override
  Future<Uint8List?> open() async => saved;
}

void main() {
  testApp('back up, export with a password, restore from the file', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('cashrotate-ui');
    addTearDown(() => dir.deleteSync(recursive: true));
    final picker = FakePicker();
    late Map<String, String> ids;
    final data = await pumpApp(
      tester,
      seed: (d) async => ids = await d.seedItems(),
      overrides: [
        filePickerProvider.overrideWithValue(picker),
        backupServiceProvider.overrideWith(
          (ref) async => BackupService(
            ref.watch(appDatabaseProvider).requireValue,
            ref.watch(journalProvider),
            await ref.watch(sodiumProvider.future),
            dir,
            kdf: const KdfParams(opsLimit: 1, memLimit: 8 << 20),
          ),
        ),
      ],
    );
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-backup')));
    await tester.tap(find.byKey(const Key('settings-backup')));
    await settle(tester);
    expect(find.text('No backups yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('backup-now')));
    await settle(tester, frames: 10);
    expect(find.text('No backups yet'), findsNothing);
    expect(find.text('Restore'), findsOneWidget);

    await tester.tap(find.byKey(const Key('backup-export')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'pass-1234',
    );
    await tester.enterText(
      find.byKey(const Key('backup-password-again')),
      'pass-1234',
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-password-ok')));
    await settle(tester, frames: 10);
    expect(picker.saved, isNotNull);
    expect(picker.savedName, endsWith('.crb'));

    // Delete an item, then bring it back from the file.
    await tester.runAsync(() => data.items.delete(ids['rent']!));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-import')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'pass-1234',
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-password-ok')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-restore-confirm')));
    await settle(tester, frames: 10);
    final rent = await tester.runAsync(() => data.items.view(ids['rent']!));
    expect(rent!.row.name, 'Rent');
  });
}
