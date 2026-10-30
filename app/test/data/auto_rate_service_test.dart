import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/fx/auto_rate_service.dart';
import 'package:cashrotate/data/fx/exchange_rate_repository.dart';
import 'package:cashrotate/data/fx/rate_fetcher.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const erApiBody =
    '{"result":"success","base_code":"TWD","time_last_update_unix":1761696000,'
    '"rates":{"TWD":1,"USD":0.03068,"JPY":4.6812,"EUR":0.0281,"HKD":0.2389,"CNY":0.2185,"KRW":44.1}}';
const fawazBody = '{"date":"2026-10-29","twd":{"usd":0.0307,"jpy":4.68}}';

void main() {
  late AppDatabase db;
  late ExchangeRateRepository rates;
  late SettingsRepository settings;
  var today = LocalDate(2026, 10, 30);
  var requests = <Uri>[];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final journal = Journal(db);
    rates = ExchangeRateRepository(db, journal, today: () => today);
    settings = SettingsRepository(db, journal);
    await settings.setRegion('TW');
    await settings.setMainCurrency(Currency.twd);
    today = LocalDate(2026, 10, 30);
    requests = [];
  });
  tearDown(() => db.close());

  AutoRateService service({
    Entitlements entitlements = Entitlements.pro,
    Future<String> Function(Uri)? get,
  }) => AutoRateService(
    rates: rates,
    settings: settings,
    fetcher: RateFetcher(
      get: (uri) {
        requests.add(uri);
        return (get ?? (_) async => erApiBody)(uri);
      },
    ),
    entitlements: entitlements,
    today: () => today,
    defaults: UserSettings.defaultsFor('TW'),
  );

  Future<Map<String, ExchangeRate>> stored() async => {
    for (final r in await rates.watchRates().first) r.quote.code: r,
  };

  test('Pro (and the preview build) stores every fetched currency', () async {
    final result = await service().refresh();
    expect(result.status, AutoRateStatus.updated);
    expect(result.source, erApiSource);
    final all = await stored();
    expect(all.keys.toSet(), {'USD', 'JPY', 'EUR', 'HKD', 'CNY', 'KRW'});
    expect(all['USD']!.base, Currency.twd);
    expect(all['USD']!.source, erApiSource);
    final fx = await rates.converter();
    // 1 TWD = 0.03068 USD, so US$20 ≈ NT$651.89.
    expect(
      fx.convert(const Money(2000, Currency.usd), Currency.twd)!.amount,
      const Money(65189, Currency.twd),
    );
  });

  test('free tier stores only its 4 currencies (defaults: USD, EUR, JPY, CNY in Taiwan)', () async {
    await service(entitlements: Entitlements.free).refresh();
    expect((await stored()).keys.toSet(), {'USD', 'EUR', 'JPY', 'CNY'});
  });

  test('free tier honours a chosen set', () async {
    await settings.setAutoRateCurrencies([Currency.krw, Currency.hkd]);
    await service(entitlements: Entitlements.free).refresh();
    expect((await stored()).keys.toSet(), {'KRW', 'HKD'});
  });

  test('downloads at most once a day unless forced', () async {
    final s = service();
    expect((await s.refresh()).status, AutoRateStatus.updated);
    expect((await s.refresh()).status, AutoRateStatus.alreadyToday);
    expect(requests, hasLength(1));
    expect((await s.refresh(force: true)).status, AutoRateStatus.updated);
    today = today.addDays(1);
    expect((await s.refresh()).status, AutoRateStatus.updated);
    expect(requests, hasLength(3));
  });

  test('falls back to currency-api when open.er-api.com fails', () async {
    final result = await service(
      get: (uri) async {
        if (uri.host == 'open.er-api.com') throw Exception('offline');
        return fawazBody;
      },
    ).refresh();
    expect(result.status, AutoRateStatus.updated);
    expect(result.source, fawazSource);
    expect((await stored())['USD']!.source, fawazSource);
  });

  test(
    'when every source fails, the cached rates stay and the result says so',
    () async {
      await service().refresh();
      today = today.addDays(1);
      final result = await service(get: (_) async => throw Exception('offline'))
          .refresh();
      expect(result.status, AutoRateStatus.failed);
      expect(result.error, isA<RateFetchException>());
      expect((await stored())['USD']!.rate.toDecimalString(), '0.03068');
      expect(
        await rates.lastFetchedOn(),
        LocalDate(2026, 10, 30),
        reason: 'retry tomorrow',
      );
    },
  );

  test('automatic rates replace a manual rate for the same pair', () async {
    await rates.setManualRate(
      Currency.usd,
      Currency.twd,
      Ratio.tryParse('32')!,
    );
    await service().refresh();
    final list = await rates.watchRates().first;
    final usd = list
        .where((r) => r.base == Currency.usd || r.quote == Currency.usd)
        .toList();
    expect(usd, hasLength(1), reason: 'one row per pair');
    expect(usd.single.source, erApiSource);
  });

  test('unchanged rates are not journaled again', () async {
    await service().refresh();
    final before = (await db.select(db.changeLog).get()).length;
    await service().refresh(force: true);
    expect((await db.select(db.changeLog).get()).length, before);
  });
}
