import 'dart:convert';

import 'package:cashrotate/data/sync/sync_crypto.dart';
import 'package:cashrotate_sync/cashrotate_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sodium/sodium_sumo.dart';

void main() {
  late SodiumSumo sodium;
  // Cheap Argon2id for tests; the app uses KdfParams.standard.
  const fast = KdfParams(opsLimit: 1, memLimit: 8 << 20);

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  group('file encryption', () {
    late SodiumCipher cipher;
    setUp(() => cipher = SodiumCipher(sodium, SyncKeys(sodium).newDataKey()));

    test('round trip, "CRS1" header, a fresh nonce every time', () {
      final plain = utf8.encode('{"changes":[]}');
      final a = cipher.seal('devices/x/1.chg', plain);
      final b = cipher.seal('devices/x/1.chg', plain);
      expect(ascii.decode(a.sublist(0, 4)), 'CRS1');
      expect(a, isNot(b));
      expect(cipher.open('devices/x/1.chg', a), plain);
    });

    test('compresses before encrypting', () {
      final plain = utf8.encode(
        jsonEncode([
          for (var i = 0; i < 500; i++) {'field': 'name', 'v': i},
        ]),
      );
      expect(cipher.seal('p', plain).length, lessThan(plain.length ~/ 4));
    });

    test('another path, a changed byte or another key does not open', () {
      final sealed = cipher.seal('devices/x/1.chg', [1, 2, 3]);
      expect(
        () => cipher.open('devices/x/2.chg', sealed),
        throwsA(isA<SyncCipherException>()),
      );
      final tampered = [...sealed]..[sealed.length - 1] ^= 1;
      expect(
        () => cipher.open('devices/x/1.chg', tampered),
        throwsA(isA<SyncCipherException>()),
      );
      final other = SodiumCipher(sodium, SyncKeys(sodium).newDataKey());
      expect(
        () => other.open('devices/x/1.chg', sealed),
        throwsA(isA<SyncCipherException>()),
      );
      expect(
        () => cipher.open('x', utf8.encode('not ours')),
        throwsA(isA<SyncCipherException>()),
      );
    });
  });

  group('recovery codes', () {
    test('generated: 32 Crockford characters in 8 groups', () {
      final code = SyncKeys(sodium).generateRecoveryCode();
      expect(
        code,
        matches(RegExp(r'^([0-9A-HJKMNP-TV-Z]{4}-){7}[0-9A-HJKMNP-TV-Z]{4}$')),
      );
    });

    test('a generated code tolerates case, spacing and look-alikes', () {
      const code = 'K7Q2-M9XA-T4WP-HC3N-R8DZ-6YVB-J2EF-5GS0';
      final canonical = SyncKeys.normalizeRecoveryCode(code);
      expect(
        SyncKeys.normalizeRecoveryCode(
          'k7q2 m9xa t4wp hc3n r8dz 6yvb j2ef 5gso',
        ),
        canonical,
      );
      expect(canonical, isNot(contains('-')));
    });

    test('a code of the user\'s own is used exactly and must be strong', () {
      expect(
        SyncKeys.normalizeRecoveryCode('  My Bitwarden Pass!  '),
        'My Bitwarden Pass!',
      );
      expect(SyncKeys.strength('short'), RecoveryStrength.tooShort);
      expect(SyncKeys.strength('aaaaaaaaaaaaaaaaaaaa'), RecoveryStrength.weak);
      expect(SyncKeys.strength('correcthorsebattery'), RecoveryStrength.weak);
      expect(SyncKeys.strength('password12345678'), RecoveryStrength.weak);
      // Password-manager passphrases and random passwords pass.
      expect(
        SyncKeys.strength('correct-horse-battery-staple'),
        RecoveryStrength.ok,
      );
      expect(SyncKeys.strength('gT7#qL2v!Wm9@zR4xK8&'), RecoveryStrength.ok);
    });
  });

  group('setting up a folder', () {
    late MemoryFolder remote;
    late SyncKeys keys;
    setUp(() {
      remote = MemoryFolder();
      keys = SyncKeys(sodium, kdf: fast);
    });

    Future<SecureKey> create() => SyncSetup(keys, remote).create(
      password: 'pw-1',
      recoveryCode: 'gT7#qL2v!Wm9@zR4xK8&',
      deviceId: 'a',
      deviceName: 'Pixel',
    );

    test(
      'a second device joins with the password; a wrong one fails',
      () async {
        final key = await create();
        final joined = await SyncSetup(
          keys,
          remote,
        ).join(password: 'pw-1', deviceId: 'b', deviceName: 'Tablet');
        expect(joined.extractBytes(), key.extractBytes());
        final manifest = (await SyncSetup(keys, remote).readManifest())!;
        expect(manifest.devices.map((d) => d['name']), ['Pixel', 'Tablet']);
        await expectLater(
          SyncSetup(
            keys,
            remote,
          ).join(password: 'nope', deviceId: 'c', deviceName: 'x'),
          throwsA(isA<SyncCipherException>()),
        );
        await expectLater(create(), throwsStateError, reason: 'already set up');
      },
    );

    test('the manifest never holds the key in the clear', () async {
      final key = await create();
      final manifest = utf8.decode(remote.files[SyncManifest.path]!);
      expect(manifest, isNot(contains(base64.encode(key.extractBytes()))));
      expect(manifest, contains('argon2id13'));
    });

    test('the recovery code unlocks and sets a new password', () async {
      final key = await create();
      final recovered = await SyncSetup(
        keys,
        remote,
      ).recover(recoveryCode: 'gT7#qL2v!Wm9@zR4xK8&', newPassword: 'pw-2');
      expect(recovered.extractBytes(), key.extractBytes());
      await expectLater(
        SyncSetup(
          keys,
          remote,
        ).join(password: 'pw-1', deviceId: 'b', deviceName: 'x'),
        throwsA(isA<SyncCipherException>()),
      );
      final again = await SyncSetup(
        keys,
        remote,
      ).join(password: 'pw-2', deviceId: 'b', deviceName: 'x');
      expect(again.extractBytes(), key.extractBytes());
    });
  });

  test('standard Argon2id cost (64 MiB, 3 passes) runs on this machine', () {
    final keys = SyncKeys(sodium);
    final watch = Stopwatch()..start();
    keys.derive('password', keys.newSalt(), KdfParams.standard);
    // Desktop CI is fast; phones are measured before release (ADR 0009).
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
  });
}
