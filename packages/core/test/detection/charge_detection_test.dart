import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

ParsedCharge? tw(String s) => parseCharge(s, region: 'TW');

void main() {
  group('parseCharge', () {
    test('Taiwan credit card wording', () {
      expect(
        tw('您的卡號末四碼1234於11/01 14:32在NETFLIX.COM消費新臺幣390元'),
        const ParsedCharge(
          amount: Money(39000, Currency.twd),
          merchant: 'NETFLIX.COM',
          last4: '1234',
        ),
      );
      final ctbc = tw('【中國信託】您的信用卡****5678 於 2026/11/02 消費 NT\$149，商店：Spotify');
      expect(ctbc!.amount, const Money(14900, Currency.twd));
      expect(ctbc.merchant, 'Spotify');
      expect(ctbc.last4, '5678');
      expect(
        tw('信用卡消費新臺幣1,250元 特店：中華電信')!.amount,
        const Money(125000, Currency.twd),
      );
    });

    test('e-wallets and app stores', () {
      final jko = tw('街口支付 已付款 \$99 給 KKBOX');
      expect(jko!.amount, const Money(9900, Currency.twd));
      expect(jko.merchant, 'KKBOX');
      final play = tw(
        'Google Play: You\'ve been charged US\$20.00 for ChatGPT Plus',
      );
      expect(play!.amount, const Money(2000, Currency.usd));
      expect(play.merchant, 'ChatGPT Plus');
    });

    test('Hong Kong and mainland wording', () {
      final hsbc = parseCharge(
        'HSBC: A purchase of HKD 78.00 at NETFLIX.COM was made with your card ending 4321',
        region: 'HK',
      );
      expect(hsbc!.amount, const Money(7800, Currency.hkd));
      expect(hsbc.merchant, 'NETFLIX.COM');
      expect(hsbc.last4, '4321');
      final alipay = parseCharge('支付宝 支付成功 ¥25.00 美团', region: 'CN');
      expect(alipay!.amount, const Money(2500, Currency.cny));
    });

    test('refunds, income and non-charges are ignored', () {
      expect(tw('退款通知：NETFLIX 退刷 NT\$390'), isNull);
      expect(tw('您的帳戶轉入 NT\$50,000'), isNull);
      expect(tw('本月帳單已出帳，請記得繳費'), isNull);
      expect(tw('消費提醒：今天天氣晴'), isNull, reason: 'no amount');
    });

    test('a shared symbol that the region does not settle is skipped', () {
      // ¥ in Taiwan could be yen or yuan: ask rather than guess.
      expect(tw('支付成功 ¥25.00 美团'), isNull);
    });
  });

  group('matchCharge', () {
    final nov1 = LocalDate(2026, 11, 1);
    final netflix = ChargeCandidate(
      itemId: 'netflix',
      names: const ['Netflix', 'NETFLIX.COM'],
      expected: const Money(39000, Currency.twd),
      dueOn: nov1,
      occurrenceId: 'netflix:2026-11-01',
      cardLast4: '1234',
    );
    final chatgpt = ChargeCandidate(
      itemId: 'chatgpt',
      names: const ['ChatGPT', 'OpenAI'],
      expected: const Money(2000, Currency.usd),
      dueOn: nov1,
      accountFeeBasisPoints: 150,
    );
    final fx = FxConverter([
      ExchangeRate(
        base: Currency.usd,
        quote: Currency.twd,
        rate: Ratio.tryParse('32.5')!,
        asOf: nov1,
        source: 'manual',
      ),
    ]);
    ChargeMatch? match(ParsedCharge c, {LocalDate? on}) =>
        matchCharge(c, on ?? nov1.addDays(1), [netflix, chatgpt], fx: fx);

    test('name, amount, date and card all fit: recorded automatically', () {
      final m = match(
        const ParsedCharge(
          amount: Money(39000, Currency.twd),
          merchant: 'NETFLIX.COM',
          last4: '1234',
        ),
      )!;
      expect(m.candidate.itemId, 'netflix');
      expect(m.confidence, MatchConfidence.high);
    });

    test('a foreign price charged in the card currency, within its markup', () {
      final m = match(
        const ParsedCharge(
          amount: Money(66100, Currency.twd),
          merchant: 'OPENAI *CHATGPT SUBSCR',
        ),
      )!;
      expect(m.candidate.itemId, 'chatgpt');
      expect(m.confidence, MatchConfidence.high);
    });

    test('a different amount, or no merchant: ask instead', () {
      expect(
        match(
          const ParsedCharge(
            amount: Money(42000, Currency.twd),
            merchant: 'Netflix',
          ),
        )!.confidence,
        MatchConfidence.low,
      );
      final noName = match(
        const ParsedCharge(amount: Money(39000, Currency.twd)),
      )!;
      expect(noName.candidate.itemId, 'netflix');
      expect(noName.confidence, MatchConfidence.low);
    });

    test('nothing close: no match; another card counts against', () {
      expect(
        match(const ParsedCharge(amount: Money(12300, Currency.twd))),
        isNull,
      );
      expect(
        match(
          const ParsedCharge(amount: Money(39000, Currency.twd)),
          on: nov1.addDays(20),
        ),
        isNull,
        reason: 'outside the date window and unnamed',
      );
      final otherCard = match(
        const ParsedCharge(
          amount: Money(39000, Currency.twd),
          merchant: 'Netflix',
          last4: '9999',
        ),
      )!;
      expect(otherCard.confidence, MatchConfidence.low);
    });
  });

  test('recurring merchants not on the list are suggested', () {
    final seen = [
      UnmatchedCharge(
        merchant: 'Notion Labs',
        amount: const Money(1000, Currency.usd),
        on: LocalDate(2026, 9, 3),
      ),
      UnmatchedCharge(
        merchant: 'NOTION LABS',
        amount: const Money(1000, Currency.usd),
        on: LocalDate(2026, 10, 3),
      ),
      UnmatchedCharge(
        merchant: '7-ELEVEN',
        amount: const Money(8500, Currency.twd),
        on: LocalDate(2026, 10, 3),
      ),
      UnmatchedCharge(
        merchant: '7-ELEVEN',
        amount: const Money(4500, Currency.twd),
        on: LocalDate(2026, 10, 5),
      ),
    ];
    expect(recurringMerchants(seen).map((c) => c.merchant), ['NOTION LABS']);
  });
}
