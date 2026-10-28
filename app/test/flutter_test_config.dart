import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Applies to every test under app/test.
///
/// Loads Roboto and Material Icons from the Flutter SDK so goldens show real
/// glyph widths instead of the default box font, and swaps in a comparator
/// that tolerates the tiny anti-aliasing differences between Windows and Linux.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await _loadSdkFonts();
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('_'));
  }
  await testMain();
}

/// Pixel share that may differ before a golden fails.
const _goldenTolerance = 0.005;

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    try {
      if (result.passed || result.diffPercent <= _goldenTolerance) return true;
      throw FlutterError(await generateFailureOutput(result, golden, basedir));
    } finally {
      result.dispose();
    }
  }
}

/// Goldens are drawn with these fonts, so a missing one is a setup error, not
/// something to paper over: the images would silently stop matching.
Future<void> _loadSdkFonts() async {
  final fontsDir = _findMaterialFontsDir();
  // File names differ in case between platforms' font archives.
  final files = {
    for (final f in fontsDir?.listSync().whereType<File>() ?? <File>[])
      f.uri.pathSegments.last.toLowerCase(): f,
  };
  Future<void> load(String family, List<String> names) async {
    final loader = FontLoader(family);
    for (final name in names) {
      final file = files[name];
      if (file == null) {
        throw StateError(
          'Material font "$name" not found in ${fontsDir?.path ?? 'the Flutter '
                  'cache'}. Run `flutter precache --universal` first.',
        );
      }
      loader.addFont(
        Future.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

/// `<flutter>/bin/cache/artifacts/material_fonts`, found by walking up from
/// the test runner binary, which lives inside the same cache.
Directory? _findMaterialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (true) {
    final candidate = Directory('${dir.path}/material_fonts');
    if (candidate.existsSync()) return candidate;
    final artifacts = Directory('${dir.path}/artifacts/material_fonts');
    if (artifacts.existsSync()) return artifacts;
    if (dir.parent.path == dir.path) return null;
    dir = dir.parent;
  }
}
