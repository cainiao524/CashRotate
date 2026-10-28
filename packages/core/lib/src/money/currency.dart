/// A currency the app supports as a main or pricing currency.
///
/// Amounts are stored as integers in the currency's ISO 4217 minor unit
/// ([minorUnits] decimal places). Display may round further: see
/// [defaultDisplayDecimals].
final class Currency {
  const Currency._(this.code, this.minorUnits, {int? displayDecimals})
    : defaultDisplayDecimals = displayDecimals ?? minorUnits;

  /// ISO 4217 alphabetic code, e.g. `TWD`.
  final String code;

  /// Decimal places of the stored minor unit.
  final int minorUnits;

  /// Decimal places shown by default. Some currencies are stored with cents
  /// but customarily shown as whole numbers (TWD, IDR …); users can change this
  /// in settings.
  final int defaultDisplayDecimals;

  /// 10^[minorUnits]: minor units per major unit.
  int get minorPerMajor => _pow10(minorUnits);

  static Currency? tryParse(String code) => _byCode[code.toUpperCase()];

  static Currency parse(String code) =>
      tryParse(code) ??
      (throw ArgumentError.value(code, 'code', 'unsupported currency'));

  @override
  String toString() => code;

  // Asia–Pacific plus USD and EUR: 41 currencies. KPW is excluded because the
  // exchange-rate sources publish no quote for it.
  static const twd = Currency._('TWD', 2, displayDecimals: 0);
  static const hkd = Currency._('HKD', 2);
  static const mop = Currency._('MOP', 2);
  static const cny = Currency._('CNY', 2);
  static const jpy = Currency._('JPY', 0);
  static const krw = Currency._('KRW', 0);
  static const mnt = Currency._('MNT', 2, displayDecimals: 0);
  static const sgd = Currency._('SGD', 2);
  static const myr = Currency._('MYR', 2);
  static const thb = Currency._('THB', 2);
  static const vnd = Currency._('VND', 0);
  static const php = Currency._('PHP', 2);
  static const idr = Currency._('IDR', 2, displayDecimals: 0);
  static const bnd = Currency._('BND', 2);
  static const khr = Currency._('KHR', 2, displayDecimals: 0);
  static const lak = Currency._('LAK', 2, displayDecimals: 0);
  static const mmk = Currency._('MMK', 2, displayDecimals: 0);
  static const inr = Currency._('INR', 2);
  static const pkr = Currency._('PKR', 2);
  static const bdt = Currency._('BDT', 2);
  static const lkr = Currency._('LKR', 2);
  static const npr = Currency._('NPR', 2);
  static const btn = Currency._('BTN', 2);
  static const mvr = Currency._('MVR', 2);
  static const afn = Currency._('AFN', 2);
  static const aud = Currency._('AUD', 2);
  static const nzd = Currency._('NZD', 2);
  static const fjd = Currency._('FJD', 2);
  static const pgk = Currency._('PGK', 2);
  static const sbd = Currency._('SBD', 2);
  static const vuv = Currency._('VUV', 0);
  static const wst = Currency._('WST', 2);
  static const top = Currency._('TOP', 2);
  static const xpf = Currency._('XPF', 0);
  static const kzt = Currency._('KZT', 2);
  static const uzs = Currency._('UZS', 2, displayDecimals: 0);
  static const kgs = Currency._('KGS', 2);
  static const tjs = Currency._('TJS', 2);
  static const tmt = Currency._('TMT', 2);
  static const usd = Currency._('USD', 2);
  static const eur = Currency._('EUR', 2);

  static const all = <Currency>[
    twd, hkd, mop, cny, jpy, krw, mnt, sgd, myr, thb, vnd, php, idr, bnd, //
    khr, lak, mmk, inr, pkr, bdt, lkr, npr, btn, mvr, afn, aud, nzd, fjd, //
    pgk, sbd, vuv, wst, top, xpf, kzt, uzs, kgs, tjs, tmt, usd, eur,
  ];

  static final Map<String, Currency> _byCode = {for (final c in all) c.code: c};
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
