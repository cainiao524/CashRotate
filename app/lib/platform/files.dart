import 'package:flutter/services.dart';

/// The system file picker, for exported backups. Behind an interface so
/// tests can fake it.
abstract interface class FilePicker {
  /// Lets the user choose where to save [bytes]. False when cancelled.
  Future<bool> save(String name, Uint8List bytes);

  /// Lets the user pick a file to read. Null when cancelled.
  Future<Uint8List?> open();
}

class SystemFilePicker implements FilePicker {
  static const _channel = MethodChannel('app.cashrotate/files');

  @override
  Future<bool> save(String name, Uint8List bytes) async =>
      await _channel.invokeMethod<bool>('saveFile', {
        'name': name,
        'bytes': bytes,
      }) ??
      false;

  @override
  Future<Uint8List?> open() => _channel.invokeMethod<Uint8List>('openFile');
}
