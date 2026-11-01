import 'dart:convert';
import 'dart:typed_data';

import 'package:local_auth/local_auth.dart';
import 'package:sodium/sodium_sumo.dart';

import '../db/app_database.dart';
import '../sync/sync_crypto.dart';

/// App lock settings for this device (never synced): a hashed PIN, whether
/// a fingerprint or face may unlock, and how long the app may stay in the
/// background before it locks again.
class AppLockConfig {
  const AppLockConfig({
    required this.hash,
    required this.salt,
    required this.pinLength,
    required this.kdf,
    this.biometric = false,
    this.timeoutSeconds = 0,
  });

  factory AppLockConfig.fromJson(Map<String, Object?> j) => AppLockConfig(
    hash: base64.decode(j['hash']! as String),
    salt: base64.decode(j['salt']! as String),
    pinLength: j['pinLength']! as int,
    kdf: KdfParams.fromJson((j['kdf']! as Map).cast<String, Object?>()),
    biometric: j['biometric'] == true,
    timeoutSeconds: j['timeout'] as int? ?? 0,
  );

  final Uint8List hash;
  final Uint8List salt;

  /// Digits in the PIN, so the pad checks as soon as the last one is typed.
  final int pinLength;
  final KdfParams kdf;
  final bool biometric;

  /// 0 = lock every time the app leaves the screen.
  final int timeoutSeconds;

  AppLockConfig copyWith({bool? biometric, int? timeoutSeconds}) =>
      AppLockConfig(
        hash: hash,
        salt: salt,
        pinLength: pinLength,
        kdf: kdf,
        biometric: biometric ?? this.biometric,
        timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      );

  Map<String, Object?> toJson() => {
    'hash': base64.encode(hash),
    'salt': base64.encode(salt),
    'pinLength': pinLength,
    'kdf': kdf.toJson(),
    'biometric': biometric,
    'timeout': timeoutSeconds,
  };
}

/// Stores and checks the app lock PIN (Argon2id, interactive cost).
class AppLockRepository {
  AppLockRepository(this._db, this._sodium, {KdfParams? kdf})
    : kdf =
          kdf ??
          KdfParams(
            opsLimit: _sodium.crypto.pwhash.opsLimitInteractive,
            memLimit: _sodium.crypto.pwhash.memLimitInteractive,
          );

  final AppDatabase _db;
  final SodiumSumo _sodium;
  final KdfParams kdf;

  static const _key = 'app_lock';

  /// Wrong PINs allowed before the pad pauses.
  static const freeAttempts = 5;

  Stream<AppLockConfig?> watch() =>
      (_db.select(_db.meta)..where((m) => m.key.equals(_key)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _parse(r.value));

  Future<AppLockConfig?> read() async {
    final r = await (_db.select(
      _db.meta,
    )..where((m) => m.key.equals(_key))).getSingleOrNull();
    return r == null ? null : _parse(r.value);
  }

  static AppLockConfig _parse(String raw) =>
      AppLockConfig.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());

  Future<void> _write(AppLockConfig? c) async {
    if (c == null) {
      await (_db.delete(_db.meta)..where((m) => m.key.equals(_key))).go();
    } else {
      await _db
          .into(_db.meta)
          .insertOnConflictUpdate(
            MetaCompanion.insert(key: _key, value: jsonEncode(c.toJson())),
          );
    }
  }

  Uint8List _hash(String pin, Uint8List salt, KdfParams params) =>
      SyncKeys(_sodium).derive(pin, salt, params).extractBytes();

  /// Turns the lock on (or changes the PIN), keeping other settings.
  Future<void> setPin(String pin) async {
    final current = await read();
    final salt = SyncKeys(_sodium).newSalt();
    await _write(
      AppLockConfig(
        hash: _hash(pin, salt, kdf),
        salt: salt,
        pinLength: pin.length,
        kdf: kdf,
        biometric: current?.biometric ?? false,
        timeoutSeconds: current?.timeoutSeconds ?? 0,
      ),
    );
  }

  Future<bool> verify(String pin) async {
    final c = await read();
    if (c == null) return true;
    final candidate = _hash(pin, c.salt, c.kdf);
    // Constant time: the comparison does not stop at the first difference.
    var diff = candidate.length ^ c.hash.length;
    for (var i = 0; i < candidate.length && i < c.hash.length; i++) {
      diff |= candidate[i] ^ c.hash[i];
    }
    return diff == 0;
  }

  Future<void> update(AppLockConfig Function(AppLockConfig) change) async {
    final c = await read();
    if (c != null) await _write(change(c));
  }

  Future<void> disable() => _write(null);
}

/// Fingerprint / face unlock, behind an interface so tests can fake it.
abstract interface class BiometricAuth {
  Future<bool> available();
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuth implements BiometricAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on Exception {
      return false; // falls back to the PIN pad
    }
  }
}
