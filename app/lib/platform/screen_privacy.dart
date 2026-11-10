import 'package:flutter/services.dart';

/// Keeps the app's content out of the recent-apps list while the app lock
/// is on. Behind an interface so tests can fake it.
///
/// Android 13 and newer only blank the recents thumbnail. Older versions
/// have no such switch, so the window is marked secure there, which also
/// blocks screenshots.
abstract interface class ScreenPrivacy {
  Future<void> setHiddenInRecents({required bool hidden});
}

class SystemScreenPrivacy implements ScreenPrivacy {
  static const _channel = MethodChannel('app.cashrotate/privacy');

  @override
  Future<void> setHiddenInRecents({required bool hidden}) =>
      _channel.invokeMethod('setHiddenInRecents', {'hidden': hidden});
}
