import 'dart:io';

import 'package:cashrotate_core/cashrotate_core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Items,
    PricePhases,
    Occurrences,
    PriceHistory,
    Accounts,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    Attachments,
    Aliases,
    ReminderLog,
    ChangeLog,
    Meta,
    AppSettings,
    ExchangeRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump with every schema change, add a step below, and run
  /// `dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`
  /// so the migration test covers it.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2 (M2): synced settings, exchange rates, "to fill in" items.
      if (from < 2) {
        await m.createTable(appSettings);
        await m.createTable(exchangeRates);
        await m.addColumn(items, items.needsDetails);
        // Occurrences are identified by due date instead of charge number.
        await m.alterTable(TableMigration(occurrences));
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

final _hexKey = RegExp(r'^[0-9a-f]{64}$');

/// Opens [file] encrypted with SQLite3MultipleCiphers' ChaCha20-Poly1305
/// cipher, keyed with 32 random bytes given as lowercase hex.
///
/// A wrong key fails here (SQLITE_NOTADB) instead of at the first query.
QueryExecutor openEncryptedDatabase(File file, {required String hexKey}) {
  if (!_hexKey.hasMatch(hexKey)) {
    throw ArgumentError('Database key must be 64 lowercase hex characters');
  }
  return NativeDatabase.createInBackground(
    file,
    setup: (db) {
      db
        ..execute("PRAGMA cipher = 'chacha20'")
        ..execute("PRAGMA hexkey = '$hexKey'")
        ..select('SELECT count(*) FROM sqlite_master')
        ..execute('PRAGMA journal_mode = WAL');
    },
  );
}
