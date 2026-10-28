import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/locale_resolution.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';

class CashRotateApp extends ConsumerWidget {
  const CashRotateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (_) => Brand.appName,
      restorationScopeId: 'app',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Palette.light),
      darkTheme: buildTheme(Palette.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
