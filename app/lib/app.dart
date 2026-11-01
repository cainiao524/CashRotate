import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'data/providers.dart';
import 'features/reminders/reminder_bridge.dart';
import 'features/sync/sync_bridge.dart';
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
    final language = ref.watch(appDatabaseProvider).hasValue
        ? ref.watch(userSettingsProvider).value?.language
        : null;
    return MaterialApp.router(
      onGenerateTitle: (_) => Brand.appName,
      restorationScopeId: 'app',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Palette.light),
      darkTheme: buildTheme(Palette.dark),
      locale: _localeFor(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveAppLocale,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _StartupGate(child: child!),
    );
  }

  /// A language picked in settings keeps the system's region for formatting.
  static Locale? _localeFor(String? language) {
    if (language == null) return null;
    final region =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    return switch (language) {
      'zh-Hant' => Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: region,
      ),
      'zh-Hans' => Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
        countryCode: region,
      ),
      _ => Locale.fromSubtags(languageCode: 'en', countryCode: region),
    };
  }
}

/// Holds the UI back until the encrypted database and settings are loaded,
/// and explains instead of crashing when the database cannot be opened.
/// First-launch setup is a route (the router redirects to it), so it has a
/// Navigator and Overlay for dialogs, pickers and tooltips.
class _StartupGate extends ConsumerWidget {
  const _StartupGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(appDatabaseProvider)) {
      case AsyncError(:final error):
        return Scaffold(
          body: ErrorState(
            title: AppLocalizations.of(context).databaseOpenFailed,
            message: '$error',
            onRetry: () => ref.invalidate(appDatabaseProvider),
          ),
        );
      case AsyncData():
        break;
      default:
        return const Scaffold(body: SizedBox.expand());
    }
    // Today's exchange rates, in the background (once a day; offline keeps
    // the cached ones).
    ref.watch(autoRateStartupProvider);
    return switch (ref.watch(userSettingsProvider)) {
      AsyncData() => SyncBridge(child: ReminderBridge(child: child)),
      AsyncError(:final error) => Scaffold(body: ErrorState(message: '$error')),
      _ => const Scaffold(body: SizedBox.expand()),
    };
  }
}
