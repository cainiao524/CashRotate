import 'dart:convert';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../journal.dart';

/// Tables that sync, their key columns (a composite key's row id joins
/// the values with `/`), in the order rows are written so parents come
/// before children.
const syncedTables = <String, List<String>>{
  'app_settings': ['key'],
  'exchange_rates': ['base', 'quote'],
  'accounts': ['id'],
  'items': ['id'],
  'price_phases': ['id'],
  'occurrences': ['id'],
  'price_history': ['id'],
  'transactions': ['id'],
};

/// [SyncStore] over the encrypted drift database: the change log is the
/// journal, merged values are written with plain SQL (only to the tables
/// and columns above, whatever a downloaded file names).
class DriftSyncStore implements SyncStore {
  DriftSyncStore(this._db, this._journal);

  final AppDatabase _db;
  final Journal _journal;

  static const _seenKey = 'sync_seen';
  static const _lastSeqKey = 'sync_last_seq';
  static const _conflictsKey = 'sync_conflicts';

  @override
  Future<String> deviceId() => _journal.deviceId();

  FieldChange _change(ChangeLogRow row) => FieldChange(
    entity: row.entity,
    rowId: row.rowId,
    field: row.field,
    value: row.value,
    hlc: Hlc.parse(row.hlc),
  );

  @override
  Future<List<LocalChange>> pending() async {
    final rows =
        await (_db.select(_db.changeLog)
              ..where((c) => c.uploaded.equals(false))
              ..orderBy([(c) => OrderingTerm.asc(c.seq)]))
            .get();
    return [for (final r in rows) LocalChange(r.seq, _change(r))];
  }

  @override
  Future<void> markUploaded(Iterable<int> localIds) async {
    final ids = localIds.toList();
    for (var i = 0; i < ids.length; i += 500) {
      await (_db.update(_db.changeLog)
            ..where((c) => c.seq.isIn(ids.skip(i).take(500))))
          .write(const ChangeLogCompanion(uploaded: Value(true)));
    }
  }

  @override
  Future<Hlc?> fieldHlc(String entity, String rowId, String field) async {
    // Packed HLCs sort as text, so MAX is the newest.
    final row = await _db
        .customSelect(
          'SELECT MAX(hlc) AS h FROM change_log '
          'WHERE entity = ? AND row_id = ? AND field = ?',
          variables: [
            Variable.withString(entity),
            Variable.withString(rowId),
            Variable.withString(field),
          ],
          readsFrom: {_db.changeLog},
        )
        .getSingle();
    final h = row.read<String?>('h');
    return h == null ? null : Hlc.parse(h);
  }

  @override
  Future<Hlc?> tombstoneHlc(String entity, String rowId) =>
      fieldHlc(entity, rowId, tombstoneField);

  @override
  Future<void> apply(List<FieldChange> winners) => _db.transaction(() async {
    final byRow = <(String, String), List<FieldChange>>{};
    for (final c in winners) {
      if (!syncedTables.containsKey(c.entity)) continue; // unknown: ignore
      byRow.putIfAbsent((c.entity, c.rowId), () => []).add(c);
    }
    final order = syncedTables.keys.toList();
    final rows = byRow.keys.toList()
      ..sort((a, b) => order.indexOf(a.$1).compareTo(order.indexOf(b.$1)));
    final applied = <FieldChange>[];
    for (final key in rows) {
      final changes = byRow[key]!;
      if (await _applyRow(key.$1, key.$2, changes)) applied.addAll(changes);
    }
    await _db.batch((b) {
      b.insertAll(_db.changeLog, [
        for (final c in applied)
          ChangeLogCompanion.insert(
            entity: c.entity,
            rowId: c.rowId,
            field: c.field,
            value: c.value,
            hlc: c.hlc.pack(),
            uploaded: const Value(true),
          ),
      ]);
    });
  });

