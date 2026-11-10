import 'dart:convert';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../items/item_repository.dart';
import '../journal.dart';
import 'drift_sync_store.dart';

/// A fixed expense deleted on one device and edited on another afterwards:
/// it stays deleted until the user decides.
typedef DeletedItemConflict = ({String itemId, String name, int changes});

/// Settles "edited after delete" conflicts (CLAUDE.md: changes needing a
/// decision go to pending conflicts): keep the item deleted, or bring it
/// back.
///
/// Bringing it back does not undo the deletion (other devices already
/// merged it). The item is rebuilt from this device's change log, with the
/// conflicting edits on top, as a new item that syncs like any other. Its
/// id is derived from the old one, so restoring on two devices gives the
/// same item rather than two copies.
class ConflictResolver {
  ConflictResolver(this._db, this._journal, this._items);

  final AppDatabase _db;
  final Journal _journal;
  final ItemRepository _items;

  DriftSyncStore get _store => DriftSyncStore(_db, _journal);

  /// Tables whose rows belong to an item (their `item_id` column).
  static const _children = {
    'price_phases',
    'occurrences',
    'price_history',
    'transactions',
  };

  /// Children deleted by the same device within this long of the item's
  /// deletion were deleted with it; older deletions (a shorter price
  /// schedule, re-planned charges) stay deleted.
  static const sameDeletion = Duration(seconds: 5);

  // The RFC 4122 URL namespace, for ids derived from a name.
  static const _namespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  /// The id a restored copy of [itemId] gets, on every device.
  static String restoredId(String itemId) =>
      const Uuid().v5(_namespace, 'cashrotate:restored:$itemId');

  Future<List<FieldChange>> _conflicts() async => [
    for (final c in await _store.conflictsJson())
      if (c['change'] case final Map<Object?, Object?> change)
        FieldChange.fromJson(change.cast<String, Object?>()),
  ];

