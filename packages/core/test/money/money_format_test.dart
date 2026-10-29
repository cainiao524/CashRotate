import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:test/test.dart';

Money m(int minor, Currency c) => Money(minor, c);

void main() {
  setUpAll(initializeDateFormatting);

  group('formatMoney', () {
    test('ambiguous symbols always carry their prefix', () {
      expect(formatMoney(m(39000, Currency.twd), locale: 'zh_TW'), r'NT$390');
      expect(formatMoney(m(2000, Currency.usd), locale: 'en_US'), r'US$20.00');
      expect(formatMoney(m(1000, Currency.jpy), locale: 'ja_JP'), 'JP¥1,000');
      expect(formatMoney(m(6800, Currency.cny), locale: 'zh_CN'), 'CN¥68.00');
      expect(formatMoney(m(7800, Currency.hkd), locale: 'zh_HK'), r'HK$78.00');
    });

    test('shared symbols fall back to the ISO code with a space', () {
      expect(
        formatMoney(m(150000, Currency.lkr), locale: 'en'),
        'LKR 1,500.00',
      );
      expect(formatMoney(m(500000, Currency.mmk), locale: 'en'), 'MMK 5,000');
    });

    test(
      'whole-number currencies drop cents by default; can be overridden',
      () {
        expect(formatMoney(m(65249, Currency.twd), locale: 'zh_TW'), r'NT$652');
        expect(
          formatMoney(m(65250, Currency.twd), locale: 'zh_TW'),
          r'NT$652',
          reason: 'half-even',
        );
        expect(
          formatMoney(m(65350, Currency.twd), locale: 'zh_TW'),
          r'NT$654',
          reason: 'half-even',
        );
        expect(
          formatMoney(m(65249, Currency.twd), locale: 'zh_TW', decimals: 2),
          r'NT$652.49',
        );
        expect(
          formatMoney(m(1234567800, Currency.idr), locale: 'id'),
          contains('12.345.678'),
        );
      },
    );

    test('locale decides grouping and decimal marks', () {
      expect(
        formatMoney(m(123456, Currency.eur), locale: 'de'),
        contains('1.234,56'),
      );
      expect(
        formatMoney(m(123456, Currency.eur), locale: 'en'),
        contains('1,234.56'),
      );
    });

    test('negative amounts', () {
      expect(
        formatMoney(m(-2000, Currency.usd), locale: 'en_US'),
        contains('20.00'),
      );
      expect(
        formatMoney(m(-2000, Currency.usd), locale: 'en_US'),
        startsWith('-'),
      );
    });

    test('formatAmount has no symbol', () {
      expect(formatAmount(m(123456, Currency.usd), locale: 'en'), '1,234.56');
      expect(formatAmount(m(1000, Currency.jpy), locale: 'en'), '1,000');
    });
  });

  group('parseMoney', () {
    test('plain and decimal input', () {
      expect(parseMoney('20', Currency.usd), m(2000, Currency.usd));
      expect(parseMoney('19.99', Currency.usd), m(1999, Currency.usd));
      expect(parseMoney('19.9', Currency.usd), m(1990, Currency.usd));
      expect(parseMoney(' 1,234.50 ', Currency.usd), m(123450, Currency.usd));
      expect(parseMoney('1.234,50', Currency.eur), m(123450, Currency.eur));
      expect(parseMoney('9,99', Currency.eur), m(999, Currency.eur));
      expect(parseMoney('1 234,5', Currency.eur), m(123450, Currency.eur));
    });

    test('a three-digit tail after a lone separator', () {
      expect(parseMoney('1,000', Currency.jpy), m(1000, Currency.jpy));
      expect(
        parseMoney('1,000', Currency.usd),
        m(100000, Currency.usd),
        reason: 'grouping',
      );
      expect(parseMoney('1,000,000', Currency.usd), m(100000000, Currency.usd));
      expect(parseMoney('1.5', Currency.usd), m(150, Currency.usd));
    });

    test('rejects what cannot be an amount', () {
      for (final bad in ['', '  ', 'abc', '-5', '1.2.3x', '20.001']) {
        expect(parseMoney(bad, Currency.usd), isNull, reason: bad);
      }
      expect(
        parseMoney('100.5', Currency.jpy),
        isNull,
        reason: 'JPY has no minor unit',
      );
    });
  });

  group('resolveCurrencySymbol', () {
    test('unambiguous symbols, codes and words', () {
      expect(resolveCurrencySymbol(r'NT$'), Currency.twd);
      expect(resolveCurrencySymbol('JP¥'), Currency.jpy);
      expect(resolveCurrencySymbol('€'), Currency.eur);
      expect(resolveCurrencySymbol('usd'), Currency.usd);
      expect(resolveCurrencySymbol('刀'), Currency.usd);
      expect(resolveCurrencySymbol('日圓'), Currency.jpy);
      expect(resolveCurrencySymbol('蚊'), Currency.hkd);
    });

    test(r'¥ and $ follow the preset first, then the region', () {
      expect(
        resolveCurrencySymbol('¥', presetCurrency: Currency.jpy),
        Currency.jpy,
      );
      expect(resolveCurrencySymbol('¥', region: 'CN'), Currency.cny);
      expect(resolveCurrencySymbol('¥', region: 'JP'), Currency.jpy);
      expect(resolveCurrencySymbol(r'$', region: 'TW'), Currency.twd);
      expect(resolveCurrencySymbol(r'$', region: 'HK'), Currency.hkd);
      expect(
        resolveCurrencySymbol(r'$', region: 'HK', presetCurrency: Currency.usd),
        Currency.usd,
      );
      expect(resolveCurrencySymbol('元', region: 'TW'), Currency.twd);
    });

    test('unresolvable shared symbols return null so the app asks', () {
      expect(resolveCurrencySymbol('¥'), isNull);
      expect(resolveCurrencySymbol('¥', region: 'TW'), isNull);
      expect(resolveCurrencySymbol(r'$', region: 'DE'), isNull);
      expect(resolveCurrencySymbol('Rs'), isNull);
      expect(resolveCurrencySymbol('zzz'), isNull);
    });
  });

  group('CurrencyInfo', () {
    test('covers every supported currency', () {
      expect(CurrencyInfo.all.map((i) => i.currency), Currency.all);
    });

    test('default currency from region', () {
      expect(CurrencyInfo.forRegion('TW'), Currency.twd);
      expect(CurrencyInfo.forRegion('hk'), Currency.hkd);
      expect(CurrencyInfo.forRegion('DE'), Currency.eur);
      expect(CurrencyInfo.forRegion('BR'), Currency.usd);
      expect(CurrencyInfo.forRegion(null), Currency.usd);
    });

    test('search by code, name, country and symbol', () {
      expect(CurrencyInfo.search('jpy').first.currency, Currency.jpy);
      expect(CurrencyInfo.search('日圓').first.currency, Currency.jpy);
      expect(CurrencyInfo.search('香港').first.currency, Currency.hkd);
      expect(CurrencyInfo.search('korea').first.currency, Currency.krw);
      expect(CurrencyInfo.search(r'NT$').first.currency, Currency.twd);
      expect(
        CurrencyInfo.search('rupee').map((i) => i.currency),
        containsAll([Currency.inr, Currency.pkr, Currency.lkr, Currency.npr]),
      );
      expect(CurrencyInfo.search(''), hasLength(41));
    });
  });
}
