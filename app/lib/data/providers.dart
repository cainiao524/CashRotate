import 'dart:io';
import 'dart:ui';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sodium/sodium_sumo.dart';

import '../platform/files.dart';
import '../platform/home_widgets.dart';
import '../platform/keystore.dart';
import '../platform/links.dart';
import '../platform/screen_privacy.dart';
import '../platform/shortcuts.dart';
import '../platform/tilt.dart';
import 'backup/backup_service.dart';
import 'db/app_database.dart';
import 'detection/detection_service.dart';
import 'detection/notice_platform.dart';
import 'entitlements.dart';
import 'fx/auto_rate_service.dart';
import 'fx/exchange_rate_repository.dart';
import 'fx/rate_fetcher.dart';
import 'items/item_repository.dart';
import 'journal.dart';
import 'payments/payment_repository.dart';
import 'reminders/reminder_platform.dart';
import 'reminders/reminder_service.dart';
import 'security/app_lock.dart';
import 'settings/settings_repository.dart';
import 'sync/conflict_resolver.dart';
import 'sync/sync_service.dart';

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

final rateFetcherProvider = Provider<RateFetcher>((ref) => RateFetcher());

final autoRateServiceProvider = Provider<AutoRateService>((ref) {
  final clock = ref.watch(clockProvider);
  return AutoRateService(
    rates: ref.watch(exchangeRateRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    fetcher: ref.watch(rateFetcherProvider),
    entitlements: ref.watch(entitlementsProvider),
    today: () => todayFrom(clock),
    defaults: UserSettings.defaultsFor(ref.watch(systemRegionProvider)),
  );
});

/// Downloads today's rates once the database is open (at most once a day;
/// failures keep the cached rates). Watched by the app shell.
final autoRateStartupProvider = FutureProvider<AutoRateResult>(
  (ref) => ref.watch(autoRateServiceProvider).refresh(),
);

/// The native reminder scheduler; replaced by a fake in tests.
final reminderPlatformProvider = Provider<ReminderPlatform>(
  (ref) => MethodChannelReminderPlatform(),
);

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(itemRepositoryProvider),
    ref.watch(reminderPlatformProvider),
    ref.watch(clockProvider),
    payments: ref.watch(paymentRepositoryProvider),
  );
});

/// libsodium (sumo: Argon2id), loaded once.
/// Settles sync conflicts: keep an item deleted, or bring it back.
final conflictResolverProvider = Provider<ConflictResolver>(
  (ref) => ConflictResolver(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    ref.watch(itemRepositoryProvider),
  ),
);

final sodiumProvider = FutureProvider<SodiumSumo>(
  (ref) => SodiumSumoInit.init(),
);

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  return SyncService(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    await ref.watch(sodiumProvider.future),
  );
});

/// This device's sync connection, or null when not set up.
final syncConfigProvider = StreamProvider<SyncConfig?>((ref) async* {
  final service = await ref.watch(syncServiceProvider.future);
  yield* service.watchConfig();
});

final appLockRepositoryProvider = FutureProvider<AppLockRepository>(
  (ref) async => AppLockRepository(
    ref.watch(appDatabaseProvider).requireValue,
    await ref.watch(sodiumProvider.future),
  ),
);

/// The app lock on this device, or null when it is off.
final appLockConfigProvider = StreamProvider<AppLockConfig?>((ref) async* {
  final repo = await ref.watch(appLockRepositoryProvider.future);
  yield* repo.watch();
});

/// Fingerprint / face; replaced by a fake in tests.
final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => LocalBiometricAuth(),
);

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return BackupService(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    await ref.watch(sodiumProvider.future),
    Directory('${dir.path}/backups'),
    now: ref.watch(clockProvider),
  );
});

/// Today's automatic backup, in the background once the database is open.
final autoBackupProvider = FutureProvider<bool>(
  (ref) async => (await ref.watch(backupServiceProvider.future)).backUpIfDue(),
);

/// Save and open dialogs for backup files; faked in tests.
final filePickerProvider = Provider<FilePicker>((ref) => SystemFilePicker());

final linkOpenerProvider = Provider<LinkOpener>((ref) => SystemLinkOpener());

final tiltSourceProvider = Provider<TiltSource>((ref) => SystemTiltSource());

final screenPrivacyProvider = Provider<ScreenPrivacy>(
  (ref) => SystemScreenPrivacy(),
);

final shortcutPlatformProvider = Provider<ShortcutPlatform>(
  (ref) => SystemShortcuts(),
);

final homeWidgetPlatformProvider = Provider<HomeWidgetPlatform>(
  (ref) => SystemHomeWidgets(),
);

final paymentMethodsProvider = Provider<PaymentMethods>(
  (ref) => PaymentMethods(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
  ),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
    ref.watch(itemRepositoryProvider),
    ref.watch(paymentMethodsProvider),
  ),
);

/// Payment methods to choose from (not archived, not "unassigned").
final paymentMethodListProvider = StreamProvider<List<AccountRow>>(
  (ref) => ref.watch(paymentMethodsProvider).watchAll(),
);

/// The native notification listener; faked in tests.
final noticePlatformProvider = Provider<NoticePlatform>(
  (ref) => MethodChannelNoticePlatform(),
);

final detectionServiceProvider = Provider<DetectionService>(
  (ref) => DetectionService(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(itemRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
    ref.watch(noticePlatformProvider),
  ),
);

final detectionSettingsProvider = StreamProvider<DetectionSettings>(
  (ref) => ref.watch(detectionServiceProvider).watchSettings(),
);

/// Charges read from notifications, newest first.
final detectionsProvider = StreamProvider<List<Detection>>(
  (ref) => ref.watch(detectionServiceProvider).watch(),
);
