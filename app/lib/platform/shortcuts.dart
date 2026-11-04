import 'dart:async';

import 'package:flutter/services.dart';

/// Launcher shortcuts (long-press the app icon). Behind an interface so
/// tests can fake it.
abstract interface class ShortcutPlatform {
  /// Replaces the app's shortcuts: id → label, in order.
  Future<void> set(Map<String, String> shortcuts);

  /// The shortcut the app was opened from, once.
  Future<String?> takeOpened();

  /// Fires when a shortcut opens the app while it is running.
  Stream<void> get opened;
}

class SystemShortcuts implements ShortcutPlatform {
  SystemShortcuts() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shortcutOpened') _opened.add(null);
    });
  }

  static const _channel = MethodChannel('app.cashrotate/shortcuts');
  final _opened = StreamController<void>.broadcast();

  @override
  Future<void> set(Map<String, String> shortcuts) =>
      _channel.invokeMethod('set', [
        for (final MapEntry(:key, :value) in shortcuts.entries)
          {'id': key, 'label': value},
      ]);

  @override
  Future<String?> takeOpened() => _channel.invokeMethod<String>('takeOpened');

  @override
  Stream<void> get opened => _opened.stream;
}