  /// Writes one row's winning changes. False when the row cannot be written
  /// (e.g. its insert lacks a required column); those changes are dropped.
  Future<bool> _applyRow(
    String entity,
    String rowId,
    List<FieldChange> changes,
  ) async {
    final table = _db.allTables.firstWhere((t) => t.actualTableName == entity);
    final keyColumns = syncedTables[entity]!;
    final keyValues = keyColumns.length == 1 ? [rowId] : rowId.split('/');
    if (keyValues.length != keyColumns.length) return false;
    final where = keyColumns.map((k) => '"$k" = ?').join(' AND ');
    final keyVars = [for (final v in keyValues) Variable.withString(v)];

    if (changes.any((c) => c.isTombstone)) {
      await _db.customUpdate(
        'DELETE FROM "$entity" WHERE $where',
        variables: keyVars,
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      return true;
    }

    final columns = table.columnsByName.keys.toSet();
    final values = <String, Object?>{
      for (final c in changes)
        if (columns.contains(c.field) && !keyColumns.contains(c.field))
          c.field: _sql(jsonDecode(c.value)),
    };
    if (values.isEmpty) return true;
    final exists = await _db
        .customSelect(
          'SELECT 1 FROM "$entity" WHERE $where',
          variables: keyVars,
          readsFrom: {table},
        )
        .getSingleOrNull();
    try {
      if (exists != null) {
        await _db.customUpdate(
          'UPDATE "$entity" SET '
          '${values.keys.map((c) => '"$c" = ?').join(', ')} WHERE $where',
          variables: [for (final v in values.values) _var(v), ...keyVars],
          updates: {table},
          updateKind: UpdateKind.update,
        );
      } else {
        final names = [...keyColumns, ...values.keys];
        await _db.customInsert(
          'INSERT INTO "$entity" (${names.map((n) => '"$n"').join(', ')}) '
          'VALUES (${List.filled(names.length, '?').join(', ')})',
          variables: [...keyVars, for (final v in values.values) _var(v)],
          updates: {table},
        );
      }
      return true;
    } on Exception {
      return false;
    }
  }

  /// SQL value of a JSON-decoded journal value (booleans are stored as 0/1).
  static Object? _sql(Object? v) => switch (v) {
    final bool b => b ? 1 : 0,
    _ => v,
  };

  static Variable<Object> _var(Object? v) => switch (v) {
    null => const Variable(null),
    final int i => Variable.withInt(i),
    final double d => Variable.withReal(d),
    final String s => Variable.withString(s),
    _ => Variable.withString(jsonEncode(v)),
  };

  @override
  Future<void> addConflicts(List<SyncConflict> conflicts) async {
    final existing = await conflictsJson();
    await _setMeta(
      _conflictsKey,
      jsonEncode([
        ...existing,
        for (final c in conflicts)
          {'kind': c.kind.name, 'change': c.change.toJson()},
      ]),
    );
  }

  /// Pending conflicts for the user to settle.
  Future<List<Map<String, Object?>>> conflictsJson() async {
    final raw = await _meta(_conflictsKey);
    if (raw == null) return [];
    return [
      for (final c in jsonDecode(raw) as List)
        (c as Map).cast<String, Object?>(),
    ];
  }

  Future<void> clearConflicts() => _setMeta(_conflictsKey, '[]');

  /// Keeps only [conflicts] (the rest were settled).
  Future<void> replaceConflicts(List<Map<String, Object?>> conflicts) =>
      _setMeta(_conflictsKey, jsonEncode(conflicts));

  @override
  Future<void> receiveClock(Hlc remote) => _journal.receive(remote);

  @override
  Future<Map<String, int>> seen() async {
    final raw = await _meta(_seenKey);
    return raw == null ? {} : (jsonDecode(raw) as Map).cast<String, int>();
  }

  @override
  Future<void> setSeen(String device, int seq) async =>
      _setMeta(_seenKey, jsonEncode({...await seen(), device: seq}));

  @override
  Future<int> lastUploadedSeq() async =>
      int.tryParse(await _meta(_lastSeqKey) ?? '') ?? 0;

  @override
  Future<void> setLastUploadedSeq(int seq) => _setMeta(_lastSeqKey, '$seq');

  @override
  Future<List<FieldChange>> allChanges() async => [
    for (final r in await _db.select(_db.changeLog).get())
      if (syncedTables.containsKey(r.entity)) _change(r),
  ];

  Future<String?> _meta(String key) async => (await (_db.select(
    _db.meta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setMeta(String key, String value) => _db
      .into(_db.meta)
      .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));
}
