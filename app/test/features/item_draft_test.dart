import 'package:cashrotate/features/items/item_draft.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';

Preset preset(Map<String, Object?> extra) => Preset.fromJson({
  'id': 'chatgpt',
  'name': {'en': 'ChatGPT'},
  'category': 'ai',
  'type': 'subscription',
  'defaultCycle': 'monthly',
  'regions': ['global'],
  'color': '#10A37F',
  ...extra,
});

void main() {
  group('fromPreset', () {
    test('takes name, type, cycle, billing currency and reminder days', () {
      final d = ItemDraft.fromPreset(
        preset({
          'currency': 'USD',
          'remindDays': 7,
          'cancelUrl': 'https://x.test/c',
        }),
        language: 'en',
        mainCurrency: Currency.twd,
      );
      expect(d.name, 'ChatGPT');
      expect(d.type, ItemType.subscription);
      expect(d.cycle, Cycle.monthly);
      expect(d.currency, Currency.usd, reason: 'AI subscriptions bill in USD');
      expect(d.remindDays, [7]);
      expect(d.fields['cancelUrl'], 'https://x.test/c');
    });

    test('services billed locally use the main currency', () {
      final d = ItemDraft.fromPreset(
        preset({}),
        language: 'en',
        mainCurrency: Currency.hkd,
      );
      expect(d.currency, Currency.hkd);
    });

    test('field groups follow type and preset', () {
      final domain = ItemDraft.fromPreset(
        preset({
          'fields': ['domain'],
        }),
        language: 'en',
        mainCurrency: Currency.usd,
      );
      expect(
        domain.groups,
        containsAll([
          FieldGroup.subscription,
          FieldGroup.trial,
          FieldGroup.domain,
          FieldGroup.sharing,
        ]),
      );
      final loan = ItemDraft(
        type: ItemType.repayment,
        currency: Currency.twd,
        cycle: Cycle.monthly,
      );
      expect(loan.groups, contains(FieldGroup.repayment));
      expect(loan.groups, isNot(contains(FieldGroup.sharing)));
    });
  });

  group('validation', () {
    ItemDraft draft() => ItemDraft(
      type: ItemType.subscription,
      currency: Currency.usd,
      cycle: Cycle.monthly,
      name: 'VPS',
      amountText: '8',
      nextCharge: LocalDate(2026, 4, 1),
    );

    test('a complete draft is valid', () => expect(draft().isValid, isTrue));

    test('name, amount and date are required', () {
      final d = draft()
        ..name = ' '
        ..amountText = ''
        ..nextCharge = null;
      expect(d.validate(), {
        DraftField.name: DraftError.required,
        DraftField.amount: DraftError.required,
        DraftField.nextCharge: DraftError.required,
      });
    });

    test('unreadable or over-precise amounts', () {
      expect(
        (draft()..amountText = 'abc').validate()[DraftField.amount],
        DraftError.amount,
      );
      expect(
        (draft()..amountText = '8.123').validate()[DraftField.amount],
        DraftError.amount,
      );
    });

    test('intro price on: renewal price is required', () {
      final d = draft()
        ..intro = true
        ..introAmountText = '5'
        ..introPeriodsText = '3'
        ..amountText = '';
      expect(d.validate()[DraftField.amount], DraftError.renewalRequired);
    });

    test(
      'intro price needs an amount (zero allowed) and at least one period',
      () {
        final d = draft()
          ..intro = true
          ..introAmountText = ''
          ..introPeriodsText = '0';
        expect(d.validate()[DraftField.introAmount], DraftError.required);
        expect(d.validate()[DraftField.introPeriods], DraftError.periods);
        d
          ..introAmountText = '0'
          ..introPeriodsText = '1';
        expect(d.isValid, isTrue, reason: 'a free first period is a trial');
      },
    );
  });

  group('toNewItem', () {
    test('intro schedule: 3 months at 5, then 8', () {
      final item =
          (ItemDraft(
                  type: ItemType.bill,
                  currency: Currency.usd,
                  cycle: Cycle.monthly,
                  name: 'VPS',
                  amountText: '8',
                  nextCharge: LocalDate(2026, 4, 1),
                )
                ..intro = true
                ..introAmountText = '5'
                ..introPeriodsText = '3')
              .toNewItem();
      expect(
        item.prices,
        PriceSchedule.intro(
          intro: const Money(500, Currency.usd),
          periods: 3,
          renewal: const Money(800, Currency.usd),
        ),
      );
      expect(item.anchor, LocalDate(2026, 4, 1));
      expect(item.paidUntil, LocalDate(2026, 4, 1));
    });

    test('drops empty type fields; sharing splits the total evenly', () {
      final d =
          ItemDraft(
              type: ItemType.subscription,
              currency: Currency.twd,
              cycle: Cycle.monthly,
              name: 'Netflix',
              amountText: '390',
              nextCharge: LocalDate(2026, 4, 1),
              fields: {'plan': 'premium', 'cancelUrl': ''},
            )
            ..sharing = true
            ..sharingPeople = 4
            ..sharingTotalText = '390'
            ..members = [SharingMember(name: 'Amy', paid: true)];
      final item = d.toNewItem();
      expect(item.typeFields, {'plan': 'premium'});
      expect(item.sharing!['people'], 4);
      expect(item.sharing!['myShare'], 9750);
      expect(item.sharing!['members'], [
        {'name': 'Amy', 'paid': true},
      ]);
    });
  });
}
