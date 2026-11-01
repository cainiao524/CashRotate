import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

/// Seals files before they leave the phone and opens them after download.
///
/// [path] (the file's place in the sync folder) is bound to the result as
/// additional authenticated data: a file moved or renamed on the server no
/// longer opens. Implementations compress before encrypting (ADR 0009).
abstract interface class SyncCipher {
  Uint8List seal(String path, List<int> plain);

  /// Throws [SyncCipherException] when the file was not sealed with this key
  /// for this path, or was changed.
  Uint8List open(String path, List<int> sealed);
}

class SyncCipherException implements Exception {
  const SyncCipherException(this.message);
  final String message;

  @override
  String toString() => 'SyncCipherException: $message';
}

/// Not encryption: gzip plus a path check, for tests of the protocol and
/// merging. Never used with a real server.
class TestCipher implements SyncCipher {
  const TestCipher([this.keyTag = 'test']);

  /// Different tags model different keys.
  final String keyTag;

  static const _magic = 'TST1';

  @override
  Uint8List seal(String path, List<int> plain) => Uint8List.fromList([
    ...utf8.encode('$_magic$keyTag|$path|'),
    ...gzip.encode(plain),
  ]);

  @override
  Uint8List open(String path, List<int> sealed) {
    final header = utf8.encode('$_magic$keyTag|$path|');
    if (sealed.length < header.length || !_startsWith(sealed, header)) {
      throw const SyncCipherException('wrong key or path');
    }
    return Uint8List.fromList(gzip.decode(sealed.sublist(header.length)));
  }

  static bool _startsWith(List<int> a, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (a[i] != prefix[i]) return false;
    }
    return true;
  }
}
