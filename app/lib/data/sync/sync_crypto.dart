import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';
import 'dart:typed_data';

import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:sodium/sodium_sumo.dart';

/// File format (ADR 0009): `"CRS1" ‖ nonce (24) ‖ XChaCha20-Poly1305 of the
/// gzipped content`, with the file's path in the folder as additional data.
class SodiumCipher implements SyncCipher {
  SodiumCipher(this._sodium, this._key);

  final SodiumSumo _sodium;
  final SecureKey _key;

  static final magic = ascii.encode('CRS1');

  @override
  Uint8List seal(String path, List<int> plain) {
    final aead = _sodium.crypto.aeadXChaCha20Poly1305IETF;
    final nonce = _sodium.randombytes.buf(aead.nonceBytes);
    final cipher = aead.encrypt(
      message: Uint8List.fromList(gzip.encode(plain)),
      nonce: nonce,
      key: _key,
      additionalData: Uint8List.fromList(utf8.encode(path)),
    );
    return Uint8List.fromList([...magic, ...nonce, ...cipher]);
  }

  @override
  Uint8List open(String path, List<int> sealed) {
    final aead = _sodium.crypto.aeadXChaCha20Poly1305IETF;
    final head = magic.length + aead.nonceBytes;
    if (sealed.length < head + aead.aBytes ||
        !_equal(sealed.sublist(0, magic.length), magic)) {
      throw const SyncCipherException('not a CashRotate sync file');
    }
    try {
      final plain = aead.decrypt(
        cipherText: Uint8List.fromList(sealed.sublist(head)),
        nonce: Uint8List.fromList(sealed.sublist(magic.length, head)),
        key: _key,
        additionalData: Uint8List.fromList(utf8.encode(path)),
      );
      return Uint8List.fromList(gzip.decode(plain));
    } on SodiumException {
      throw const SyncCipherException('wrong key, wrong path or changed');
    }
  }

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Argon2id cost. ADR 0009: 64 MiB, 3 passes, run once per device.
class KdfParams {
  const KdfParams({required this.opsLimit, required this.memLimit});

  factory KdfParams.fromJson(Map<String, Object?> j) =>
      KdfParams(opsLimit: j['ops']! as int, memLimit: j['mem']! as int);

  static const standard = KdfParams(opsLimit: 3, memLimit: 64 << 20);

  final int opsLimit;
  final int memLimit;

  Map<String, Object?> toJson() => {
    'alg': 'argon2id13',
    'ops': opsLimit,
    'mem': memLimit,
  };
}

/// How strong a user-chosen recovery code is.
enum RecoveryStrength { tooShort, weak, ok }

/// Key derivation, wrapping and recovery codes.
///
/// A random 32-byte data key encrypts every file. It is stored in the
/// folder's manifest only wrapped: once by a key derived from the sync
/// password, once by a key derived from the recovery code. Changing the
/// password rewraps it; nothing in the cloud is re-encrypted.
class SyncKeys {
  SyncKeys(this.sodium, {this.kdf = KdfParams.standard});

  final SodiumSumo sodium;
  final KdfParams kdf;

  static const keyBytes = 32;

  SecureKey newDataKey() => sodium.crypto.aeadXChaCha20Poly1305IETF.keygen();

  Uint8List newSalt() => sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);

  SecureKey derive(String secret, Uint8List salt, KdfParams params) =>
      sodium.crypto.pwhash.callStr(
        outLen: keyBytes,
        password: secret,
        salt: salt,
        opsLimit: params.opsLimit,
        memLimit: params.memLimit,
        alg: CryptoPwhashAlgorithm.argon2id13,
      );

  /// [dataKey] encrypted under [wrapKey]; [purpose] binds it to its slot.
  Map<String, Object?> wrap(
    SecureKey wrapKey,
    SecureKey dataKey,
    String purpose,
  ) {
    final aead = sodium.crypto.aeadXChaCha20Poly1305IETF;
    final nonce = sodium.randombytes.buf(aead.nonceBytes);
    final cipher = aead.encrypt(
      message: dataKey.extractBytes(),
      nonce: nonce,
      key: wrapKey,
      additionalData: Uint8List.fromList(
        utf8.encode('cashrotate-key-v1:$purpose'),
      ),
    );
    return {'nonce': base64.encode(nonce), 'key': base64.encode(cipher)};
  }