  /// Newest known value of every column of a row (the tombstone left out),
  /// with the HLC it was set at.
  Future<Map<String, ({Object? value, Hlc hlc})>> _fields(
    String entity,
    String rowId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT field, value, hlc FROM change_log '
          'WHERE entity = ? AND row_id = ? AND field != ? ORDER BY hlc',
          variables: [
            Variable.withString(entity),
            Variable.withString(rowId),
            Variable.withString(tombstoneField),
          ],
          readsFrom: {_db.changeLog},
        )
        .get();
    return {
      for (final r in rows)
        r.read<String>('field'): (
          value: jsonDecode(r.read<String>('value')),
          hlc: Hlc.parse(r.read<String>('hlc')),
        ),
    };
  }

  /// The item a conflicting change is about, if any.
  Future<String?> _itemOf(FieldChange c) async {
    if (c.entity == 'items') return c.rowId;
    if (!_children.contains(c.entity)) return null;
    if (c.field == 'item_id') return jsonDecode(c.value) as String?;
    return (await _fields(c.entity, c.rowId))['item_id']?.value as String?;
  }

  /// Deleted items with edits waiting for a decision.
  Future<List<DeletedItemConflict>> deletedItems() async {
    final counts = <String, int>{};
    for (final c in await _conflicts()) {
      final id = await _itemOf(c);
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return [
      for (final MapEntry(:key, :value) in counts.entries)
        (
          itemId: key,
          name: (await _fields('items', key))['name']?.value as String? ?? '',
          changes: value,
        ),
    ];
  }

  /// Drops the conflicts about [itemId]: it stays deleted.
  Future<void> keepDeleted(String itemId) async {
    final kept = <Map<String, Object?>>[];
    for (final c in await _store.conflictsJson()) {
      final change = FieldChange.fromJson(
        (c['change']! as Map).cast<String, Object?>(),
      );
      if (await _itemOf(change) != itemId) kept.add(c);
    }
    await _store.replaceConflicts(kept);
  }

  /// Brings [itemId] back as a new item with the conflicting edits applied;
  /// its paid charges, price history and payment records follow. Returns
  /// the new id, or null when this device does not know enough of the item
  /// to rebuild it (the conflicts are kept then).
  Future<String?> restore(String itemId) => _db.transaction(() async {
    final tomb = await _store.tombstoneHlc('items', itemId);
    final newId = restoredId(itemId);
    final exists =
        await (_db.select(
          _db.items,
        )..where((i) => i.id.equals(newId))).getSingleOrNull() !=
        null;
    if (tomb == null || exists) {
      // Not deleted here, or already restored (here or on another device).
      await keepDeleted(itemId);
      return exists ? newId : itemId;
    }

    final edits = <FieldChange>[];
    for (final c in await _conflicts()) {
      if (await _itemOf(c) == itemId) edits.add(c);
    }

    /// A row as last known, with the conflicting edits on top, as SQL
    /// values by column.
    Future<Map<String, Object?>> row(String entity, String rowId) async {
      final fields = await _fields(entity, rowId);
      for (final c in edits) {
        if (c.entity != entity || c.rowId != rowId || c.isTombstone) continue;
        final known = fields[c.field];
        if (known == null || c.hlc > known.hlc) {
          fields[c.field] = (value: jsonDecode(c.value), hlc: c.hlc);
        }
      }
      return {
        for (final MapEntry(:key, :value) in fields.entries)
          key: switch (value.value) {
            final bool b => b ? 1 : 0, // booleans are stored as 0 / 1
            final other => other,
          },
      };
    }

    /// Rows of [entity] that belonged to the item when it was deleted.
    Future<List<String>> childrenAtDeletion(String entity) async {
      final rows = await _db
          .customSelect(
            'SELECT DISTINCT row_id FROM change_log '
            "WHERE entity = ? AND field = 'item_id' AND value = ?",
            variables: [
              Variable.withString(entity),
              Variable.withString(jsonEncode(itemId)),
            ],
            readsFrom: {_db.changeLog},
          )
          .get();
      final alive = <String>[];
      for (final r in rows) {
        final id = r.read<String>('row_id');
        final deleted = await _store.tombstoneHlc(entity, id);
        if (deleted == null ||
            (deleted.node == tomb.node &&
                (tomb.millis - deleted.millis).abs() <=
                    sameDeletion.inMilliseconds)) {
          alive.add(id);
        }
      }
      return alive;
    }

    final ItemRow item;
    try {
      item = _db.items.map({...await row('items', itemId), 'id': newId});
    } on Object {
      return null;
    }
    await _db.into(_db.items).insert(item);
    await _journal.inserted('items', newId, item);

    for (final id in await childrenAtDeletion('price_phases')) {
      final data = await row('price_phases', id);
      final seq = data['seq'];
      if (seq is! int) continue;
      final phase = _db.pricePhases.map({
        ...data,
        'id': ItemRepository.phaseId(newId, seq),
        'item_id': newId,
      });
      await _db.into(_db.pricePhases).insertOnConflictUpdate(phase);
      await _journal.inserted('price_phases', phase.id, phase);
    }

    // Paid and skipped charges are history; pending ones are planned anew.
    for (final id in await childrenAtDeletion('occurrences')) {
      final data = await row('occurrences', id);
      final dueOn = data['due_on'];
      if (dueOn is! String || data['state'] == 'pending') continue;
      final occurrence = _db.occurrences.map({
        ...data,
        'id': '$newId:$dueOn',
        'item_id': newId,
      });
      await _db.into(_db.occurrences).insertOnConflictUpdate(occurrence);
      await _journal.inserted('occurrences', occurrence.id, occurrence);
    }

    for (final id in await childrenAtDeletion('price_history')) {
      final change = _db.priceHistory.map({
        ...await row('price_history', id),
        'id': const Uuid().v5(_namespace, 'cashrotate:restored:$id'),
        'item_id': newId,
      });
      await _db.into(_db.priceHistory).insertOnConflictUpdate(change);
      await _journal.inserted('price_history', change.id, change);
    }

    // Payment records were never deleted: point them at the new item.
    final payments = await (_db.select(
      _db.transactions,
    )..where((t) => t.itemId.equals(itemId))).get();
    for (final t in payments) {
      final occurrence = t.occurrenceId;
      final after = t.copyWith(
        itemId: Value(newId),
        occurrenceId: Value(
          occurrence != null && occurrence.startsWith('$itemId:')
              ? '$newId${occurrence.substring(itemId.length)}'
              : occurrence,
        ),
      );
      await _db.update(_db.transactions).replace(after);
      await _journal.updated('transactions', t.id, t, after);
    }

    await _items.refreshAll(); // plan its upcoming charges
    await keepDeleted(itemId); // settled
    return newId;
  });
}
