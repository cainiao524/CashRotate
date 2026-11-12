import 'package:flutter/services.dart';

/// How the phone is tilted, for the pearl sheen: x and y of gravity in the
/// screen's plane, each from -1 to 1 (0, 0 = lying flat). Behind an
/// interface so tests can fake it.
abstract interface class TiltSource {
  /// Starts the sensor on listen and stops it on cancel.
  Stream<Offset> get tilt;
}

class SystemTiltSource implements TiltSource {
  static const _channel = EventChannel('app.cashrotate/tilt');

  @override
  Stream<Offset> get tilt => _channel.receiveBroadcastStream().map((event) {
    final xy = (event as List).cast<num>();
    return Offset(xy[0].toDouble(), xy[1].toDouble());
  });
}

/// No sensor (tests, or a phone without one): the sheen stays still.
class NoTilt implements TiltSource {
  const NoTilt();

  @override
  Stream<Offset> get tilt => const Stream.empty();
}