  /// Throws [SyncCipherException] for a wrong password or code.
  SecureKey unwrap(
    SecureKey wrapKey,
    Map<String, Object?> wrapped,
    String purpose,
  ) {
    try {
      final bytes = sodium.crypto.aeadXChaCha20Poly1305IETF.decrypt(
        cipherText: base64.decode(wrapped['key']! as String),
        nonce: base64.decode(wrapped['nonce']! as String),
        key: wrapKey,
        additionalData: Uint8List.fromList(
          utf8.encode('cashrotate-key-v1:$purpose'),
        ),
      );
      return SecureKey.fromList(sodium, bytes);
    } on SodiumException {
      throw const SyncCipherException('wrong password or recovery code');
    }
  }

  /// A generated recovery code: 160 random bits as 32 Crockford base32
  /// characters (no I, L, O, U) in groups of four.
  String generateRecoveryCode() {
    final bytes = sodium.randombytes.buf(20);
    var bits = 0;
    var value = 0;
    final out = StringBuffer();
    for (final b in bytes) {
      value = (value << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_crockford[(value >> bits) & 31]);
      }
    }
    final code = out.toString();
    return [for (var i = 0; i < code.length; i += 4) code.substring(i, i + 4)]
        .join('-');
  }

  static const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// The form a recovery code is derived from: a generated code ignores
  /// case, spaces and dashes (and 0/O, 1/I/L confusions); a code of the
  /// user's own (e.g. from a password manager) is used exactly, trimmed.
  static String normalizeRecoveryCode(String input) {
    final compact = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final mapped = compact.replaceAll('O', '0').replaceAll(RegExp('[IL]'), '1');
    if (RegExp(r'^[0-9A-HJKMNP-TV-Z]{32}$').hasMatch(mapped)) return mapped;
    return input.trim();
  }

  /// Rough strength of a user-chosen code: at least 16 characters and about
  /// 100 bits of guessing work (by character classes used and repetition).
  static RecoveryStrength strength(String code) {
    final c = code.trim();
    if (c.length < 16) return RecoveryStrength.tooShort;
    var pool = 0;
    if (RegExp('[a-z]').hasMatch(c)) pool += 26;
    if (RegExp('[A-Z]').hasMatch(c)) pool += 26;
    if (RegExp('[0-9]').hasMatch(c)) pool += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(c)) pool += 33;
    final distinct = c.split('').toSet().length;
    final effective = min(c.length, distinct * 2);
    final bits = effective * (log(max(pool, 2)) / ln2);
    return bits >= 100 ? RecoveryStrength.ok : RecoveryStrength.weak;
  }
}

/// `manifest.json`: format, key derivation parameters, the wrapped data
/// key (by password and by recovery code) and the device list. Never holds
/// a key in the clear.
class SyncManifest {
  SyncManifest({
    required this.kdf,
    required this.passwordSalt,
    required this.passwordWrap,
    required this.recoverySalt,
    required this.recoveryWrap,
    required this.devices,
  });

  factory SyncManifest.decode(List<int> bytes) {
    final j = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (j['format'] != format) {
      throw FormatException('Unsupported sync folder format ${j['format']}');
    }
    final password = (j['password']! as Map).cast<String, Object?>();
    final recovery = (j['recovery']! as Map).cast<String, Object?>();
    return SyncManifest(
      kdf: KdfParams.fromJson((j['kdf']! as Map).cast<String, Object?>()),
      passwordSalt: base64.decode(password['salt']! as String),
      passwordWrap: password,
      recoverySalt: base64.decode(recovery['salt']! as String),
      recoveryWrap: recovery,
      devices: [
        for (final d in j['devices']! as List)
          (d as Map).cast<String, Object?>(),
      ],
    );
  }

  static const format = 1;
  static const path = 'manifest.json';

