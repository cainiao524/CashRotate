import 'dart:convert';
import 'dart:math';

import '../crypto/sync_cipher.dart';
import '../hlc/hlc.dart';
import '../remote/remote_folder.dart';
import 'changes.dart';
import 'merge.dart';

/// The local database, as the sync engine needs it.
abstract interface class SyncStore implements MergeState {
  /// This install's id (the HLC node and the folder under `devices/`).
  Future<String> deviceId();

  /// Local changes not uploaded yet, oldest first.
  Future<List<LocalChange>> pending();
  Future<void> markUploaded(Iterable<int> localIds);

  /// Writes merged changes to the tables and remembers their HLCs (as
  /// already uploaded, so they are not sent back).
  Future<void> apply(List<FieldChange> winners);
  Future<void> addConflicts(List<SyncConflict> conflicts);

  /// Advances the local clock past a merged change.
  Future<void> receiveClock(Hlc remote);

  /// Highest batch seq merged per other device.
  Future<Map<String, int>> seen();
  Future<void> setSeen(String device, int seq);

  /// This device's last uploaded batch seq (0 before the first).
  Future<int> lastUploadedSeq();
  Future<void> setLastUploadedSeq(int seq);

  /// Every change on record, local and merged, for a snapshot.
  Future<List<FieldChange>> allChanges();
}

/// What one sync did.
class SyncReport {
  SyncReport({
    required this.downloaded,
    required this.uploaded,
    required this.applied,
    required this.conflicts,
    required this.snapshotWritten,
    required this.deleted,
  });

  /// Batches (and a snapshot, if bootstrapping) merged.
  final int downloaded;

  /// Local changes uploaded.
  final int uploaded;

  /// Changes that won and were written locally.
  final int applied;
  final int conflicts;
  final bool snapshotWritten;

  /// Old batch and snapshot files removed from the server.
  final int deleted;
}

/// The WebDAV folder protocol (CLAUDE.md, "同步"):
///
/// - `devices/<device>/<seq>.chg`: encrypted change batches, append-only;
/// - `devices/<device>/seen.json`: how far that device has merged others;
/// - `snapshots/snap-<millis>-<device>.bin`: encrypted full state.
///
/// Every file is uploaded under a temporary name and then moved into place,
/// so readers never see half a file. Each device lists the others' latest
/// seqs and downloads only batches it has not seen. Old batches are deleted
/// only once a snapshot includes them and every device has merged them.
class SyncEngine {
  SyncEngine({
    required this.store,
    required this.remote,
    required this.cipher,
    int Function()? nowMillis,
    Random? random,
    this.snapshotAfterBatches = 100,
    this.keepSnapshots = 2,
  }) : _now = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _random = random ?? Random.secure();

  final SyncStore store;
  final RemoteFolder remote;
  final SyncCipher cipher;
  final int Function() _now;
  final Random _random;

  /// Write a snapshot once the folder holds this many batch files.
  final int snapshotAfterBatches;
  final int keepSnapshots;

  static const devicesDir = 'devices';
  static const snapshotsDir = 'snapshots';
  static final _batchName = RegExp(r'^(\d+)\.chg$');
  static final _snapshotName = RegExp(r'^snap-(\d+)-(.+)\.bin$');

