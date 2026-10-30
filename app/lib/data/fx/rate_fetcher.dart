import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';

/// Downloads public exchange rates for one base currency.
///
/// Primary source: ExchangeRate-API's open endpoint (open.er-api.com, shown
/// as attribution in the app). Fallback: fawazahmed0's currency-api, from
/// jsDelivr and then its Cloudflare mirror. Only the base currency code is
/// sent; no user data leaves the phone.
class RateFetcher {
  RateFetcher({Future<String> Function(Uri uri)? get}) : _get = get ?? _httpGet;

  final Future<String> Function(Uri uri) _get;

  static Uri erApi(Currency base) =>
      Uri.parse('https://open.er-api.com/v6/latest/${base.code}');
  static List<Uri> fawaz(Currency base) => [
    Uri.parse(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/${base.code.toLowerCase()}.json',
    ),
    Uri.parse(
      'https://latest.currency-api.pages.dev/v1/currencies/${base.code.toLowerCase()}.json',
    ),
  ];

  /// First source that answers wins. Throws [RateFetchException] listing
  /// every failure when none does.
  Future<FetchedRates> fetch(Currency base) async {
    final errors = <String>[];
    try {
      return parseErApi(await _get(erApi(base)), base);
    } on Object catch (e) {
      errors.add('${erApi(base).host}: $e');
    }
    for (final uri in fawaz(base)) {
      try {
        return parseFawaz(await _get(uri), base);
      } on Object catch (e) {
        errors.add('${uri.host}: $e');
      }
    }
    throw RateFetchException(errors);
  }

  static Future<String> _httpGet(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }
}

class RateFetchException implements Exception {
  RateFetchException(this.errors);
  final List<String> errors;

  @override
  String toString() => 'RateFetchException: ${errors.join('; ')}';
}
