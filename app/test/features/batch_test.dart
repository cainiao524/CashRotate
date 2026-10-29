import 'package:cashrotate/features/onboarding/batch.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = LocalDate(2026, 3, 15);
  final netflix = Preset.fromJson({
    'id': 'netflix',
    'name': {'en': 'Netflix', 'zh-Hans': '奈飞'},
    'category': 'streaming',
    'type': 'subscription',
    'defaultCycle': 'monthly',
    'regions': ['global'],
    'color': '#E50914',
    'cancelUrl': 'https://www.netflix.com/cancelplan',
  });

  test('rows from presets carry name, cycle, currency and cancel link', () {
    final row = BatchRow.fromPreset(
      netflix,
      language: 'zh-Hans',
      mainCurrency: Currency.twd,
    );
    expect(row.name, '奈飞');
    expect(row.currency, Currency.twd);
    expect(row.isPending, isTrue);
  });

  test('blank amount or date is saved as an item to fill in', () {
    final row = BatchRow.fromPreset(
      netflix,
      language: 'en',
      mainCurrency: Currency.twd,
    );
    final item = row.toNewItem(today: today);
    expect(item.needsDetails, isTrue);
    expect(item.prices.stablePrice, const Money.zero(Currency.twd));
    expect(item.anchor, today);
    expect(item.typeFields, {
      'cancelUrl': 'https://www.netflix.com/cancelplan',
    });

    row
      ..amountText = '390'
      ..date = LocalDate(2026, 3, 20);
    final complete = row.toNewItem(today: today);
    expect(complete.needsDetails, isFalse);
    expect(complete.prices.stablePrice, const Money(39000, Currency.twd));
    expect(complete.anchor, LocalDate(2026, 3, 20));
  });

  test('apply date and currency to selected rows only', () {
    final draft =
        BatchDraft(
            rows: [
              BatchRow.custom('A', mainCurrency: Currency.twd)..selected = true,
              BatchRow.custom('B', mainCurrency: Currency.twd),
              BatchRow.custom('C', mainCurrency: Currency.twd)..selected = true,
            ],
          )
          ..applyDate(LocalDate(2026, 4, 1))
          ..applyCurrency(Currency.usd);
    expect(draft.rows.map((r) => r.date?.toString()), [
      '2026-04-01',
      null,
      '2026-04-01',
    ]);
    expect(draft.rows.map((r) => r.currency), [
      Currency.usd,
      Currency.twd,
      Currency.usd,
    ]);
    draft.selectAll(true);
    expect(draft.selected, hasLength(3));
  });

  test('toggle adds and removes by key', () {
    final draft = BatchDraft();
    final row = BatchRow.fromPreset(
      netflix,
      language: 'en',
      mainCurrency: Currency.twd,
    );
    draft.toggle(row);
    expect(draft.contains('netflix'), isTrue);
    draft.toggle(row);
    expect(draft.rows, isEmpty);
  });

  test('round-trips through JSON so setup can resume', () {
    final draft = BatchDraft(
      step: 3,
      rows: [
        BatchRow.fromPreset(netflix, language: 'en', mainCurrency: Currency.twd)
          ..amountText = '390'
          ..date = LocalDate(2026, 3, 20)
          ..selected = true,
        BatchRow.custom('Gym', mainCurrency: Currency.hkd),
      ],
    );
    final restored = BatchDraft.fromJson(draft.toJson());
    expect(restored.step, 3);
    expect(
      restored.rows.map((r) => r.toJson()),
      draft.rows.map((r) => r.toJson()),
    );
    expect(BatchDraft.fromJson(null).rows, isEmpty);
    expect(BatchDraft.fromJson('junk').step, 0);
  });
}
