import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import '../time/local_date.dart';

/// "1 [base] = [rate] [quote]", kept as an exact decimal (never a double).
@immutable
final class ExchangeRate {
  ExchangeRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.asOf,
    required this.source,
  }) {
    if (rate.numerator <= BigInt.zero) {
      throw ArgumentError.value(rate, 'rate', 'must be positive');
    }
  }

  final Currency base;
  final Currency quote;
  final Ratio rate;

  /// Date the rate applies to, shown as "updated on …".
  final LocalDate asOf;

  /// `manual`, or the provider id once automatic rates arrive (Pro).
  final String source;

  ExchangeRate get inverse => ExchangeRate(
    base: quote,
    quote: base,
    rate: rate.inverse,
    asOf: asOf,
    source: source,
  );
}

/// An exact positive fraction. Parsed from decimal text such as "32.59".
@immutable
final class Ratio {
  Ratio(BigInt numerator, BigInt denominator)
    : this._normalized(numerator, denominator, numerator.gcd(denominator));

  Ratio._normalized(BigInt n, BigInt d, BigInt g)
    : numerator = n ~/ g,
      denominator = d ~/ g {
    if (d == BigInt.zero) throw ArgumentError('denominator is zero');
  }

  static final _decimal = RegExp(r'^(\d+)(?:\.(\d+))?$');

  /// Parses "32.59" or "0.000213". Returns null for anything else.
  static Ratio? tryParse(String text) {
    final m = _decimal.firstMatch(text.trim());
    if (m == null) return null;
    final frac = m[2] ?? '';
    final r = Ratio(
      BigInt.parse('${m[1]}$frac'),
      BigInt.from(10).pow(frac.length),
    );
    return r.numerator == BigInt.zero ? null : r;
  }

  final BigInt numerator;
  final BigInt denominator;

  Ratio get inverse => Ratio(denominator, numerator);
  Ratio operator *(Ratio o) =>
      Ratio(numerator * o.numerator, denominator * o.denominator);

  /// Decimal text with up to [maxDecimals] places, trailing zeros removed.
  String toDecimalString({int maxDecimals = 6}) {
    final scale = BigInt.from(10).pow(maxDecimals);
    final scaled = _roundHalfEven(numerator * scale, denominator);
    final whole = scaled ~/ scale;
    var frac = (scaled % scale).toString().padLeft(maxDecimals, '0');
    frac = frac.replaceFirst(RegExp(r'0+$'), '');
    return frac.isEmpty ? '$whole' : '$whole.$frac';
  }

  @override
  bool operator ==(Object other) =>
      other is Ratio &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => toDecimalString();
}

BigInt _roundHalfEven(BigInt n, BigInt d) {
  var q = n ~/ d;
  var r = n - q * d;
  if (r.isNegative) {
    q -= BigInt.one;
    r += d;
  }
  final twice = r * BigInt.two;
  if (twice > d || (twice == d && q.isOdd)) q += BigInt.one;
  return q;
}

/// A conversion result with everything the UI shows next to "≈".
typedef Conversion = ({
  Money amount,
  Ratio rate,
  LocalDate asOf,
  String source,
});

/// Converts between currencies using the rates it was given: direct, inverse,
/// or through one shared currency (e.g. JPY → USD → TWD).
class FxConverter {
  FxConverter(Iterable<ExchangeRate> rates) {
    for (final r in rates) {
      _rates[(r.base, r.quote)] = r;
      _rates.putIfAbsent((r.quote, r.base), () => r.inverse);
    }
  }

  final _rates = <(Currency, Currency), ExchangeRate>{};

  /// Best available rate from [from] to [to], or null when none is known.
  /// The date reported is the older of any two rates chained together.
  ExchangeRate? rate(Currency from, Currency to) {
    if (from == to) return null;
    final direct = _rates[(from, to)];
    if (direct != null) return direct;
    for (final MapEntry(key: (a, via), value: first) in _rates.entries) {
      if (a != from) continue;
      final second = _rates[(via, to)];
      if (second == null) continue;
      return ExchangeRate(
        base: from,
        quote: to,
        rate: first.rate * second.rate,
        asOf: first.asOf < second.asOf ? first.asOf : second.asOf,
        source: first.source == second.source ? first.source : 'mixed',
      );
    }
    return null;
  }

  /// [money] in [to], optionally adding a card's foreign transaction fee in
  /// basis points (150 = 1.5%). Rounded half-even to [to]'s minor unit.
  /// Null when no rate is known. Same-currency amounts pass through.
  Conversion? convert(Money money, Currency to, {int feeBasisPoints = 0}) {
    if (money.currency == to) {
      return (
        amount: money,
        rate: Ratio(BigInt.one, BigInt.one),
        asOf: LocalDate(1970, 1, 1),
        source: 'same',
      );
    }
    final r = rate(money.currency, to);
    if (r == null) return null;
    final ten = BigInt.from(10);
    final n =
        BigInt.from(money.minor) *
        r.rate.numerator *
        ten.pow(to.minorUnits) *
        BigInt.from(10000 + feeBasisPoints);
    final d =
        r.rate.denominator *
        ten.pow(money.currency.minorUnits) *
        BigInt.from(10000);
    return (
      amount: Money(_roundHalfEven(n, d).toInt(), to),
      rate: r.rate,
      asOf: r.asOf,
      source: r.source,
    );
  }
}
