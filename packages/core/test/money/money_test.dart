import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  group('Currency', () {
    test('has exactly the 41 supported currencies, no KPW', () {
      expect(Currency.all, hasLength(41));
      expect(Currency.all.map((c) => c.code).toSet(), hasLength(41));
      expect(Currency.tryParse('KPW'), isNull);
    });

    test('ISO 4217 minor units', () {
      const zeroDecimal = {'JPY', 'KRW', 'VND', 'VUV', 'XPF'};
      for (final c in Currency.all) {
        expect(
          c.minorUnits,
          zeroDecimal.contains(c.code) ? 0 : 2,
          reason: c.code,
        );
      }
      expect(Currency.usd.minorPerMajor, 100);
      expect(Currency.jpy.minorPerMajor, 1);
    });

    test('currencies shown as whole numbers by default', () {
      const wholeByDefault = {
        'TWD', 'IDR', 'KHR', 'LAK', 'MMK', 'MNT', 'UZS', //
        'JPY', 'KRW', 'VND', 'VUV', 'XPF',
      };
      for (final c in Currency.all) {
        expect(
          c.defaultDisplayDecimals,
          wholeByDefault.contains(c.code) ? 0 : 2,
          reason: c.code,
        );
      }
    });

    test('parse is case-insensitive and rejects unknown codes', () {
      expect(Currency.parse('twd'), Currency.twd);
      expect(() => Currency.parse('XXX'), throwsArgumentError);
    });
  });

  group('Money', () {
    test('same-currency arithmetic', () {
      const a = Money(1999, Currency.usd);
      expect(a + const Money(1, Currency.usd), const Money(2000, Currency.usd));
      expect(a - a, const Money.zero(Currency.usd));
      expect(a.times(3), const Money(5997, Currency.usd));
      expect(-a, const Money(-1999, Currency.usd));
      expect(a > const Money(1000, Currency.usd), isTrue);
    });

    test('refuses to mix currencies', () {
      expect(
        () => const Money(1, Currency.usd) + const Money(1, Currency.twd),
        throwsArgumentError,
      );
      expect(
        () => const Money(
          1,
          Currency.usd,
        ).compareTo(const Money(1, Currency.eur)),
        throwsArgumentError,
      );
    });
  });

  group('divideRoundHalfEven', () {
    test('rounds to nearest, ties to even', () {
      expect(divideRoundHalfEven(10, 4), 2); // 2.5 → 2
      expect(divideRoundHalfEven(14, 4), 4); // 3.5 → 4
      expect(divideRoundHalfEven(11, 4), 3); // 2.75
      expect(divideRoundHalfEven(9, 4), 2); // 2.25
      expect(divideRoundHalfEven(12, 4), 3);
    });

    test('negative values are symmetric', () {
      expect(divideRoundHalfEven(-10, 4), -2);
      expect(divideRoundHalfEven(-14, 4), -4);
      expect(divideRoundHalfEven(-11, 4), -3);
      expect(divideRoundHalfEven(10, -4), -2);
    });

    test('rejects division by zero', () {
      expect(() => divideRoundHalfEven(1, 0), throwsArgumentError);
    });
  });
}