  final KdfParams kdf;
  final Uint8List passwordSalt;
  final Map<String, Object?> passwordWrap;
  final Uint8List recoverySalt;
  final Map<String, Object?> recoveryWrap;

  /// `{id, name, addedAt}` per device.
  final List<Map<String, Object?>> devices;

  List<int> encode() => utf8.encode(
    const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'kdf': kdf.toJson(),
      'password': {...passwordWrap, 'salt': base64.encode(passwordSalt)},
      'recovery': {...recoveryWrap, 'salt': base64.encode(recoverySalt)},
      'devices': devices,
    }),
  );
}

/// Setting up, joining and recovering a sync folder.
class SyncSetup {
  SyncSetup(this.keys, this.remote, {int Function()? nowMillis})
    : _now = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SyncKeys keys;
  final RemoteFolder remote;
  final int Function() _now;

  Future<SyncManifest?> readManifest() async {
    final bytes = await remote.read(SyncManifest.path);
    return bytes == null ? null : SyncManifest.decode(bytes);
  }

  Future<void> _writeManifest(SyncManifest m) async {
    final temp = '${SyncManifest.path}.tmp-${_now()}';
    await remote.write(temp, m.encode());
    await remote.move(temp, SyncManifest.path);
  }

  /// First device: a new data key, wrapped by [password] and
  /// [recoveryCode]. Fails if the folder already has a manifest.
  Future<SecureKey> create({
    required String password,
    required String recoveryCode,
    required String deviceId,
    required String deviceName,
  }) async {
    if (await readManifest() != null) {
      throw StateError('This folder is already set up; join it instead.');
    }
    final dataKey = keys.newDataKey();
    final pSalt = keys.newSalt();
    final rSalt = keys.newSalt();
    final code = SyncKeys.normalizeRecoveryCode(recoveryCode);
    await _writeManifest(
      SyncManifest(
        kdf: keys.kdf,
        passwordSalt: pSalt,
        passwordWrap: keys.wrap(
          keys.derive(password, pSalt, keys.kdf),
          dataKey,
          'password',
        ),
        recoverySalt: rSalt,
        recoveryWrap: keys.wrap(
          keys.derive(code, rSalt, keys.kdf),
          dataKey,
          'recovery',
        ),
        devices: [
          {'id': deviceId, 'name': deviceName, 'addedAt': _now()},
        ],
      ),
    );
    return dataKey;
  }

  /// Another device: unlocks the data key with [password] and adds itself
  /// to the device list.
  Future<SecureKey> join({
    required String password,
    required String deviceId,
    required String deviceName,
  }) async {
    final m = await readManifest();
    if (m == null) throw StateError('No sync folder here yet.');
    final dataKey = keys.unwrap(
      keys.derive(password, m.passwordSalt, m.kdf),
      m.passwordWrap,
      'password',
    );
    if (!m.devices.any((d) => d['id'] == deviceId)) {
      m.devices.add({'id': deviceId, 'name': deviceName, 'addedAt': _now()});
      await _writeManifest(m);
    }
    return dataKey;
  }

  /// Forgotten password: unlocks with the recovery code and sets
  /// [newPassword]. The recovery code stays valid.
  Future<SecureKey> recover({
    required String recoveryCode,
    required String newPassword,
  }) async {
    final m = await readManifest();
    if (m == null) throw StateError('No sync folder here yet.');
    final dataKey = keys.unwrap(
      keys.derive(
        SyncKeys.normalizeRecoveryCode(recoveryCode),
        m.recoverySalt,
        m.kdf,
      ),
      m.recoveryWrap,
      'recovery',
    );
    final salt = keys.newSalt();
    await _writeManifest(
      SyncManifest(
        kdf: m.kdf,
        passwordSalt: salt,
        passwordWrap: keys.wrap(
          keys.derive(newPassword, salt, m.kdf),
          dataKey,
          'password',
        ),
        recoverySalt: m.recoverySalt,
        recoveryWrap: m.recoveryWrap,
        devices: m.devices,
      ),
    );
    return dataKey;
  }
}
