import 'package:cashrotate_sync/cashrotate_sync.dart';

/// A device's database in memory: rows as field maps, a change log with
/// HLCs, and the sync bookkeeping. Mirrors what the app does with drift.
class MemoryStore implements SyncStore {
  MemoryStore(this.id, {required this.clock});

  final String id;

  /// Wall clock for this device (tests skew it per device).
  int Function() clock;
  late Hlc _hlc = Hlc.zero(id);

  /// entity → row id → field → JSON value. Deleted rows are removed.
  final rows = <String, Map<String, Map<String, String>>>{};
  final log = <({int id, FieldChange change, bool uploaded})>[];
  final conflicts = <SyncConflict>[];
  final _seen = <String, int>{};
  int _lastSeq = 0;
  int _nextLocalId = 1;

  /// A local edit: sets [fields] on a row (creating it) and logs them.
  void edit(String entity, String row, Map<String, String> fields) {
    _hlc = _hlc.send(clock());
    rows
        .putIfAbsent(entity, () => {})
        .putIfAbsent(row, () => {})
        .addAll(fields);
    for (final MapEntry(:key, :value) in fields.entries) {
      log.add((
        id: _nextLocalId++,
        change: FieldChange(
          entity: entity,
          rowId: row,
          field: key,
          value: value,
          hlc: _hlc,
        ),
        uploaded: false,
      ));
    }
  }

  void delete(String entity, String row) {
    _hlc = _hlc.send(clock());
    rows[entity]?.remove(row);
    log.add((
      id: _nextLocalId++,
      change: FieldChange(
        entity: entity,
        rowId: row,
        field: tombstoneField,
        value: 'true',
        hlc: _hlc,
      ),
      uploaded: false,
    ));
  }

  bool isDeleted(String entity, String row) => log.any(
    (l) =>
        l.change.entity == entity &&
        l.change.rowId == row &&
        l.change.isTombstone,
  );

  @override
  Future<String> deviceId() async => id;

  @override
  Future<Hlc?> fieldHlc(String entity, String rowId, String field) async {
    Hlc? best;
    for (final l in log) {
      final c = l.change;
      if (c.entity == entity && c.rowId == rowId && c.field == field) {
        if (best == null || c.hlc > best) best = c.hlc;
      }
    }
    return best;
  }

  @override
  Future<Hlc?> tombstoneHlc(String entity, String rowId) =>
      fieldHlc(entity, rowId, tombstoneField);

  @override
  Future<List<LocalChange>> pending() async => [
    for (final l in log)
      if (!l.uploaded) LocalChange(l.id, l.change),
  ];

  @override
  Future<void> markUploaded(Iterable<int> localIds) async {
    final ids = localIds.toSet();
    for (var i = 0; i < log.length; i++) {
      final l = log[i];
      if (ids.contains(l.id)) {
        log[i] = (id: l.id, change: l.change, uploaded: true);
      }
    }
  }

  @override
  Future<void> apply(List<FieldChange> winners) async {
    for (final c in winners) {
      if (c.isTombstone) {
        rows[c.entity]?.remove(c.rowId);
      } else {
        rows
                .putIfAbsent(c.entity, () => {})
                .putIfAbsent(c.rowId, () => {})[c.field] =
            c.value;
      }
      log.add((id: _nextLocalId++, change: c, uploaded: true));
    }
  }

  @override
  Future<void> addConflicts(List<SyncConflict> c) async => conflicts.addAll(c);

  @override
  Future<void> receiveClock(Hlc remote) async {
    _hlc = _hlc.receive(remote, clock());
  }

  @override
  Future<Map<String, int>> seen() async => {..._seen};

  @override
  Future<void> setSeen(String device, int seq) async => _seen[device] = seq;

  @override
  Future<int> lastUploadedSeq() async => _lastSeq;

  @override
  Future<void> setLastUploadedSeq(int seq) async => _lastSeq = seq;

  @override
  Future<List<FieldChange>> allChanges() async => [
    for (final l in log) l.change,
  ];
}
