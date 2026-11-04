import 'package:flutter/services.dart';

/// The Android home-screen widgets: the app hands them what to show.
/// Behind an interface so tests can fake it.
abstract interface class HomeWidgetPlatform {
  /// Replaces the widgets' content with [json] and redraws them.
  Future<void> update(String json);
}

class SystemHomeWidgets implements HomeWidgetPlatform {
  static const _channel = MethodChannel('app.cashrotate/widgets');

  @override
  Future<void> update(String json) => _channel.invokeMethod('update', json);
}
