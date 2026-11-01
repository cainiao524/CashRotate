import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:sodium/sodium_sumo.dart';

import '../db/app_database.dart';
import '../journal.dart';
import '../sync/drift_sync_store.dart';
import '../sync/sync_crypto.dart';

/// One automatic backup on this phone.
class LocalBackup {
  const LocalBackup(this.file, this.createdAt, this.size);

  final File file;
  final DateTime createdAt;
  final int size;
}

/// The wrong password, or not a CashRotate backup.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// Automatic daily backups kept on the phone (newest [keep]), and backup
/// files the user exports and imports with a password of their choice.
///
/// A backup holds every synced table's rows (items, prices, charges, price
/// history, settings, exchange rates) as JSON, sealed like a sync file.
/// Restoring replaces those tables and records the restored rows as new
/// changes, so sync carries the restored state to the other devices
/// instead of overwriting it.
class BackupService {
  BackupService(
    this._db,
    this._journal,
    this._sodium,
    this.directory, {
    this.keep = 7,
    this.kdf = KdfParams.standard,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Journal _journal;
  final SodiumSumo _sodium;
  final Directory directory;
  final int keep;

  /// Argon2id cost for exported files; tests pass a cheap one.
  final KdfParams kdf;
  final DateTime Function() _now;

  static const _keyMeta = 'backup_key';
  static const _lastMeta = 'backup_last';
  static const _path = 'backup';
  static final _exportMagic = ascii.encode('CRB1');
  static final _name = RegExp(r'^backup-(\d+)\.crb$');

  // --- contents ------------------------------------------------------------

  Future<Map<String, List<Map<String, Object?>>>> _dump() async => {
    for (final table in syncedTables.keys)
      table: [
        for (final row
            in await _db.customSelect('SELECT * FROM "$table"').get())
          row.data,
      ],
  };

  List<int> _encode(Map<String, List<Map<String, Object?>>> tables) =>
      utf8.encode(
        jsonEncode({
          'format': 1,
          'createdAt': _now().toUtc().millisecondsSinceEpoch,
          'tables': tables,
        }),
      );

  static String _rowId(String table, Map<String, Object?> row) =>
      syncedTables[table]!.map((k) => '${row[k]}').join('/');

  /// Replaces the synced tables with [bytes]' rows and journals the change.
  Future<void> _restore(List<int> bytes) async {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (j['format'] != 1) throw const BackupException('unknown format');
    final tables = (j['tables']! as Map).cast<String, Object?>();
    await _db.transaction(() async {
      final before = await _dump();
      // Children first, so the foreign keys never dangle.
      for (final table in syncedTables.keys.toList().reversed) {
        await _db.customStatement('DELETE FROM "$table"');
      }
      for (final table in syncedTables.keys) {
        final rows = (tables[table] as List? ?? const [])
            .cast<Map<String, Object?>>();
        final restored = <String>{};
        for (final row in rows) {
          final columns = row.keys.toList();
          await _db.customInsert(
            'INSERT INTO "$table" (${columns.map((c) => '"$c"').join(', ')}) '
            'VALUES (${List.filled(columns.length, '?').join(', ')})',
            variables: [for (final c in columns) _variable(row[c])],
          );
          final id = _rowId(table, row);
          restored.add(id);
          // Every column, as a new row is journaled.
          await _journal.rewritten(table, id, {
            for (final c in columns) c: row[c],
          });
        }
        for (final old in before[table]!) {
          final id = _rowId(table, old);
          if (!restored.contains(id)) await _journal.deleted(table, id);
        }
      }
    });
    // Tell every open query the tables changed.
    _db.notifyUpdates({
      for (final t in _db.allTables)
        if (syncedTables.containsKey(t.actualTableName)) TableUpdate.onTable(t),
    });
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
    null => const Variable(null),
    final int i => Variable.withInt(i),
    final double d => Variable.withReal(d),
    final String s => Variable.withString(s),
    final Uint8List b => Variable.withBlob(b),
    _ => Variable.withString('$v'),
  };

  // --- automatic backups on the phone -------------------------------------

  Future<SodiumCipher> _localCipher() async {
    final row = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_keyMeta))).getSingleOrNull();
    var key = row?.value;
    if (key == null) {
      key = base64.encode(SyncKeys(_sodium).newDataKey().extractBytes());
      await _db
          .into(_db.meta)
          .insertOnConflictUpdate(
            MetaCompanion.insert(key: _keyMeta, value: key),
          );
    }
    return SodiumCipher(
      _sodium,
      SecureKey.fromList(_sodium, base64.decode(key)),
    );
  }

  Future<List<LocalBackup>> list() async {
    if (!directory.existsSync()) return const [];
    final backups = <LocalBackup>[];
    for (final f in directory.listSync().whereType<File>()) {
      final m = _name.firstMatch(f.uri.pathSegments.last);
      if (m == null) continue;
      backups.add(
        LocalBackup(
          f,
          DateTime.fromMillisecondsSinceEpoch(int.parse(m[1]!), isUtc: true),
          f.lengthSync(),
        ),
      );
    }
    return backups..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Writes a backup now and keeps the newest [keep].
  Future<LocalBackup> backUpNow() async {
    directory.createSync(recursive: true);
    final at = _now().toUtc();
    final file = File(
      '${directory.path}/backup-${at.millisecondsSinceEpoch}.crb',
    );
    final sealed = (await _localCipher()).seal(_path, _encode(await _dump()));
    await file.writeAsBytes(sealed, flush: true);
    for (final old in (await list()).skip(keep)) {
      old.file.deleteSync();
    }
    await _db
        .into(_db.meta)
        .insertOnConflictUpdate(
          MetaCompanion.insert(key: _lastMeta, value: at.toIso8601String()),
        );
    return LocalBackup(file, at, sealed.length);
  }

  /// Backs up if the last automatic backup is a day old (or missing).
  Future<bool> backUpIfDue() async {
    final row = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_lastMeta))).getSingleOrNull();
    final last = row == null ? null : DateTime.tryParse(row.value);
    if (last != null && _now().toUtc().difference(last).inHours < 24) {
      return false;
    }
    await backUpNow();
    return true;
  }

  Future<void> restoreLocal(LocalBackup backup) async {
    final cipher = await _localCipher();
    await _restore(cipher.open(_path, await backup.file.readAsBytes()));
  }

  // --- exported files ------------------------------------------------------

  /// A backup file sealed with [password]: `"CRB1" ‖ salt ‖ ops ‖ mem ‖`
  /// a sync-style sealed body. Opens on any phone with the password.
  Future<Uint8List> export(String password) async {
    final keys = SyncKeys(_sodium, kdf: kdf);
    final salt = keys.newSalt();
    final cipher = SodiumCipher(_sodium, keys.derive(password, salt, kdf));
    final header = ByteData(8)
      ..setUint32(0, kdf.opsLimit)
      ..setUint32(4, kdf.memLimit);
    return Uint8List.fromList([
      ..._exportMagic,
      ...salt,
      ...header.buffer.asUint8List(),
      ...cipher.seal(_path, _encode(await _dump())),
    ]);
  }

  /// Restores an exported file. Throws [BackupException] for a wrong
  /// password or a file that is not a CashRotate backup.
  Future<void> import(List<int> bytes, String password) async {
    final saltBytes = _sodium.crypto.pwhash.saltBytes;
    final head = _exportMagic.length + saltBytes + 8;
    if (bytes.length < head ||
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'CRB1') {
      throw const BackupException('not a CashRotate backup');
    }
    final salt = Uint8List.fromList(bytes.sublist(4, 4 + saltBytes));
    final header = ByteData.sublistView(
      Uint8List.fromList(bytes.sublist(4 + saltBytes, head)),
    );
    final kdf = KdfParams(
      opsLimit: header.getUint32(0),
      memLimit: header.getUint32(4),
    );
    final keys = SyncKeys(_sodium, kdf: kdf);
    final cipher = SodiumCipher(_sodium, keys.derive(password, salt, kdf));
    final List<int> plain;
    try {
      plain = cipher.open(_path, bytes.sublist(head));
    } on Exception {
      throw const BackupException('wrong password');
    }
    await _restore(plain);
  }
}
