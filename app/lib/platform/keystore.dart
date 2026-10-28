import 'package:flutter/services.dart';

/// Supplies the 32-byte local database key.
abstract interface class DatabaseKeySource {
  /// The key as 64 lowercase hex characters.
  Future<String> databaseKeyHex();
}

/// Key kept by Android Keystore (see DatabaseKeyStore.kt).
class AndroidKeystoreKeySource implements DatabaseKeySource {
  const AndroidKeystoreKeySource();

  static const _channel = MethodChannel('app.cashrotate/keystore');

  @override
  Future<String> databaseKeyHex() async {
    final bytes = await _channel.invokeMethod<Uint8List>('databaseKey');
    if (bytes == null || bytes.length != 32) {
      throw StateError('Keystore returned an invalid database key');
    }
    return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  }
}
