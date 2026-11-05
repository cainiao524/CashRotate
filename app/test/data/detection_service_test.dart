import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/detection/detection_service.dart';
import 'package:cashrotate/data/detection/notice_platform.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/payments/payment_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notice_platform.dart';

void main() {
  final today = LocalDate(2026, 3, 15);
  late AppDatabase db;
  late ItemRepository items;
  late PaymentRepository payments;
  late FakeNoticePlatform platform;
  late DetectionService service;
  final fx = FxConverter(const []);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final journal = Journal(db);
    items = ItemRepository(db, journal, today: () => today);
    final methods = PaymentMethods(db, journal);
    payments = PaymentRepository(db, journal, items, methods);
    platform = FakeNoticePlatform();
    service = DetectionService(db, items, payments, platform);
  });
  tearDown(() => db.close());

  Future<String> netflix() => items.create(
    NewItem(
      type: ItemType.subscription,
      name: 'Netflix',
      cycle: Cycle.monthly,
      anchor: LocalDate(2026, 3, 18),
      prices: PriceSchedule.fixed(const Money(39000, Currency.twd)),
    ),
  );

  Future<Detection?> process(String text, DateTime at) => service.process(
    Notice(source: 'com.bank.app', text: text, postedAt: at),
    region: 'TW',
    main: Currency.twd,
    fx: fx,
    presets: null,
  );

  test('a confident match is paid automatically, and can be undone', () async {
    final id = await netflix();
    final d = await process(
      '您的信用卡於 3/18 在 NETFLIX.COM 消費新臺幣390元',
      DateTime(2026, 3, 18, 9),
    );
    expect(d!.status, DetectionStatus.auto);
    expect(d.itemId, id);
    expect((await items.view(id)).nextDue!.dueOn, LocalDate(2026, 4, 18));
    expect(await payments.watchForItem(id).first, hasLength(1));

    await service.undo(d.id);
    expect((await items.view(id)).nextDue!.dueOn, LocalDate(2026, 3, 18));
    expect(await payments.watchForItem(id).first, isEmpty);
    expect((await service.list()).single.status, DetectionStatus.undone);
  });

  test('an unsure match waits; assigning it records the payment', () async {
    final id = await netflix();
    final d = await process('信用卡消費 NT\$390', DateTime(2026, 3, 19, 9));
    expect(d!.status, DetectionStatus.pending);
    expect(d.itemId, id, reason: 'best guess shown to the user');
    await service.assign(d.id, id, main: Currency.twd, fx: fx);
    expect((await service.list()).single.status, DetectionStatus.assigned);
    expect((await items.view(id)).nextDue!.dueOn, LocalDate(2026, 4, 18));
  });

  test(
    'assigning teaches the merchant name; the next one matches by itself',
    () async {
      final id = await items.create(
        NewItem(
          type: ItemType.bill,
          name: '家裡網路',
          cycle: Cycle.monthly,
          anchor: LocalDate(2026, 3, 18),
          prices: PriceSchedule.fixed(const Money(59900, Currency.twd)),
        ),
      );
      final first = await process(
        '您的信用卡於 3/18 在 HINET 消費新臺幣599元',
        DateTime(2026, 3, 18, 9),
      );
      expect(first!.status, isNot(DetectionStatus.auto));
      await service.assign(first.id, id, main: Currency.twd, fx: fx);
      expect(learnedMerchants(await items.view(id)), ['HINET']);

      final next = await process(
        '您的信用卡於 4/18 在 HINET 消費新臺幣599元',
        DateTime(2026, 4, 18, 9),
      );
      expect(next!.status, DetectionStatus.auto);
      expect(next.itemId, id);
    },
  );

  test(
    'a repeated notification is handled once; non-charges are skipped',
    () async {
      await netflix();
      final at = DateTime(2026, 3, 18, 9);
      const text = '在 NETFLIX.COM 消費新臺幣390元';
      expect(await process(text, at), isNotNull);
      expect(await process(text, at.add(const Duration(minutes: 2))), isNull);
      expect(await process('您的帳戶轉入 NT\$50,000', at), isNull);
    },
  );

  test(
    'unmatched monthly charges become new-subscription suggestions',
    () async {
      await process('在 Notion Labs 消費 US\$10.00', DateTime(2026, 2, 3));
      await process('在 Notion Labs 消費 US\$10.00', DateTime(2026, 3, 3));
      final list = await service.list();
      expect(list.every((d) => d.status == DetectionStatus.unmatched), isTrue);
      expect(service.suggestions(list).single.merchant, 'Notion Labs');
    },
  );

  test(
    'settings go to the native listener; shared text is processed too',
    () async {
      await service.setSettings(
        const DetectionSettings(enabled: true, packages: ['com.bank.app']),
      );
      expect(platform.enabled, isTrue);
      expect(platform.packages, ['com.bank.app']);

      final id = await netflix();
      platform.shared = '【銀行】您於NETFLIX.COM消費新臺幣390元';
      final created = await service.processWaiting(
        region: 'TW',
        main: Currency.twd,
        fx: fx,
        presets: null,
      );
      expect(created.single.source, Notice.shared);
      expect(created.single.itemId, id);
    },
  );
}
