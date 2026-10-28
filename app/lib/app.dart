import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'data/providers.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/locale_resolution.dart';
import 'routing/router.dart';
import 'theme/app_theme.dart';
import 'theme/palette.dart';
import 'widgets/state_views.dart';

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
      builder: (context, child) => _DatabaseGate(child: child!),
    );
  }
}

/// Holds the UI back until the encrypted database is open, and explains
/// instead of crashing when it cannot be opened.
class _DatabaseGate extends ConsumerWidget {
  const _DatabaseGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(appDatabaseProvider)) {
      AsyncData() => child,
      AsyncError(:final error) => Scaffold(
        body: ErrorState(
          title: AppLocalizations.of(context).databaseOpenFailed,
          message: '$error',
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
      ),
      _ => const Scaffold(body: SizedBox.expand()),
    };
  }
}
