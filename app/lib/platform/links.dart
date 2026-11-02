import 'package:flutter/services.dart';

/// Opens web pages in the browser (a service's cancel page). Behind an
/// interface so tests can fake it.
abstract interface class LinkOpener {
  /// False when the link is not a web link or nothing can open it.
  Future<bool> open(String url);
}

class SystemLinkOpener implements LinkOpener {
  static const _channel = MethodChannel('app.cashrotate/links');

  @override
  Future<bool> open(String url) async =>
      await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
}
