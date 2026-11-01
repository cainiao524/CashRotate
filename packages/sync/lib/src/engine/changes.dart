import 'dart:convert';

import 'package:meta/meta.dart';

import '../hlc/hlc.dart';

/// Field name of a deletion marker.
const tombstoneField = '_deleted';

/// One column of one row, as of [hlc]. The unit of merging: devices agree
/// field by field, and the newer [hlc] wins.
@immutable
class FieldChange {
  const FieldChange({
    required this.entity,
    required this.rowId,
    required this.field,
    required this.value,
    required this.hlc,
  });

  factory FieldChange.fromJson(Map<String, Object?> j) => FieldChange(
    entity: j['e']! as String,
    rowId: j['r']! as String,
    field: j['f']! as String,
    value: j['v']! as String,
    hlc: Hlc.parse(j['h']! as String),
  );

  /// Table name, e.g. `items`.
  final String entity;
  final String rowId;

  /// SQL column name, or [tombstoneField].
  final String field;

  /// JSON-encoded SQL value.
  final String value;
  final Hlc hlc;

  bool get isTombstone => field == tombstoneField;
  (String, String, String) get key => (entity, rowId, field);

  Map<String, Object?> toJson() => {
    'e': entity,
    'r': rowId,
    'f': field,
    'v': value,
    'h': hlc.pack(),
  };

  @override
  bool operator ==(Object other) =>
      other is FieldChange &&
      other.key == key &&
      other.value == value &&
      other.hlc == hlc;

  @override
  int get hashCode => Object.hash(entity, rowId, field, value, hlc);

  @override
  String toString() => 'FieldChange($entity/$rowId.$field=$value @$hlc)';
}

/// A local change not yet uploaded, with its local log id.
@immutable
class LocalChange {
  const LocalChange(this.localId, this.change);
  final int localId;
  final FieldChange change;
}

/// Changes one device uploads at once: `devices/<device>/<seq>.chg`.
/// Append-only; never rewritten.
@immutable
class ChangeBatch {
  const ChangeBatch({
    required this.device,
    required this.seq,
    required this.changes,
  });

  factory ChangeBatch.decode(List<int> bytes) {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (j['format'] != format) {
      throw FormatException('Unknown batch format ${j['format']}');
    }
    return ChangeBatch(
      device: j['device']! as String,
      seq: j['seq']! as int,
      changes: [
        for (final c in j['changes']! as List)
          FieldChange.fromJson((c as Map).cast<String, Object?>()),
      ],
    );
  }

  static const format = 1;

  final String device;
  final int seq;
  final List<FieldChange> changes;

  List<int> encode() => utf8.encode(
    jsonEncode({
      'format': format,
      'device': device,
      'seq': seq,
      'changes': [for (final c in changes) c.toJson()],
    }),
  );
}

/// The whole merged state as field changes (the newest per field), plus how
/// far into each device's batches it reaches:
/// `snapshots/snap-<timestamp>-<device>.bin`.
@immutable
class Snapshot {
  const Snapshot({
    required this.device,
    required this.createdAt,
    required this.coverage,
    required this.changes,
  });

  factory Snapshot.decode(List<int> bytes) {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (j['format'] != format) {
      throw FormatException('Unknown snapshot format ${j['format']}');
    }
    return Snapshot(
      device: j['device']! as String,
      createdAt: j['createdAt']! as int,
      coverage: (j['coverage']! as Map).cast<String, int>(),
      changes: [
        for (final c in j['changes']! as List)
          FieldChange.fromJson((c as Map).cast<String, Object?>()),
      ],
    );
  }

  static const format = 1;

  final String device;

  /// UTC epoch milliseconds.
  final int createdAt;

  /// Highest batch seq per device that this snapshot includes.
  final Map<String, int> coverage;
  final List<FieldChange> changes;

  List<int> encode() => utf8.encode(
    jsonEncode({
      'format': format,
      'device': device,
      'createdAt': createdAt,
      'coverage': coverage,
      'changes': [for (final c in changes) c.toJson()],
    }),
  );
}

/// Why a change could not be merged automatically.
enum ConflictKind {
  /// Edited on one device after it was deleted on another. The row stays
  /// deleted until the user chooses to restore it.
  editedAfterDelete,
}

/// A change that needs the user to decide ("pending conflicts").
@immutable
class SyncConflict {
  const SyncConflict({required this.kind, required this.change});

  final ConflictKind kind;
  final FieldChange change;
}
