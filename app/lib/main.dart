import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  // The bundled Manrope font's licence, shown on the licences page.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/Manrope-OFL.txt'));
  });
  runApp(const ProviderScope(child: CashRotateApp()));
}
