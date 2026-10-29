import 'package:material_ui/material_ui.dart';

/// `zh-Hant`, `zh-Hans` or `en`: the key for preset and currency names.
String contentLanguageOf(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode != 'zh') return 'en';
  return locale.scriptCode == 'Hant' ? 'zh-Hant' : 'zh-Hans';
}

/// Locale name for package:intl number and date formatting, e.g. `zh_TW`.
/// The region drives grouping, decimal marks and the first day of the week.
String intlLocaleOf(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
}
