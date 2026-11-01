import 'dart:convert';
import 'dart:io';

import 'package:cashrotate/app.dart';
import 'package:cashrotate/data/db/app_database.dart';
import 'package:cashrotate/data/entitlements.dart';
import 'package:cashrotate/data/fx/auto_rate_service.dart';
import 'package:cashrotate/data/fx/exchange_rate_repository.dart';
import 'package:cashrotate/data/fx/rate_fetcher.dart';
import 'package:cashrotate/data/items/item_repository.dart';
import 'package:cashrotate/data/journal.dart';
import 'package:cashrotate/data/presets.dart';
import 'package:cashrotate/data/providers.dart';
import 'package:cashrotate/data/settings/settings_repository.dart';
import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meta/meta.dart';

import 'fake_reminder_platform.dart';

/// Golden matrix required by CLAUDE.md: widths × text scales × brightness.
const goldenWidths = [360.0, 411.0, 600.0, 840.0, 1280.0];
const goldenTextScales = [1.0, 1.3, 2.0];
const goldenBrightnesses = [Brightness.light, Brightness.dark];

/// The bundled preset library, parsed once from the asset file. Loading it
/// through rootBundle in each widget test stalls after the first test (the
/// bundle caches a future across fake-async zones).
final PresetLibrary testPresetLibrary = PresetLibrary([
  for (final p in jsonDecode(
    File('assets/presets/presets.json').readAsStringSync(),
  ) as List<Object?>)
    Preset.fromJson(p),
]);

/// What the exchange-rate sources answer in widget tests; offline by default.
/// A test may replace it (and should restore it with addTearDown).
Future<String> Function(Uri uri) testRateResponses = _offline;

Future<String> _offline(Uri uri) => throw Exception('offline in tests');

/// Every test runs on this date so due dates and goldens are stable.
final testNow = DateTime(2026, 3, 15, 10);
final testToday = LocalDate(2026, 3, 15);

/// Representative window height for each golden width (phone, large phone,
/// unfolded inner screen, small tablet, tablet landscape).
double _heightFor(double width) => switch (width) {
  360 => 760,
  840 => 900,
  1280 => 800,
  _ => 880,
};

/// Repositories over a test database, with the fixed test clock.
class TestData {
  TestData(this.db)
    : journal = Journal(db, nowMillis: () => testNow.millisecondsSinceEpoch) {
    items = ItemRepository(
      db,
      journal,
      today: () => testToday,
      nowMillis: () => testNow.millisecondsSinceEpoch,
    );
    settings = SettingsRepository(
      db,
      journal,
      nowMillis: () => testNow.millisecondsSinceEpoch,
    );
    rates = ExchangeRateRepository(
      db,
      journal,
      today: () => testToday,
      nowMillis: () => testNow.millisecondsSinceEpoch,
    );
  }

  final AppDatabase db;
  final Journal journal;
  late final ItemRepository items;
  late final SettingsRepository settings;
  late final ExchangeRateRepository rates;

  /// A realistic mix for list, detail and summary screens: local and foreign
  /// prices, an intro price, a yearly item, and one still to fill in.
  Future<Map<String, String>> seedItems() async {
    Money twd(int dollars) => Money(dollars * 100, Currency.twd);
    Money usd(int cents) => Money(cents, Currency.usd);
    await rates.setManualRate(
      Currency.usd,
      Currency.twd,
      Ratio.tryParse('32.59')!,
    );
    return {
      'netflix': await items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'Netflix',
          presetId: 'netflix',
          categoryId: 'streaming',
          cycle: Cycle.monthly,
          anchor: LocalDate(2026, 3, 18),
          prices: PriceSchedule.fixed(twd(390)),
          typeFields: {'plan': 'standard'},
          sharing: {'people': 4, 'myShare': 9750, 'members': <Object?>[]},
        ),
      ),
      'chatgpt': await items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'ChatGPT',
          presetId: 'chatgpt',
          categoryId: 'ai',
          cycle: Cycle.monthly,
          anchor: LocalDate(2026, 3, 20),
          prices: PriceSchedule.fixed(usd(2000)),
        ),
      ),
      'domain': await items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'example.com',
          presetId: 'cloudflare-registrar',
          categoryId: 'domain',
          cycle: Cycle.yearly,
          anchor: LocalDate(2026, 6, 1),
          prices: PriceSchedule.intro(
            intro: usd(100),
            periods: 1,
            renewal: usd(1500),
          ),
          typeFields: {'domain': 'example.com', 'autoRenew': true},
        ),
      ),
      'rent': await items.create(
        NewItem(
          type: ItemType.bill,
          name: 'Rent',
          presetId: 'template-rent',
          categoryId: 'housing',
          cycle: Cycle.monthly,
          anchor: LocalDate(2026, 4, 5),
          prices: PriceSchedule.fixed(twd(18000)),
        ),
      ),
      'spotify': await items.create(
        NewItem(
          type: ItemType.subscription,
          name: 'Spotify',
          presetId: 'spotify',
          categoryId: 'music',
          cycle: Cycle.monthly,
          anchor: testToday,
          prices: PriceSchedule.fixed(twd(0)),
          needsDetails: true,
        ),
      ),
    };
  }
}

