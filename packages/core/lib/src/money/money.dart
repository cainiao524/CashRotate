import 'package:meta/meta.dart';

import 'currency.dart';

/// An exact amount: an integer count of [currency]'s minor units.
///
/// Arithmetic only combines amounts of the same currency; converting between
/// currencies is the FX layer's job and always records the rate used.
@immutable
final class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  final int minor;
  final Currency currency;

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;

  Money operator +(Money other) => Money(minor + _same(other).minor, currency);
  Money operator -(Money other) => Money(minor - _same(other).minor, currency);
  Money operator -() => Money(-minor, currency);
  Money times(int factor) => Money(minor * factor, currency);

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine ${currency.code} with ${other.currency.code}',
      );
    }
    return other;
  }

  @override
  int compareTo(Money other) => minor.compareTo(_same(other).minor);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >(Money other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '${currency.code} $minor';
}

/// Rounds the exact fraction [numerator] / [denominator] to the nearest
/// integer, ties to even (banker's rounding), so repeated amortisation does
/// not drift in one direction.
int divideRoundHalfEven(int numerator, int denominator) {
  if (denominator == 0) throw ArgumentError.value(denominator, 'denominator');
  if (denominator < 0) {
    numerator = -numerator;
    denominator = -denominator;
  }
  var q = numerator ~/ denominator;
  var r = numerator - q * denominator;
  if (r < 0) {
    q -= 1;
    r += denominator;
  }
  final twice = 2 * r;
  if (twice > denominator || (twice == denominator && q.isOdd)) q += 1;
  return q;
}
