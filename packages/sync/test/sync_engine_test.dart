import 'dart:math';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:test/test.dart';

import 'memory_store.dart';

void main() {
  var now = 1_800_000_000_000;
  int clock() => now;

  SyncEngine engine(
    MemoryStore store,
    RemoteFolder remote, {
    SyncCipher cipher = const TestCipher(),
    int snapshotAfter = 100,
  }) => SyncEngine(
    store: store,
    remote: remote,
    cipher: cipher,
    nowMillis: clock,
    random: Random(1),
    snapshotAfterBatches: snapshotAfter,
  );

  group('merge', () {
    final a = MemoryStore('a', clock: clock);
    FieldChange change(
      String field,
      String value,
      int millis, [
      String node = 'x',
    ]) => FieldChange(
      entity: 'items',
      rowId: 'r',
      field: field,
      value: value,
      hlc: Hlc(millis, 0, node),
    );

    test('newer wins per field; different fields are both kept', () async {
      final out = await mergeChanges([
        change('name', '"A"', 10),
        change('name', '"B"', 20),
        change('note', '"n"', 5),
      ], a);
      expect(
        {for (final w in out.winners) w.field: w.value},
        {'name': '"B"', 'note': '"n"'},
      );
    });

    test('a deletion beats earlier edits; later edits are conflicts', () async {
      final out = await mergeChanges([
        change('name', '"before"', 10),
        change(tombstoneField, 'true', 20),
        change('name', '"after"', 30),
      ], a);
      expect(out.winners.single.isTombstone, isTrue);
      expect(out.conflicts.single.change.value, '"after"');
      expect(out.conflicts.single.kind, ConflictKind.editedAfterDelete);
    });

    test(
      'compact keeps the newest per field, only tombstones of deleted rows',
      () {
        final kept = compact([
          change('name', '"A"', 10),
          change('name', '"B"', 20),
          const FieldChange(
            entity: 'items',
            rowId: 'gone',
            field: 'name',
            value: '"x"',
            hlc: Hlc(5, 0, 'x'),
          ),
          const FieldChange(
            entity: 'items',
            rowId: 'gone',
            field: tombstoneField,
            value: 'true',
            hlc: Hlc(6, 0, 'x'),
          ),
        ]);
        expect(kept.map((c) => '${c.rowId}.${c.field}=${c.value}'), [
          'gone._deleted=true',
          'r.name="B"',
        ]);
      },
    );
  });

  test(
    'two devices exchange edits; files go up under a temp name first',
    () async {
      final remote = MemoryFolder();
      final a = MemoryStore('a', clock: clock)
        ..edit('items', '1', {'name': '"Netflix"'});
      final b = MemoryStore('b', clock: clock);
      final report = await engine(a, remote).sync();
      expect(report.uploaded, 1);
      expect(remote.files.keys, contains('devices/a/1.chg'));
      expect(
        remote.writes.where((w) => w.contains('.chg')),
        everyElement(contains('.tmp-')),
      );
      now += 1000;
      b.edit('items', '1', {'note': '"shared"'});
      await engine(b, remote).sync();
      await engine(a, remote).sync();
      expect(a.rows, b.rows);
      expect(a.rows['items']!['1'], {'name': '"Netflix"', 'note': '"shared"'});
      // Nothing new: a second round downloads and uploads nothing.
      final quiet = await engine(a, remote).sync();
      expect(quiet.downloaded, 0);
      expect(quiet.uploaded, 0);
    },
  );

  test(
    'a file moved to another path, or a different key, does not open',
    () async {
      final remote = MemoryFolder();
      final a = MemoryStore('a', clock: clock)
        ..edit('items', '1', {'name': '"x"'});
      await engine(a, remote).sync();
      final bytes = remote.files['devices/a/1.chg']!;
      expect(
        () => const TestCipher().open('devices/a/2.chg', bytes),
        throwsA(isA<SyncCipherException>()),
      );
      final b = MemoryStore('b', clock: clock);
      expect(
        engine(b, remote, cipher: const TestCipher('other')).sync(),
        throwsA(isA<SyncCipherException>()),
      );
    },
  );

  test('a new device starts from the snapshot; old batches are cleaned up '
      'only after every device has them', () async {
    final remote = MemoryFolder();
    final a = MemoryStore('a', clock: clock);
    final b = MemoryStore('b', clock: clock);
    for (var i = 0; i < 4; i++) {
      now += 1000;
      a.edit('items', '$i', {'name': '"$i"'});
      await engine(a, remote, snapshotAfter: 3).sync();
    }
    await engine(b, remote, snapshotAfter: 3).sync();
    expect(b.rows, a.rows);
    // b has seen everything now; a's next sync may clean up.
    await engine(a, remote, snapshotAfter: 3).sync();
    final batches = remote.files.keys.where((k) => k.endsWith('.chg'));
    expect(batches.length, lessThan(4));

    final c = MemoryStore('c', clock: clock);
    final report = await engine(c, remote, snapshotAfter: 3).sync();
    expect(report.downloaded, greaterThan(0));
    expect(c.rows, a.rows);
  });

  test('three devices, random offline edits and deletes, random sync order: '
      'all end up identical, newest value per field', () async {
    for (var seed = 0; seed < 25; seed++) {
      final rng = Random(seed);
      final remote = MemoryFolder();
      // Clocks skewed by up to a minute.
      final skew = {
        for (final d in ['a', 'b', 'c']) d: rng.nextInt(60000),
      };
      final devices = [
        for (final d in ['a', 'b', 'c'])
          MemoryStore(d, clock: () => now + skew[d]!),
      ];
      final engines = [
        for (final d in devices)
          engine(d, remote, snapshotAfter: 5 + rng.nextInt(10)),
      ];
      for (var step = 0; step < 60; step++) {
        now += rng.nextInt(5000);
        final i = rng.nextInt(3);
        final d = devices[i];
        final row = 'r${rng.nextInt(6)}';
        switch (rng.nextInt(10)) {
          case 0:
            d.delete('items', row);
          case 1 || 2:
            await engines[i].sync();
          default:
            if (!d.isDeleted('items', row)) {
              d.edit('items', row, {
                ['name', 'amount', 'note'][rng.nextInt(3)]: '"$seed-$step-$i"',
              });
            }
        }
      }
      // Everyone online: two full rounds settle everything.
      for (var round = 0; round < 2; round++) {
        for (final e in engines) {
          now += 1000;
          await e.sync();
        }
      }
      expect(devices[1].rows, devices[0].rows, reason: 'seed $seed');
      expect(devices[2].rows, devices[0].rows, reason: 'seed $seed');

      // The surviving value of each field is the newest change anywhere.
      final everything = [for (final d in devices) ...await d.allChanges()];
      for (final c in compact(everything)) {
        if (c.isTombstone) {
          expect(devices[0].rows['items']?.containsKey(c.rowId), isNot(true));
        } else {
          expect(
            devices[0].rows[c.entity]?[c.rowId]?[c.field],
            c.value,
            reason: 'seed $seed ${c.rowId}.${c.field}',
          );
        }
      }
    }
  });
}
