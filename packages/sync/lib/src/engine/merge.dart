import '../hlc/hlc.dart';
import 'changes.dart';

/// What the local database knows about a field or a row, for merging.
abstract interface class MergeState {
  /// Newest HLC recorded for this field (local or merged), if any.
  Future<Hlc?> fieldHlc(String entity, String rowId, String field);

  /// HLC of the row's deletion, if it is deleted.
  Future<Hlc?> tombstoneHlc(String entity, String rowId);
}

/// Result of merging incoming changes.
class MergeOutcome {
  MergeOutcome(this.winners, this.conflicts);

  /// Changes newer than what is stored: apply them.
  final List<FieldChange> winners;
  final List<SyncConflict> conflicts;
}

/// Decides which [incoming] changes win, field by field:
///
/// - the newer HLC wins for the same field; different fields of a row are
///   both kept;
/// - a deletion wins over edits made before it;
/// - an edit made after the row was deleted (on another device) is not
///   applied but reported as a conflict for the user to settle;
/// - re-receiving a change already merged does nothing (idempotent), so
///   batches can arrive in any order and more than once.
Future<MergeOutcome> mergeChanges(
  List<FieldChange> incoming,
  MergeState state,
) async {
  final sorted = [...incoming]..sort((a, b) => a.hlc.compareTo(b.hlc));
  // Winners so far in this merge, which the state does not know yet.
  final fields = <(String, String, String), Hlc>{};
  final tombstones = <(String, String), Hlc>{};
  final winners = <(String, String, String), FieldChange>{};
  final conflicts = <SyncConflict>[];

  Future<Hlc?> tombOf(String e, String r) async =>
      tombstones[(e, r)] ?? await state.tombstoneHlc(e, r);

  for (final c in sorted) {
    if (c.isTombstone) {
      final tomb = await tombOf(c.entity, c.rowId);
      if (tomb == null || c.hlc > tomb) {
        tombstones[(c.entity, c.rowId)] = c.hlc;
        winners[c.key] = c;
      }
      continue;
    }
    final tomb = await tombOf(c.entity, c.rowId);
    if (tomb != null) {
      if (c.hlc > tomb) {
        conflicts.add(
          SyncConflict(kind: ConflictKind.editedAfterDelete, change: c),
        );
      }
      continue;
    }
    final current =
        fields[c.key] ?? await state.fieldHlc(c.entity, c.rowId, c.field);
    if (current == null || c.hlc > current) {
      fields[c.key] = c.hlc;
      winners[c.key] = c;
    }
  }
  // Fields of rows deleted later in this same merge are moot.
  final kept = [
    for (final w in winners.values)
      if (w.isTombstone ||
          !tombstones.containsKey((w.entity, w.rowId)) ||
          w.hlc > tombstones[(w.entity, w.rowId)]!)
        w,
  ]..sort((a, b) => a.hlc.compareTo(b.hlc));
  return MergeOutcome(kept, conflicts);
}

/// The newest change per field, for a snapshot.
List<FieldChange> compact(Iterable<FieldChange> changes) {
  final newest = <(String, String, String), FieldChange>{};
  for (final c in changes) {
    final existing = newest[c.key];
    if (existing == null || c.hlc > existing.hlc) newest[c.key] = c;
  }
  final tombs = {
    for (final c in newest.values)
      if (c.isTombstone) (c.entity, c.rowId): c.hlc,
  };
  // A deleted row needs only its tombstone (edits after it are conflicts).
  return [
    for (final c in newest.values)
      if (c.isTombstone || !tombs.containsKey((c.entity, c.rowId))) c,
  ]..sort((a, b) => a.hlc.compareTo(b.hlc));
}
