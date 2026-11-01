import 'dart:io';

import 'package:cashrotate/data/backup/backup_service.dart';
import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/sync/drift_sync_store.dart';
import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sodium/sodium_sumo.dart';

const cheap = KdfParams(opsLimit: 1, memLimit: 8 << 20);

void main() {
  late SodiumSumo sodium;
  late Directory dir;
  var now = DateTime.utc(2026, 3, 15, 10);

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => dir = Directory.systemTemp.createTempSync('cashrotate-backup'));
  tearDown(() => dir.deleteSync(recursive: true));

  ({
    AppDatabase db,
    Journal journal,
    ItemRepository items,
    BackupService backups,
  })
  phone([Directory? d]) {
    final db = AppDatabase(NativeDatabase.memory());
    final journal = Journal(db, nowMillis: () => now.millisecondsSinceEpoch);
    return (
      db: db,
      journal: journal,
      items: ItemRepository(
        db,
        journal,
        today: () => LocalDate(2026, 3, 15),
        nowMillis: () => now.millisecondsSinceEpoch,
      ),
      backups: BackupService(
        db,
        journal,
        sodium,
        d ?? dir,
        kdf: cheap,
        now: () => now,
      ),
    );
  }

  NewItem item(String name) => NewItem(
    type: ItemType.subscription,
    name: name,
    cycle: Cycle.monthly,
    anchor: LocalDate(2026, 3, 18),
    prices: PriceSchedule.fixed(const Money(39000, Currency.twd)),
  );

  Future<List<String>> names(ItemRepository items) async =>
      [for (final v in await items.watchAll().first) v.row.name]..sort();

  test(
    'restore puts the backed-up state back and journals it for sync',
    () async {
      final p = phone();
      await p.items.create(item('Netflix'));
      final backup = await p.backups.backUpNow();
      now = now.add(const Duration(hours: 1));
      await p.items.create(item('Spotify'));
      await DriftSyncStore(p.db, p.journal).markUploaded(
        (await DriftSyncStore(p.db, p.journal).pending()).map((c) => c.localId),
      );

      await p.backups.restoreLocal(backup);
      expect(await names(p.items), ['Netflix']);
      expect((await p.items.watchAll().first).single.nextDue, isNotNull);

      final pending = await DriftSyncStore(p.db, p.journal).pending();
      expect(
        pending.any((c) => c.change.isTombstone),
        isTrue,
        reason: 'Spotify',
      );
      expect(
        pending.any(
          (c) => c.change.entity == 'items' && c.change.field == 'name',
        ),
        isTrue,
        reason: 'restored rows are re-sent as new changes',
      );
      await p.db.close();
    },
  );

  test('keeps the newest seven; a daily backup only once a day', () async {
    final p = phone();
    for (var i = 0; i < 9; i++) {
      now = now.add(const Duration(minutes: 1));
      await p.backups.backUpNow();
    }
    expect(await p.backups.list(), hasLength(7));
    expect(await p.backups.backUpIfDue(), isFalse);
    now = now.add(const Duration(hours: 25));
    expect(await p.backups.backUpIfDue(), isTrue);
    await p.db.close();
  });

  test('an exported file opens on another phone with its password', () async {
    final a = phone();
    await a.items.create(item('Netflix'));
    final file = await a.backups.export('backup-pass');
    expect(String.fromCharCodes(file.sublist(0, 4)), 'CRB1');

    final b = phone(Directory('${dir.path}/b'));
    await expectLater(
      b.backups.import(file, 'wrong'),
      throwsA(isA<BackupException>()),
    );
    await expectLater(
      b.backups.import([1, 2, 3], 'backup-pass'),
      throwsA(isA<BackupException>()),
    );
    await b.backups.import(file, 'backup-pass');
    expect(await names(b.items), ['Netflix']);
    await a.db.close();
    await b.db.close();
  });
}
