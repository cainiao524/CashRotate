import 'dart:ui';

/// Regions whose Chinese is written in Traditional script when the system
/// locale carries no script subtag (e.g. `zh_TW` rather than `zh_Hant_TW`).
const _traditionalChineseRegions = {'TW', 'HK', 'MO'};

/// Picks the app locale for the user's preferred system locales.
///
/// Flutter's default matching treats a bare `zh_TW` as plain `zh`, which is
/// our Simplified fallback; this maps it to Traditional instead. The country
/// code is kept so regional formatting (dates, week start, currency) follows
/// the system region rather than the translation's.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    final match = _match(locale, supported);
    if (match != null) return match;
  }
  return supported.first;
}

Locale? _match(Locale locale, Iterable<Locale> supported) {
  switch (locale.languageCode) {
    case 'zh':
      final script =
          locale.scriptCode ??
          (_traditionalChineseRegions.contains(locale.countryCode)
              ? 'Hant'
              : 'Hans');
      return Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: script,
        countryCode: locale.countryCode,
      );
    case final language when supported.any((s) => s.languageCode == language):
      return Locale.fromSubtags(
        languageCode: language,
        countryCode: locale.countryCode,
      );
    default:
      return null;
  }
}
