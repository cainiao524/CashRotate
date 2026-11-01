import 'dart:convert';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:sodium/sodium_sumo.dart';

import '../db/app_database.dart';
import '../journal.dart';
import 'drift_sync_store.dart';
import 'sync_crypto.dart';

/// Where this device syncs. Kept on this device only (never synced): the
/// WebDAV address, user and app password, and the unlocked data key, all
/// inside the encrypted database whose key the Android Keystore protects.
class SyncConfig {
  const SyncConfig({
    required this.url,
    required this.user,
    required this.password,
    this.dataKey,
    this.lastSyncAt,
    this.lastError,
  });

  factory SyncConfig.fromJson(Map<String, Object?> j) => SyncConfig(
    url: j['url']! as String,
    user: j['user']! as String,
    password: j['password']! as String,
    dataKey: j['dataKey'] as String?,
    lastSyncAt: j['lastSyncAt'] as int?,
    lastError: j['lastError'] as String?,
  );

  final String url;
  final String user;
  final String password;

  /// Base64 data key once the folder is unlocked on this device.
  final String? dataKey;

  /// UTC epoch milliseconds of the last successful sync.
  final int? lastSyncAt;
  final String? lastError;

  bool get unlocked => dataKey != null;

  SyncConfig copyWith({
    String? dataKey,
    int? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) => SyncConfig(
    url: url,
    user: user,
    password: password,
    dataKey: dataKey ?? this.dataKey,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );

  Map<String, Object?> toJson() => {
    'url': url,
    'user': user,
    'password': password,
    'dataKey': dataKey,
    'lastSyncAt': lastSyncAt,
    'lastError': lastError,
  };
}

/// What a sync attempt came to, for the status line.
enum SyncOutcome { synced, notSetUp, authFailed, offline, wrongKey, failed }

/// Connects the app to the user's WebDAV folder and runs the sync engine.
class SyncService {
  SyncService(
    this._db,
    this._journal,
    this._sodium, {
    RemoteFolder Function(SyncConfig config)? remoteFor,
    this.kdf = KdfParams.standard,
    int Function()? nowMillis,
    this.deviceName = 'Android',
  }) : _remoteFor = remoteFor ?? _webDav,
       _now = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final Journal _journal;
  final SodiumSumo _sodium;
  final RemoteFolder Function(SyncConfig config) _remoteFor;

  /// Argon2id cost; tests pass a cheap one.
  final KdfParams kdf;
  final int Function() _now;
  final String deviceName;

  static const _configKey = 'sync_config';

  /// Folder name inside the user's WebDAV space.
  static const folder = 'CashRotate';

  static RemoteFolder _webDav(SyncConfig c) {
    final base = Uri.parse(c.url.trim());
    final path = base.path.endsWith('/') ? base.path : '${base.path}/';
    return WebDavFolder(
      base.replace(path: '$path$folder/'),
      user: c.user,
      password: c.password,
    );
  }

  Future<SyncConfig?> config() async {
    final row = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_configKey))).getSingleOrNull();
    if (row == null) return null;
    return SyncConfig.fromJson(
      (jsonDecode(row.value) as Map).cast<String, Object?>(),
    );
  }

  Stream<SyncConfig?> watchConfig() =>
      (_db.select(
        _db.meta,
      )..where((m) => m.key.equals(_configKey))).watchSingleOrNull().map(
        (row) => row == null
            ? null
            : SyncConfig.fromJson(
                (jsonDecode(row.value) as Map).cast<String, Object?>(),
              ),
      );

  Future<void> _save(SyncConfig? c) async {
    if (c == null) {
      await (_db.delete(_db.meta)..where((m) => m.key.equals(_configKey))).go();
      return;
    }
    await _db
        .into(_db.meta)
        .insertOnConflictUpdate(
          MetaCompanion.insert(key: _configKey, value: jsonEncode(c.toJson())),
        );
  }

  /// Checks the server and credentials. True when the folder already holds
  /// a CashRotate sync (join it), false when it is new (set it up).
  Future<bool> connect(String url, String user, String password) async {
    final c = SyncConfig(url: url, user: user, password: password);
    final remote = _remoteFor(c);
    await remote.makeDirectory('');
    final existing = await SyncSetup(
      SyncKeys(_sodium, kdf: kdf),
      remote,
    ).readManifest();
    await _save(c);
    return existing != null;
  }

  Future<SyncSetup> _setup() async {
    final c = await config();
    if (c == null) throw StateError('Connect to a server first.');
    return SyncSetup(
      SyncKeys(_sodium, kdf: kdf),
      _remoteFor(c),
      nowMillis: _now,
    );
  }

  Future<void> _unlock(SecureKey key) async {
    final c = (await config())!;
    await _save(c.copyWith(dataKey: base64.encode(key.extractBytes())));
  }

  /// First device: creates the folder's keys.
  Future<void> create({
    required String password,
    required String recoveryCode,
  }) async {
    final key = await (await _setup()).create(
      password: password,
      recoveryCode: recoveryCode,
      deviceId: await _journal.deviceId(),
      deviceName: deviceName,
    );
    await _unlock(key);
  }

  /// Another device: unlocks with the sync password.
  Future<void> join(String password) async {
    final key = await (await _setup()).join(
      password: password,
      deviceId: await _journal.deviceId(),
      deviceName: deviceName,
    );
    await _unlock(key);
  }

  /// Forgotten password: unlocks with the recovery code, sets a new one.
  Future<void> recover({
    required String recoveryCode,
    required String newPassword,
  }) async {
    final key = await (await _setup()).recover(
      recoveryCode: recoveryCode,
      newPassword: newPassword,
    );
    await _unlock(key);
  }

  /// Stops syncing on this device. Local data and the cloud folder stay.
  Future<void> disconnect() => _save(null);

  /// One full sync. Never throws; the outcome and error are recorded.
  Future<(SyncOutcome, SyncReport?)> syncNow() async {
    final c = await config();
    if (c == null || !c.unlocked) return (SyncOutcome.notSetUp, null);
    try {
      final report = await SyncEngine(
        store: DriftSyncStore(_db, _journal),
        remote: _remoteFor(c),
        cipher: SodiumCipher(
          _sodium,
          SecureKey.fromList(_sodium, base64.decode(c.dataKey!)),
        ),
        nowMillis: _now,
      ).sync();
      await _save(c.copyWith(lastSyncAt: _now(), clearError: true));
      return (SyncOutcome.synced, report);
    } on WebDavException catch (e) {
      await _save(c.copyWith(lastError: e.toString()));
      return (e.isAuth ? SyncOutcome.authFailed : SyncOutcome.failed, null);
    } on SyncCipherException catch (e) {
      await _save(c.copyWith(lastError: e.toString()));
      return (SyncOutcome.wrongKey, null);
    } on Exception catch (e) {
      await _save(c.copyWith(lastError: e.toString()));
      final offline =
          e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException');
      return (offline ? SyncOutcome.offline : SyncOutcome.failed, null);
    }
  }

  /// Changes waiting to be uploaded.
  Future<int> pendingCount() async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM change_log WHERE uploaded = 0',
          readsFrom: {_db.changeLog},
        )
        .getSingle();
    return row.read<int>('n');
  }
}
