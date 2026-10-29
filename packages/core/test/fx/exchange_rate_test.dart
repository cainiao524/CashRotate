import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

ExchangeRate rate(
  Currency base,
  Currency quote,
  String r, [
  String asOf = '2026-10-27',
]) => ExchangeRate(
  base: base,
  quote: quote,
  rate: Ratio.tryParse(r)!,
  asOf: d(asOf),
  source: 'manual',
);

void main() {
  group('Ratio', () {
    test('parses decimals exactly and prints them back', () {
      expect(Ratio.tryParse('32.59')!.toDecimalString(), '32.59');
      expect(Ratio.tryParse('0.000213')!.toDecimalString(), '0.000213');
      expect(Ratio.tryParse('100')!.toDecimalString(), '100');
      expect(Ratio.tryParse('1.50'), Ratio.tryParse('1.5'));
    });

    test('rejects zero, negatives and junk', () {
      for (final bad in ['0', '0.00', '-1', 'abc', '1e5', '']) {
        expect(Ratio.tryParse(bad), isNull, reason: bad);
      }
    });

    test('inverse rounds only when printed', () {
      expect(
        Ratio.tryParse('32')!.inverse.toDecimalString(maxDecimals: 6),
        '0.03125',
      );
      expect(
        Ratio.tryParse('3')!.inverse.toDecimalString(maxDecimals: 4),
        '0.3333',
      );
    });
  });

  group('FxConverter', () {
    final fx = FxConverter([
      rate(Currency.usd, Currency.twd, '32.59'),
      rate(Currency.usd, Currency.jpy, '152.3', '2026-10-25'),
    ]);

    test('US\$20 → NT\$651.80 (the example in the requirements)', () {
      final c = fx.convert(const Money(2000, Currency.usd), Currency.twd)!;
      expect(c.amount, const Money(65180, Currency.twd));
      expect(c.rate.toDecimalString(), '32.59');
      expect(c.asOf, d('2026-10-27'));
      expect(formatMoney(c.amount, locale: 'zh_TW'), r'NT$652');
    });

    test('inverse direction', () {
      final c = fx.convert(const Money(65180, Currency.twd), Currency.usd)!;
      expect(c.amount, const Money(2000, Currency.usd));
    });

    test('zero-decimal currencies scale correctly', () {
      // ¥1000 → USD 6.5660... → US$6.57 → NT$
      final c = fx.convert(const Money(1000, Currency.jpy), Currency.usd)!;
      expect(c.amount, const Money(657, Currency.usd));
    });

    test('chains through a shared currency and reports the older date', () {
      final c = fx.convert(const Money(1000, Currency.jpy), Currency.twd)!;
      // 1000 / 152.3 × 32.59 = 213.9855…
      expect(c.amount, const Money(21399, Currency.twd));
      expect(c.asOf, d('2026-10-25'));
    });

    test('adds the card foreign transaction fee', () {
      final c = fx.convert(
        const Money(2000, Currency.usd),
        Currency.twd,
        feeBasisPoints: 150,
      )!;
      // 651.80 × 1.015 = 661.577 → 661.58
      expect(c.amount, const Money(66158, Currency.twd));
    });

    test('unknown pairs return null; same currency passes through', () {
      expect(fx.convert(const Money(100, Currency.eur), Currency.twd), isNull);
      expect(
        fx.convert(const Money(100, Currency.twd), Currency.twd)!.amount,
        const Money(100, Currency.twd),
      );
    });

    test('rounds half-even at the minor unit', () {
      final half = FxConverter([rate(Currency.usd, Currency.jpy, '150.5')]);
      // US$0.01 → ¥1.505 → ¥2 ; US$0.03 → ¥4.515 → ¥5 ; US$0.02 → ¥3.01 → ¥3
      expect(
        half.convert(const Money(1, Currency.usd), Currency.jpy)!.amount.minor,
        2,
      );
      expect(
        half.convert(const Money(2, Currency.usd), Currency.jpy)!.amount.minor,
        3,
      );
      final tie = FxConverter([rate(Currency.usd, Currency.jpy, '150')]);
      // US$0.01 at 150 → exactly ¥1.5 → ¥2 (even); ¥2.5 → ¥2
      expect(
        tie.convert(const Money(1, Currency.usd), Currency.jpy)!.amount.minor,
        2,
      );
      final tie2 = FxConverter([rate(Currency.usd, Currency.jpy, '250')]);
      expect(
        tie2.convert(const Money(1, Currency.usd), Currency.jpy)!.amount.minor,
        2,
      );
    });
  });
}