  Future<SyncReport> sync() async {
    final me = await store.deviceId();
    await remote.makeDirectory('$devicesDir/$me');
    await remote.makeDirectory(snapshotsDir);

    var downloaded = 0;
    var applied = 0;
    var conflicts = 0;
    Future<void> mergeIn(List<FieldChange> changes) async {
      final outcome = await mergeChanges(changes, store);
      if (outcome.winners.isNotEmpty) await store.apply(outcome.winners);
      if (outcome.conflicts.isNotEmpty) {
        await store.addConflicts(outcome.conflicts);
      }
      if (changes.isNotEmpty) {
        await store.receiveClock(
          changes.map((c) => c.hlc).reduce((a, b) => a > b ? a : b),
        );
      }
      applied += outcome.winners.length;
      conflicts += outcome.conflicts.length;
    }

    // A device that has never synced starts from the newest snapshot.
    final snapshots = await _snapshots();
    if ((await store.seen()).isEmpty && snapshots.isNotEmpty) {
      final latest = snapshots.last;
      final path = '$snapshotsDir/${latest.name}';
      final bytes = await remote.read(path);
      if (bytes != null) {
        final snapshot = Snapshot.decode(cipher.open(path, bytes));
        await mergeIn(snapshot.changes);
        for (final MapEntry(:key, :value) in snapshot.coverage.entries) {
          if (key != me) await store.setSeen(key, value);
        }
        downloaded++;
      }
    }

    // Pull: every other device's batches we have not merged, in order.
    final seen = await store.seen();
    final batchCounts = <String, int>{};
    for (final dev in await remote.list(devicesDir)) {
      if (!dev.isDirectory) continue;
      final seqs = await _batchSeqs(dev.name);
      batchCounts[dev.name] = seqs.length;
      if (dev.name == me) continue;
      for (final seq in seqs) {
        if (seq <= (seen[dev.name] ?? 0)) continue;
        final path = '$devicesDir/${dev.name}/$seq.chg';
        final bytes = await remote.read(path);
        if (bytes == null) continue; // cleaned up meanwhile
        final batch = ChangeBatch.decode(cipher.open(path, bytes));
        await mergeIn(batch.changes);
        await store.setSeen(dev.name, seq);
        downloaded++;
      }
    }

    // Push: local changes as the next batch.
    final pending = await store.pending();
    var lastSeq = await store.lastUploadedSeq();
    if (pending.isNotEmpty) {
      final seq = lastSeq + 1;
      final batch = ChangeBatch(
        device: me,
        seq: seq,
        changes: [for (final p in pending) p.change],
      );
      await _upload('$devicesDir/$me/$seq.chg', batch.encode());
      await store.markUploaded(pending.map((p) => p.localId));
      await store.setLastUploadedSeq(seq);
      lastSeq = seq;
      batchCounts[me] = (batchCounts[me] ?? 0) + 1;
    }

    // Tell the others how far this device has merged (for cleanup).
    final mySeen = {...await store.seen(), me: lastSeq};
    await _upload('$devicesDir/$me/seen.json', utf8.encode(jsonEncode(mySeen)));

    var snapshotWritten = false;
    final total = batchCounts.values.fold(0, (a, b) => a + b);
    if (total >= snapshotAfterBatches) {
      final snapshot = Snapshot(
        device: me,
        createdAt: _now(),
        coverage: mySeen,
        changes: compact(await store.allChanges()),
      );
      await _upload(
        '$snapshotsDir/snap-${snapshot.createdAt}-$me.bin',
        snapshot.encode(),
      );
      snapshotWritten = true;
    }

    final deleted = await _cleanUp(me);
    return SyncReport(
      downloaded: downloaded,
      uploaded: pending.length,
      applied: applied,
      conflicts: conflicts,
      snapshotWritten: snapshotWritten,
      deleted: deleted,
    );
  }

  Future<void> _upload(String path, List<int> plain) async {
    final temp = '$path.tmp-${_random.nextInt(1 << 32).toRadixString(16)}';
    await remote.write(temp, cipher.seal(path, plain));
    await remote.move(temp, path);
  }

  Future<List<int>> _batchSeqs(String device) async => [
    for (final e in await remote.list('$devicesDir/$device'))
      if (!e.isDirectory)
        if (_batchName.firstMatch(e.name) case final m?) int.parse(m[1]!),
  ]..sort();

  Future<List<RemoteEntry>> _snapshots() async {
    final list = [
      for (final e in await remote.list(snapshotsDir))
        if (!e.isDirectory && _snapshotName.hasMatch(e.name)) e,
    ];
    int stamp(RemoteEntry e) =>
        int.parse(_snapshotName.firstMatch(e.name)![1]!);
    return list..sort((a, b) => stamp(a).compareTo(stamp(b)));
  }

  /// Deletes batches every device has merged and the newest snapshot
  /// includes, and all but the newest [keepSnapshots] snapshots.
  Future<int> _cleanUp(String me) async {
    final snapshots = await _snapshots();
    if (snapshots.isEmpty) return 0;
    final latestPath = '$snapshotsDir/${snapshots.last.name}';
    final latestBytes = await remote.read(latestPath);
    if (latestBytes == null) return 0;
    final coverage = Snapshot.decode(cipher.open(latestPath, latestBytes))
        .coverage;

    final devices = [
      for (final d in await remote.list(devicesDir))
        if (d.isDirectory) d.name,
    ];
    final seenBy = <String, Map<String, int>>{};
    for (final d in devices) {
      final path = '$devicesDir/$d/seen.json';
      final bytes = await remote.read(path);
      if (bytes == null) return 0; // a device we know nothing about: wait
      seenBy[d] = (jsonDecode(utf8.decode(cipher.open(path, bytes))) as Map)
          .cast<String, int>();
    }

    var deleted = 0;
    for (final d in devices) {
      var limit = coverage[d] ?? 0;
      for (final other in devices) {
        if (other == d) continue;
        limit = min(limit, seenBy[other]![d] ?? 0);
      }
      for (final seq in await _batchSeqs(d)) {
        if (seq <= limit) {
          await remote.delete('$devicesDir/$d/$seq.chg');
          deleted++;
        }
      }
    }
    for (final old in snapshots.take(
      max(0, snapshots.length - keepSnapshots),
    )) {
      await remote.delete('$snapshotsDir/${old.name}');
      deleted++;
    }
    return deleted;
  }
}
