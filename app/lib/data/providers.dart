import 'dart:io';
import 'dart:ui';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../platform/keystore.dart';
import 'db/app_database.dart';
import 'fx/exchange_rate_repository.dart';
import 'items/item_repository.dart';
import 'journal.dart';
import 'settings/settings_repository.dart';

final databaseKeySourceProvider = Provider<DatabaseKeySource>(
  (ref) => const AndroidKeystoreKeySource(),
);

/// Wall clock for everything that depends on "today". Overridden in tests so
/// dates (and golden images) do not change from day to day.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today in the device's time zone.
LocalDate todayFrom(DateTime Function() clock) =>
    LocalDate.fromDateTime(clock());

/// The encrypted local database, opened once at startup.
///
/// Opening also re-plans every item so the 12-month occurrence window is
/// current; M3 adds a daily background refresh.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final key = await ref.watch(databaseKeySourceProvider).databaseKeyHex();
  final dir = await getApplicationSupportDirectory();
  final db = AppDatabase(
    openEncryptedDatabase(File('${dir.path}/cashrotate.db'), hexKey: key),
  );
  ref.onDispose(db.close);
  final clock = ref.read(clockProvider);
  await ItemRepository(
    db,
    Journal(db),
    today: () => todayFrom(clock),
  ).refreshAll();
  return db;
});

final journalProvider = Provider<Journal>(
  (ref) => Journal(ref.watch(appDatabaseProvider).requireValue),
);

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final clock = ref.watch(clockProvider);
  return ItemRepository(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    today: () => todayFrom(clock),
    nowMillis: () => clock().millisecondsSinceEpoch,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
  ),
);

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  final clock = ref.watch(clockProvider);
  return ExchangeRateRepository(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    today: () => todayFrom(clock),
    nowMillis: () => clock().millisecondsSinceEpoch,
  );
});

/// Region of the device locale (e.g. `TW`), used until the user picks one.
final systemRegionProvider = Provider<String?>(
  (ref) => PlatformDispatcher.instance.locale.countryCode,
);

final userSettingsProvider = StreamProvider<UserSettings>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(UserSettings.defaultsFor(ref.watch(systemRegionProvider))),
);

final fxConverterProvider = StreamProvider<FxConverter>(
  (ref) => ref.watch(exchangeRateRepositoryProvider).watchConverter(),
);
