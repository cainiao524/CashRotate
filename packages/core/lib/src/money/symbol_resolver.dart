import 'currency.dart';
import 'currency_info.dart';

/// Works out which currency a symbol or word in user text means.
///
/// Unambiguous forms (`NT$`, `JP¥`, `€`, ISO codes, 美元, 日圓 …) resolve
/// directly. Shared symbols (`$`, `¥`, `元`, `Rs` …) resolve from the
/// preset's billing currency, then the user's region; when neither settles
/// it the result is null and the caller must ask.
Currency? resolveCurrencySymbol(
  String token, {
  String? region,
  Currency? presetCurrency,
}) {
  final t = token.trim();
  if (t.isEmpty) return null;
  final upper = t.toUpperCase();

  final byCode = Currency.tryParse(upper);
  if (byCode != null) return byCode;
  for (final info in CurrencyInfo.all) {
    if (info.symbol.toUpperCase() == upper && !info.symbolIsCode) {
      return info.currency;
    }
  }
  if (_words[t] case final c?) return c;

  final candidates = _shared[t] ?? _shared[upper];
  if (candidates == null) return null;
  if (presetCurrency != null && candidates.contains(presetCurrency)) {
    return presetCurrency;
  }
  final local = region == null ? null : CurrencyInfo.forRegion(region);
  if (local != null && candidates.contains(local)) return local;
  return null;
}

/// Shared symbols and the currencies they can mean.
const _shared = <String, List<Currency>>{
  r'$': [
    Currency.usd, Currency.twd, Currency.hkd, Currency.sgd, Currency.aud, //
    Currency.nzd, Currency.fjd, Currency.bnd, Currency.sbd, Currency.mop,
    Currency.wst, Currency.top,
  ],
  '¥': [Currency.jpy, Currency.cny],
  '￥': [Currency.jpy, Currency.cny],
  '元': [Currency.cny, Currency.twd, Currency.hkd, Currency.mop],
  '塊': [Currency.cny, Currency.twd, Currency.hkd],
  '块': [Currency.cny, Currency.twd, Currency.hkd],
  'RS': [Currency.inr, Currency.pkr, Currency.lkr, Currency.npr],
  'K': [Currency.mmk, Currency.pgk],
  'DOLLAR': [
    Currency.usd,
    Currency.twd,
    Currency.hkd,
    Currency.sgd,
    Currency.aud,
    Currency.nzd,
  ],
};

/// Words that name exactly one currency in Chinese or English slang.
const _words = <String, Currency>{
  '美元': Currency.usd,
  '美金': Currency.usd,
  '刀': Currency.usd,
  'USD': Currency.usd, //
  '日圓': Currency.jpy,
  '日元': Currency.jpy,
  '日幣': Currency.jpy,
  '日币': Currency.jpy,
  '円': Currency.jpy,
  '人民幣': Currency.cny, '人民币': Currency.cny, 'RMB': Currency.cny,
  '台幣': Currency.twd,
  '臺幣': Currency.twd,
  '新台幣': Currency.twd,
  '新臺幣': Currency.twd,
  '台币': Currency.twd,
  '港幣': Currency.hkd, '港币': Currency.hkd, '港元': Currency.hkd, '蚊': Currency.hkd,
  '歐元': Currency.eur, '欧元': Currency.eur,
  '韓元': Currency.krw, '韩元': Currency.krw, '韓圓': Currency.krw,
  '澳幣': Currency.aud, '澳元': Currency.aud,
  '新幣': Currency.sgd, '新加坡元': Currency.sgd, '坡幣': Currency.sgd,
  '泰銖': Currency.thb, '泰铢': Currency.thb,
};
