import 'dart:convert';

import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';
import 'backup_page_test.dart' show FakePicker;

Future<void> openReports(WidgetTester tester) async {
  await tester.tap(find.text('Reports').first);
  await settle(tester);
}

String moneyAt(WidgetTester tester, Key key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .data!;

void main() {
  testApp('overview: this month, last 12 months, categories', (tester) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openReports(tester);
    expect(moneyAt(tester, const Key('reports-monthly-total')), r'NT$18,752');
    // March: Netflix at my share (NT$97.50) and ChatGPT (US$20 × 32.59).
    expect(moneyAt(tester, const Key('month-bars-value')), r'NT$749');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('category-housing')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Housing'), findsOneWidget);
  });

  testApp('price changes show the difference', (tester) async {
    await pumpApp(
      tester,
      seed: (d) async {
        final ids = await d.seedItems();
        await d.items.changePrice(
          ids['rent']!,
          fromIndex: 2,
          amount: const Money(1980000, Currency.twd),
        );
      },
    );
    await openReports(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('price-change-0')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(r'NT$18,000 → NT$19,800'), findsOneWidget);
    expect(find.text(r'+NT$1,800 (+10%)'), findsOneWidget);
  });

  testApp("month calendar lists a day's charges; year opens a month", (
    tester,
  ) async {
    await pumpApp(tester, seed: (d) => d.seedItems());
    await openReports(tester);
    await tester.tap(find.byKey(const Key('reports-tab-month')));
    await settle(tester);
    expect(find.text('March 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-day-18')));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Netflix'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reports-tab-year')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('year-month-4')));
    await settle(tester);
    expect(find.text('April 2026'), findsOneWidget);
  });

  testApp('export payments as CSV', (tester) async {
    final picker = FakePicker();
    await pumpApp(
      tester,
      overrides: [filePickerProvider.overrideWithValue(picker)],
      seed: (d) async {
        final ids = await d.seedItems();
        final payments = PaymentRepository(
          d.db,
          d.journal,
          d.items,
          PaymentMethods(d.db, d.journal),
        );
        await payments.record(
          itemId: ids['rent']!,
          expected: const Money(1800000, Currency.twd),
          paid: const Money(1800000, Currency.twd),
          paidOn: LocalDate(2026, 3, 5),
          main: Currency.twd,
          note: 'March, "early"',
        );
      },
    );
    await openReports(tester);
    await tester.tap(find.byKey(const Key('reports-export')));
    await settle(tester);
    expect(picker.savedName, 'CashRotate-payments-2026-03-15.csv');
    final csv = utf8.decode(picker.saved!.sublist(3));
    final lines = csv.trim().split('\n');
    expect(lines.first, startsWith('date,item,amount,currency'));
    expect(lines[1], startsWith('2026-03-05,Rent,18000.00,TWD'));
    expect(lines[1], endsWith('"March, ""early"""'));
    expect(find.text('Payments exported'), findsOneWidget);
  });
}
