import 'dart:convert';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

/// Records field-level changes with an HLC timestamp so the sync engine can
/// merge devices column by column.
///
/// Call it inside the same database transaction as the write it describes.
class Journal {
  Journal(this._db, {int Function()? nowMillis, Uuid? uuid})
    : _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final int Function() _nowMillis;
  final Uuid _uuid;

  static const _deviceIdKey = 'device_id';
  static const _hlcKey = 'hlc';
  static const tombstone = '_deleted';

  Future<Hlc>? _loading;
  Hlc? _clock;

  /// This install's id; created on first use and kept for the device's life.
  Future<String> deviceId() async => (await _load()).node;

  Future<Hlc> _load() => _loading ??= () async {
    final rows = await (_db.select(
      _db.meta,
    )..where((m) => m.key.isIn([_deviceIdKey, _hlcKey]))).get();
    final byKey = {for (final r in rows) r.key: r.value};
    var device = byKey[_deviceIdKey];
    if (device == null) {
      device = _uuid.v7();
      await _db
          .into(_db.meta)
          .insertOnConflictUpdate(
            MetaCompanion.insert(key: _deviceIdKey, value: device),
          );
    }
    final stored = byKey[_hlcKey];
    _clock = stored == null ? Hlc.zero(device) : Hlc.parse(stored);
    return _clock!;
  }();

  Future<Hlc> _tick() async {
    await _load();
    final next = _clock!.send(_nowMillis());
    _clock = next;
    await _db
        .into(_db.meta)
        .insertOnConflictUpdate(
          MetaCompanion.insert(key: _hlcKey, value: next.pack()),
        );
    return next;
  }

  /// Advances the clock past a change merged from another device, so later
  /// local edits are newer than everything already seen.
  Future<void> receive(Hlc remote) async {
    await _load();
    final next = _clock!.receive(remote, _nowMillis());
    _clock = next;
    await _db
        .into(_db.meta)
        .insertOnConflictUpdate(
          MetaCompanion.insert(key: _hlcKey, value: next.pack()),
        );
  }

  /// Logs every column of a new row.
  Future<void> inserted(String entity, String rowId, Insertable<Object?> row) =>
      _log(entity, rowId, sqlValues(row));

  /// Logs only the columns that differ between [before] and [after].
  Future<void> updated(
    String entity,
    String rowId,
    Insertable<Object?> before,
    Insertable<Object?> after,
  ) {
    final old = sqlValues(before);
    final changed = {
      for (final MapEntry(:key, :value) in sqlValues(after).entries)
        if (!old.containsKey(key) || old[key] != value) key: value,
    };
    return _log(entity, rowId, changed);
  }

  /// Logs [fields] (SQL values by column) as changed now, e.g. rows put
  /// back by restoring a backup, so they win over older synced values.
  Future<void> rewritten(
    String entity,
    String rowId,
    Map<String, Object?> fields,
  ) => _log(entity, rowId, fields);

  Future<void> deleted(String entity, String rowId) =>
      _log(entity, rowId, {tombstone: true});

  Future<void> _log(
    String entity,
    String rowId,
    Map<String, Object?> fields,
  ) async {
    if (fields.isEmpty) return;
    final hlc = (await _tick()).pack();
    await _db.batch((b) {
      b.insertAll(_db.changeLog, [
        for (final MapEntry(:key, :value) in fields.entries)
          ChangeLogCompanion.insert(
            entity: entity,
            rowId: rowId,
            field: key,
            value: jsonEncode(value),
            hlc: hlc,
          ),
      ]);
    });
  }
}

/// A row's column values as stored in SQL (after type converters).
Map<String, Object?> sqlValues(Insertable<Object?> row) => {
  for (final MapEntry(:key, :value) in row.toColumns(false).entries)
    key: (value as Variable<Object>).value,
};