/// Sets the test window and system settings, then pumps the whole app over
/// an in-memory database. Returns the data handle for seeding and checks.
///
/// [onboarded] false starts at first-launch setup. [seed] fills the
/// database (after settings) before the first frame.
Future<TestData> pumpApp(
  WidgetTester tester, {
  double width = 411,
  double? height,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en', 'US'),
  bool disableAnimations = false,
  bool onboarded = true,
  String region = 'TW',
  Future<void> Function(TestData data)? seed,
  Entitlements? entitlements,
  FakeReminderPlatform? reminders,
  List<Override> overrides = const [],
}) async {
  final view = tester.view;
  final dispatcher = tester.platformDispatcher;
  view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height ?? _heightFor(width));
  dispatcher
    ..textScaleFactorTestValue = textScale
    ..platformBrightnessTestValue = brightness
    ..localesTestValue = [locale]
    ..accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: disableAnimations,
    );
  addTearDown(view.reset);
  addTearDown(dispatcher.clearAllTestValues);

  // Unencrypted in-memory database instead of Keystore + SQLCipher file.
  final db = AppDatabase(NativeDatabase.memory());
  final data = TestData(db);
  await tester.runAsync(() async {
    await data.settings.setRegion(region);
    await data.settings.setMainCurrency(CurrencyInfo.forRegion(region));
    if (onboarded) await data.settings.setOnboardingDone();
    await seed?.call(data);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => db),
        clockProvider.overrideWithValue(() => testNow),
        systemRegionProvider.overrideWithValue(region),
        presetLibraryProvider.overrideWith((ref) async => testPresetLibrary),
        // Never touch the network: "Update now" uses [testRateResponses];
        // the automatic startup download is skipped.
        rateFetcherProvider.overrideWithValue(
          RateFetcher(get: (uri) async => testRateResponses(uri)),
        ),
        autoRateStartupProvider.overrideWith(
          (ref) async => (
            status: AutoRateStatus.alreadyToday,
            asOf: null,
            source: null,
            error: null,
          ),
        ),
        if (entitlements != null)
          entitlementsProvider.overrideWithValue(entitlements),
        reminderPlatformProvider.overrideWithValue(
          reminders ?? FakeReminderPlatform(),
        ),
        // No automatic backup files in widget tests.
        autoBackupProvider.overrideWith((ref) async => false),
        ...overrides,
      ],
      child: const CashRotateApp(),
    ),
  );
  // Long enough for the home page's entrance (tiles, rings, count-up, pearl
  // sheen) to finish before a test looks or a golden is taken.
  await settle(tester, frames: 18);
  return data;
}

/// [testWidgets] for tests that use [pumpApp]: unmounts the app at the end
/// of the body and flushes the zero-length timer drift schedules when its
/// stream queries are cancelled (the framework checks for pending timers
/// before tear-down callbacks would run).
@isTest
void testApp(
  String description,
  Future<void> Function(WidgetTester tester) body, {
  Object? tags,
  bool? skip,
}) => testWidgets(
  description,
  (tester) async {
    await body(tester);
    // Unmount, then advance fake time so drift's deferred stream-query
    // cleanup runs. The in-memory database is left for the GC: closing it
    // would wait on work tied to the fake-async zone.
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
  },
  tags: tags,
  skip: skip,
);

/// Pumps until [finder] matches (e.g. after the preset library loads from
/// the asset bundle, which happens in real async), failing after [maxFrames].
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 60,
}) async {
  for (var i = 0; i < maxFrames; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await settle(tester, frames: 1);
  }
  expect(finder, findsWidgets);
}

/// Lets database streams deliver and frames build. Not pumpAndSettle:
/// overflowing MarqueeText animates forever by design.
Future<void> settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}
