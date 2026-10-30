import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  group('defaultAutoRateCurrencies (free tier, applied from M7)', () {
    test('local, USD, EUR, JPY without the main currency, topped up to 4', () {
      expect(defaultAutoRateCurrencies(main: Currency.twd, region: 'TW'), [
        Currency.usd,
        Currency.eur,
        Currency.jpy,
        Currency.cny,
      ]);
      expect(defaultAutoRateCurrencies(main: Currency.usd, region: 'US'), [
        Currency.eur,
        Currency.jpy,
        Currency.cny,
        Currency.hkd,
      ]);
    });

    test('a main currency different from the region keeps the local one', () {
      expect(defaultAutoRateCurrencies(main: Currency.usd, region: 'HK'), [
        Currency.hkd,
        Currency.eur,
        Currency.jpy,
        Currency.cny,
      ]);
    });
  });

  group('parseErApi', () {
    const body = '''
{"result":"success","base_code":"TWD","time_last_update_unix":1761696000,
 "rates":{"TWD":1,"USD":0.03068,"JPY":4.6812,"IDR":512.3,"GBP":0.0231,"VND":8.1e2,"XAU":0.00001}}''';

    test(
      'keeps supported currencies as exact decimals with the update date',
      () {
        final r = parseErApi(body, Currency.twd);
        expect(r.source, erApiSource);
        expect(r.asOf, LocalDate(2025, 10, 29));
        expect(r.rates[Currency.usd]!.toDecimalString(), '0.03068');
        expect(r.rates[Currency.jpy]!.toDecimalString(), '4.6812');
        expect(r.rates[Currency.vnd]!.toDecimalString(), '810');
        expect(
          r.rates.containsKey(Currency.twd),
          isFalse,
          reason: 'base itself',
        );
        expect(
          r.rates.keys.map((c) => c.code),
          isNot(contains('GBP')),
          reason: 'not supported',
        );
      },
    );

    test('rejects errors and a different base', () {
      expect(
        () => parseErApi(
          '{"result":"error","error-type":"unsupported-code"}',
          Currency.twd,
        ),
        throwsFormatException,
      );
      expect(() => parseErApi(body, Currency.usd), throwsFormatException);
      expect(() => parseErApi('not json', Currency.twd), throwsFormatException);
    });
  });

  group('parseFawaz', () {
    const body =
        '{"date":"2026-10-29","twd":{"usd":0.0307,"jpy":4.68,"eur":0.0281,"btc":4e-7}}';

    test('reads lowercase codes and the date', () {
      final r = parseFawaz(body, Currency.twd);
      expect(r.source, fawazSource);
      expect(r.asOf, LocalDate(2026, 10, 29));
      expect(r.rates[Currency.eur]!.toDecimalString(), '0.0281');
      expect(r.rates.keys.map((c) => c.code), isNot(contains('BTC')));
    });

    test('rejects an unexpected payload', () {
      expect(
        () => parseFawaz('{"date":"2026-10-29"}', Currency.twd),
        throwsFormatException,
      );
    });
  });

  test('ratioFromDouble avoids exponent notation', () {
    expect(
      ratioFromDouble(1.5e-5)!.toDecimalString(maxDecimals: 8),
      '0.000015',
    );
    expect(ratioFromDouble(32.59)!.toDecimalString(), '32.59');
    expect(ratioFromDouble(0), isNull);
  });

  test('entitlements: free has no Pro features, Pro has all', () {
    expect(Entitlements.free.has(ProFeature.autoRatesAllCurrencies), isFalse);
    expect(Entitlements.pro.has(ProFeature.autoRatesAllCurrencies), isTrue);
  });
}
