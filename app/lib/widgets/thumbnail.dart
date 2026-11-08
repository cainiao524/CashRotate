import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Size of a picture used as a tile icon: enough for the largest badge on a
/// dense screen, small enough to sync with the settings.
const thumbnailSize = 128;

/// Crops a picture to its centre square and scales it to [size] pixels, as
/// PNG; null when it cannot be decoded. Decoding is scaled down on the way,
/// so a large photo never sits in memory at full size.
Future<Uint8List?> squareThumbnail(
  Uint8List bytes, {
  int size = thumbnailSize,
}) async {
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        final scale = size / math.min(width, height);
        return scale >= 1
            ? ui.TargetImageSize(width: width, height: height)
            : ui.TargetImageSize(
                width: (width * scale).ceil(),
                height: (height * scale).ceil(),
              );
      },
    );
    final image = (await codec.getNextFrame()).image;
    final side = math.min(image.width, image.height).toDouble();
    final source = Rect.fromLTWH(
      (image.width - side) / 2,
      (image.height - side) / 2,
      side,
      side,
    );
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final square = await recorder.endRecording().toImage(size, size);
    final data = await square.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    square.dispose();
    return data?.buffer.asUint8List();
  } on Object {
    return null;
  }
}
