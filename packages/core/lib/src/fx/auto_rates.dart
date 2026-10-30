import 'dart:convert';

import 'package:meta/meta.dart';

import '../entitlements/entitlements.dart';
import '../money/currency.dart';
import '../money/currency_info.dart';
import '../time/local_date.dart';
import 'exchange_rate.dart';

/// The free tier's automatic currencies when the user has not chosen any:
/// the same suggestions the currency picker pins (local currency, USD, EUR,
/// JPY), skipping the main currency itself, topped up from common Asian
/// currencies so all slots are useful.
List<Currency> defaultAutoRateCurrencies({
  required Currency main,
  required String region,
}) {
  final preference = [
    CurrencyInfo.forRegion(region),
    Currency.usd,
    Currency.eur,
    Currency.jpy,
    Currency.cny,
    Currency.hkd,
    Currency.twd,
    Currency.krw,
    Currency.sgd,
  ];
  return {
    for (final c in preference)
      if (c != main) c,
  }.take(Entitlements.freeAutoRateSlots).toList();
}

/// Rates fetched for one base currency: "1 base = rate[c] c".
@immutable
final class FetchedRates {
  const FetchedRates({
    required this.base,
    required this.asOf,
    required this.rates,
    required this.source,
  });

  final Currency base;
  final LocalDate asOf;
  final Map<Currency, Ratio> rates;

  /// `open.er-api.com` or `fawazahmed0`.
  final String source;
}

/// Source id for ExchangeRate-API's open endpoint (attribution required).
const erApiSource = 'open.er-api.com';

/// Source id for fawazahmed0's currency-api (fallback).
const fawazSource = 'fawazahmed0';

/// open.er-api.com `/v6/latest/<BASE>` response. Only supported currencies
/// are kept. Throws [FormatException] for an error or unexpected payload.
FetchedRates parseErApi(String body, Currency base) {
  final json = jsonDecode(body);
  if (json is! Map || json['result'] != 'success') {
    throw FormatException(
      'open.er-api.com: ${json is Map ? json['error-type'] : 'bad response'}',
    );
  }
  if (json['base_code'] != base.code) {
    throw FormatException(
      'open.er-api.com: base ${json['base_code']} != ${base.code}',
    );
  }
  final seconds = json['time_last_update_unix'];
  final rates = json['rates'];
  if (seconds is! int || rates is! Map) {
    throw const FormatException('open.er-api.com: missing fields');
  }
  return FetchedRates(
    base: base,
    asOf: LocalDate.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
    ),
    rates: _supported(rates, upperCase: true, base: base),
    source: erApiSource,
  );
}

/// fawazahmed0 currency-api `currencies/<base>.json` response (lowercase
/// codes). Throws [FormatException] for an unexpected payload.
FetchedRates parseFawaz(String body, Currency base) {
  final json = jsonDecode(body);
  final key = base.code.toLowerCase();
  if (json is! Map || json['date'] is! String || json[key] is! Map) {
    throw const FormatException('currency-api: bad response');
  }
  return FetchedRates(
    base: base,
    asOf: LocalDate.parse(json['date'] as String),
    rates: _supported(json[key] as Map, upperCase: false, base: base),
    source: fawazSource,
  );
}

Map<Currency, Ratio> _supported(
  Map<Object?, Object?> raw, {
  required bool upperCase,
  required Currency base,
}) => {
  for (final MapEntry(:key, :value) in raw.entries)
    if (key is String && value is num && value > 0)
      if (Currency.tryParse(upperCase ? key : key.toUpperCase()) case final c?
          when c != base)
        c: ?ratioFromDouble(value),
};

/// A JSON number as an exact decimal ratio, avoiding exponent notation.
/// Keeps up to 12 decimals, which is beyond what the sources publish.
Ratio? ratioFromDouble(num value) {
  var text = value.toString();
  if (text.contains('e') || text.contains('E')) {
    text = value.toStringAsFixed(12).replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  }
  return Ratio.tryParse(text);
}
