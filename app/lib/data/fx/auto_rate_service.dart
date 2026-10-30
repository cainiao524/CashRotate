import 'package:cashrotate_core/cashrotate_core.dart';

import '../settings/settings_repository.dart';
import 'exchange_rate_repository.dart';
import 'rate_fetcher.dart';

enum AutoRateStatus { updated, alreadyToday, failed }

typedef AutoRateResult = ({
  AutoRateStatus status,
  LocalDate? asOf,
  String? source,
  Object? error,
});

/// Keeps automatic exchange rates fresh: once a day (or on demand), against
/// the user's main currency.
///
/// With Pro every supported currency is stored; free users get the
/// [Entitlements.freeAutoRateSlots] currencies they chose (defaults from
/// [defaultAutoRateCurrencies]); other currencies stay manual. Failures keep
/// the last cached rates, which still show their date.
class AutoRateService {
  AutoRateService({
    required this.rates,
    required this.settings,
    required this.fetcher,
    required this.entitlements,
    required this.today,
    required this.defaults,
  });

  final ExchangeRateRepository rates;
  final SettingsRepository settings;
  final RateFetcher fetcher;
  final Entitlements entitlements;
  final LocalDate Function() today;
  final UserSettings defaults;

  /// Currencies updated automatically for [settings]; null means all.
  Set<Currency>? autoCurrencies(UserSettings s) {
    if (entitlements.has(ProFeature.autoRatesAllCurrencies)) return null;
    return (s.autoRateCurrencies ??
            defaultAutoRateCurrencies(main: s.mainCurrency, region: s.region))
        .where((c) => c != s.mainCurrency)
        .take(Entitlements.freeAutoRateSlots)
        .toSet();
  }

  /// Downloads today's rates unless already done today ([force] skips that
  /// check). Never throws; the result says what happened.
  Future<AutoRateResult> refresh({bool force = false}) async {
    final day = today();
    if (!force && await rates.lastFetchedOn() == day) {
      return (
        status: AutoRateStatus.alreadyToday,
        asOf: null,
        source: null,
        error: null,
      );
    }
    try {
      final current = await settings.read(defaults);
      final fetched = await fetcher.fetch(current.mainCurrency);
      await rates.setAutoRates(fetched, only: autoCurrencies(current));
      await rates.markFetched(day);
      return (
        status: AutoRateStatus.updated,
        asOf: fetched.asOf,
        source: fetched.source,
        error: null,
      );
    } on Object catch (e) {
      return (
        status: AutoRateStatus.failed,
        asOf: null,
        source: null,
        error: e,
      );
    }
  }
}
