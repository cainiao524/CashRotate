import 'package:intl/intl.dart';

import 'currency.dart';
import 'currency_info.dart';
import 'money.dart';

/// Formats [money] for [locale] with its unambiguous symbol (`NT$390`,
/// `US$20.00`, `LKR 1,000.00`), grouping and decimal marks from the locale.
///
/// [decimals] overrides the currency's default display precision (users can
/// show TWD with cents, for instance). Display rounding is half-even; the
/// stored amount is never changed.
String formatMoney(Money money, {required String locale, int? decimals}) {
  final info = CurrencyInfo.of(money.currency);
  final digits = decimals ?? money.currency.defaultDisplayDecimals;
  final format = NumberFormat.currency(
    locale: locale,
    name: money.currency.code,
    symbol: info.symbolIsCode ? '${info.symbol} ' : info.symbol,
    decimalDigits: digits,
  );
  return format.format(_displayValue(money, digits));
}

/// Just the number, without a symbol: for amount fields and table cells.
String formatAmount(Money money, {required String locale, int? decimals}) {
  final digits = decimals ?? money.currency.defaultDisplayDecimals;
  final format = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: digits,
  );
  return format.format(_displayValue(money, digits));
}

/// The amount in major units rounded half-even to [digits] places, as a
/// double only for display.
num _displayValue(Money money, int digits) {
  final drop = money.currency.minorUnits - digits;
  if (drop <= 0) return money.minor / money.currency.minorPerMajor;
  var factor = 1;
  for (var i = 0; i < drop; i++) {
    factor *= 10;
  }
  final rounded = divideRoundHalfEven(money.minor, factor) * factor;
  return rounded / money.currency.minorPerMajor;
}

/// Parses what a user typed into an amount field: digits with an optional
/// decimal part using `.` or `,`, grouping separators and spaces ignored.
/// Returns null for empty, invalid, negative or over-precise input.
Money? parseMoney(String input, Currency currency) {
  final text = input.trim().replaceAll(RegExp(r'[\s  _]'), '');
  if (text.isEmpty) return null;
  // The last '.' or ',' followed by 1–3 digits that are not a group of three
  // after another separator is the decimal mark; others are grouping.
  final lastDot = text.lastIndexOf('.');
  final lastComma = text.lastIndexOf(',');
  final sep = lastDot > lastComma ? lastDot : lastComma;
  String whole;
  String fraction;
  if (sep < 0) {
    whole = text;
    fraction = '';
  } else {
    final after = text.substring(sep + 1);
    final before = text.substring(0, sep);
    final mark = text[sep];
    final otherMark = mark == '.' ? ',' : '.';
    // Three trailing digits are thousands for "1,000", "1.000.000" or a
    // currency without minor units; a lone "20.001" stays a (too precise)
    // decimal so it is rejected rather than read as twenty thousand.
    final looksLikeGrouping =
        after.length == 3 &&
        !before.contains(otherMark) &&
        (before.contains(mark) || mark == ',' || currency.minorUnits == 0);
    if (looksLikeGrouping) {
      whole = text;
      fraction = '';
    } else {
      whole = before;
      fraction = after;
    }
  }
  whole = whole.replaceAll(RegExp('[.,]'), '');
  if (!RegExp(r'^\d+$').hasMatch(whole) ||
      !RegExp(r'^\d*$').hasMatch(fraction)) {
    return null;
  }
  if (fraction.length > currency.minorUnits) return null;
  final minor =
      int.parse(whole) * currency.minorPerMajor +
      (fraction.isEmpty
          ? 0
          : int.parse(fraction.padRight(currency.minorUnits, '0')));
  return Money(minor, currency);
}
