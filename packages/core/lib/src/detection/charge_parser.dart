import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import '../money/money_format.dart';
import '../money/symbol_resolver.dart';

/// What a bank or payment notification says was charged.
@immutable
class ParsedCharge {
  const ParsedCharge({required this.amount, this.merchant, this.last4});

  final Money amount;

  /// Shop or service as printed, if found ("NETFLIX.COM", "Google Play").
  final String? merchant;

  /// Last four digits of the card or account, if shown.
  final String? last4;

  @override
  bool operator ==(Object other) =>
      other is ParsedCharge &&
      other.amount == amount &&
      other.merchant == merchant &&
      other.last4 == last4;

  @override
  int get hashCode => Object.hash(amount, merchant, last4);

  @override
  String toString() => 'ParsedCharge($amount, $merchant, ··$last4)';
}

/// Words that mark a notification as a charge (zh-Hant, zh-Hans, en).
final _chargeWords = RegExp(
  r'消費|扣款|刷卡|交易|支付|付款|扣繳|已扣|簽帳|授權|自動加值|續訂|'
  r'消费|扣费|'
  r'charged|charge of|payment|paid|purchase|spent|debited|transaction|subscription|renew',
  caseSensitive: false,
);

/// Not a charge, even if it mentions money: refunds, income, offers.
final _notCharge = RegExp(
  r'退款|退刷|退費|入帳|轉入|收款|存入|回饋|優惠券|折價|餘額不足|'
  r'入账|转入|'
  r'refund|reversal|received|deposit|cashback|declined|failed',
  caseSensitive: false,
);

/// A currency marker followed by an amount, or an amount followed by one.
/// Markers: ISO codes, prefixed symbols (NT$, US$, HK$, JP¥ …), bare
/// symbols, and Chinese currency words.
const _marker =
    r'(?:[A-Z]{3}|NT\$|US\$|HK\$|S\$|A\$|C\$|NZ\$|MOP\$|JP¥|CN¥|RMB|₩|€|£|¥|\$|'
    r'新臺幣|新台幣|臺幣|台幣|美元|美金|港幣|港元|日圓|日元|人民幣|人民币|歐元|欧元|韓元|韩元)';
const _number = r'(\d{1,3}(?:[,，]\d{3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)';
final _before = RegExp('$_marker\\s?$_number');
final _after = RegExp('$_number\\s?($_marker|元)');

final _last4 = RegExp(
  r'(?:末四碼|末4碼|尾號|尾号|末四位|卡號|卡号|ending(?: in)?|card)\D{0,8}(\d{4})'
  r'|[*＊xX•]{2,}\s?(\d{4})',
  caseSensitive: false,
);

/// Merchant after a marker word, up to punctuation, a verb or an amount.
/// Starts with a letter (not a digit), so dates after 於 are skipped.
final _merchant = RegExp(
  r'(?:於|在|給|向|消費店家|特約商店|商店|特店|商户|商戶|\bat|\bto|\bfor|\bfrom|merchant)[:：\s]*'
  r'([A-Za-z一-鿿][A-Za-z0-9一-鿿 .&+*\-_/]{1,40}?)'
  r'(?=\s*(?:消費|扣款|刷卡|交易|支付|付款|，|,|。|\.\s|;|；|\(|（|$|\n|'
  r'NT\$|US\$|HK\$|[0-9]{2,}|\bwas\b|\bon\b|\bwith\b))',
  caseSensitive: false,
);

/// Reads a charge from a notification's text, on the phone, with rules
/// (no AI). Returns null when it does not look like a charge.
///
/// [region] settles shared symbols such as `$` and `元`.
ParsedCharge? parseCharge(String text, {required String region}) {
  final t = text.replaceAll(' ', ' ');
  if (!_chargeWords.hasMatch(t) || _notCharge.hasMatch(t)) return null;

  Money? amount;
  final matches = [..._before.allMatches(t), ..._after.allMatches(t)]
    ..sort((a, b) => a.start.compareTo(b.start));
  for (final m in matches) {
    final before = m.pattern == _before;
    final digits = m[1]!;
    final marker = before
        ? m[0]!.substring(0, m[0]!.lastIndexOf(digits))
        : m[2]!;
    final currency = resolveCurrencySymbol(marker.trim(), region: region);
    if (currency == null) continue;
    final value = parseMoney(digits.replaceAll('，', ','), currency);
    if (value == null || value.minor <= 0) continue;
    amount = value;
    break;
  }
  if (amount == null) return null;

  final card = _last4.firstMatch(t);
  final merchant = _merchant.firstMatch(t)?[1]?.trim();
  return ParsedCharge(
    amount: amount,
    merchant: merchant == null || merchant.length < 2 ? null : merchant,
    last4: card == null ? null : (card[1] ?? card[2]),
  );
}

/// Lower case, without spaces and punctuation, for comparing names.
String normalizeMerchant(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\.(com|net|tv|io|co)\b'), '')
    .replaceAll(RegExp(r'[\s.\-_*/&,，。:：()（）]'), '');

/// Currency of a parsed amount.
Currency currencyOf(ParsedCharge c) => c.amount.currency;
