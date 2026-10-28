import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../platform/keystore.dart';
import 'db/app_database.dart';
import 'items/item_repository.dart';
import 'journal.dart';

final databaseKeySourceProvider = Provider<DatabaseKeySource>(
  (ref) => const AndroidKeystoreKeySource(),
);

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
  await ItemRepository(db, Journal(db)).refreshAll();
  return db;
});

final journalProvider = Provider<Journal>(
  (ref) => Journal(ref.watch(appDatabaseProvider).requireValue),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(
    ref.watch(appDatabaseProvider).requireValue,
    ref.watch(journalProvider),
  ),
);
