import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:test/test.dart';

void main() {
  final today = LocalDate(2026, 11, 2);
  Money usd(int dollars) => Money(dollars * 100, Currency.usd);

  test('an irregular bill plans no charges', () {
    final s = ItemSchedule(
      anchor: LocalDate(2026, 1, 1),
      cycle: Cycle.monthly,
      prices: PriceSchedule.fixed(usd(0)),
      irregular: true,
    );
    expect(expectedOccurrences(s, today: today), isEmpty);
    expect(planOccurrences(s, const [], today: today).toInsert, isEmpty);
  });

  group('irregularMonthly', () {
    test('no payments: unknown (to fill in)', () {
      expect(irregularMonthly(const [], today: today), isNull);
    });

    test('one top-up counts over at least three months', () {
      expect(
        irregularMonthly([(LocalDate(2026, 10, 20), usd(30))], today: today),
        usd(10),
      );
    });

    test('averages over the months since the first payment, up to 12', () {
      final payments = [
        (LocalDate(2026, 6, 5), usd(20)),
        (LocalDate(2026, 8, 9), usd(25)),
        (LocalDate(2026, 10, 30), usd(15)),
        (LocalDate(2025, 1, 1), usd(999)), // older than a year: left out
      ];
      // June through November: 6 months, US$60 → US$10 a month.
      expect(irregularMonthly(payments, today: today), usd(10));
    });
  });

  test('an irregular bill is matched by name, whatever the amount or day', () {
    final candidate = ChargeCandidate(
      itemId: 'openrouter',
      names: const ['OpenRouter'],
      expected: usd(0),
      dueOn: today,
      anyAmount: true,
    );
    final named = matchCharge(
      ParsedCharge(amount: usd(17), merchant: 'OPENROUTER.AI'),
      today.addDays(40),
      [candidate],
    )!;
    expect(named.confidence, MatchConfidence.high);
    expect(
      matchCharge(ParsedCharge(amount: usd(17)), today, [candidate]),
      isNull,
      reason: 'no name, no match',
    );
  });
}
