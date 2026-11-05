import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'settings_test.dart' show openSettings, scrollTo;

IncomeSource income(
  IncomeType type,
  Money amount, {
  Cycle cycle = Cycle.monthly,
  bool counts = true,
  String id = '',
}) => IncomeSource(
  id: id.isEmpty ? type.name : id,
  type: type,
  name: '',
  amount: amount,
  cycle: cycle,
  countsInShare: counts,
);

void main() {
  final fx = FxConverter([
    ExchangeRate(
      base: Currency.usd,
      quote: Currency.twd,
      rate: Ratio.tryParse('32')!,
      asOf: LocalDate(2026, 3, 15),
      source: 'manual',
    ),
  ]);
  const twd = Currency.twd;

  test('every kind and cycle becomes a monthly amount', () {
    final c = compareIncome(
      [
        income(IncomeType.salary, const Money(6000000, twd)),
        income(
          IncomeType.bonus,
          const Money(12000000, twd),
          cycle: Cycle.yearly,
        ),
        income(
          IncomeType.freelance,
          const Money(50000, Currency.usd), // US$500 a quarter
          cycle: Cycle.quarterly,
        ),
        income(
          IncomeType.sales,
          const Money(300000, twd),
          counts: false, // one-off: not relied on
        ),
      ],
      fixedMonthly: const Money(3000000, twd),
      fx: fx,
    )!;
    // 60,000 + 120,000 / 12 + US$166.67 a month × 32 = 75,333.44
    expect(c.income.minor, 7533344);
    expect(c.share, closeTo(3000000 / 7533344, 1e-9));
    expect(c.remaining.minor, 7533344 - 3000000);
    expect(
      [for (final e in c.byType) e.type],
      [IncomeType.salary, IncomeType.bonus, IncomeType.freelance],
    );
  });

  test('nothing counted: no comparison; no rate: left out and counted', () {
    expect(
      compareIncome(
        [income(IncomeType.sales, const Money(1, twd), counts: false)],
        fixedMonthly: const Money(100, twd),
        fx: fx,
      ),
      isNull,
    );
    final c = compareIncome(
      [income(IncomeType.rental, const Money(100000, Currency.jpy))],
      fixedMonthly: const Money(100, twd),
      fx: fx,
    )!;
    expect(c.missingRates, 1);
    expect(c.share, isNull);
  });

  test('stored and read back; unreadable entries are skipped', () {
    final i = income(
      IncomeType.pension,
      const Money(2000000, twd),
      cycle: Cycle(CycleUnit.week, 2),
    );
    expect(IncomeSource.fromJson(i.toJson()), i);
    expect(IncomeSource.fromJson({'id': 'x'}), isNull);
  });

  testApp('add salary and a yearly bonus; home shows the share of income', (
    tester,
  ) async {
    final data = await pumpApp(tester, seed: (d) => d.seedItems());
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const Key('settings-income')));
    await tester.tap(find.byKey(const Key('settings-income')));
    await settle(tester);

    Future<void> add(String type, String amount, {String? cycle}) async {
      await tester.tap(find.byKey(const Key('income-add')));
      await settle(tester);
      await tester.tap(find.byKey(ValueKey('income-type-$type')));
      await tester.enterText(find.byKey(const Key('income-amount')), amount);
      if (cycle != null) {
        await tester.ensureVisible(find.byKey(ValueKey('income-cycle-$cycle')));
        await tester.tap(find.byKey(ValueKey('income-cycle-$cycle')));
      }
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('income-save')));
      await tester.tap(find.byKey(const Key('income-save')));
      await settle(tester, frames: 8);
    }

    await add('salary', '50000');
    await add('bonus', '60000'); // yearly by default
    final settings = await tester.runAsync(
      () => data.settings.read(
        const UserSettings(mainCurrency: Currency.twd, region: 'TW'),
      ),
    );
    expect(settings!.incomes, hasLength(2));
    expect(settings.incomes.last.cycle, Cycle.yearly);
    // 50,000 + 5,000 a month; fixed NT$18,752 → 34%, NT$36,248 left.
    expect(find.text(r'NT$55,000'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await settle(tester);
    final line = tester.widget<Text>(
      find.byKey(const Key('home-income-share')),
    );
    expect(line.data, r'34% of income · NT$36,248 left');
  });
}
