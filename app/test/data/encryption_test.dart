import 'dart:convert';
import 'dart:io';

import 'package:cashrotate/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

const _key = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
const _otherKey =
    'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cashrotate_db_');
    file = File('${dir.path}/test.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> writeSecret(String key) async {
    final db = AppDatabase(openEncryptedDatabase(file, hexKey: key));
    await db
        .into(db.meta)
        .insert(MetaCompanion.insert(key: 'secret', value: 'hunter2'));
    await db.close();
  }

  test('the bundled SQLite is SQLite3MultipleCiphers', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    final version = db.select('SELECT sqlite3mc_version() AS v').single['v'];
    expect(version, contains('SQLite3 Multiple Ciphers'));
  });

  test('round-trips data with the right key', () async {
    await writeSecret(_key);
    final db = AppDatabase(openEncryptedDatabase(file, hexKey: _key));
    addTearDown(db.close);
    final row = await db.select(db.meta).getSingle();
    expect(row.value, 'hunter2');
  });

  test('the file on disk is not plain SQLite and hides its contents', () async {
    await writeSecret(_key);
    final bytes = file.readAsBytesSync();
    expect(
      ascii.decode(bytes.sublist(0, 15), allowInvalid: true),
      isNot('SQLite format 3'),
    );
    expect(latin1.decode(bytes).contains('hunter2'), isFalse);
  });

  test('a wrong key cannot open the database', () async {
    await writeSecret(_key);
    final db = AppDatabase(openEncryptedDatabase(file, hexKey: _otherKey));
    addTearDown(db.close);
    await expectLater(db.select(db.meta).get(), throwsA(isA<Object>()));
  });

  test('plain SQLite cannot read it either', () async {
    await writeSecret(_key);
    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(
      () => raw.select('SELECT * FROM meta'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects malformed keys before touching the file', () {
    expect(
      () => openEncryptedDatabase(file, hexKey: 'short'),
      throwsArgumentError,
    );
    expect(
      () => openEncryptedDatabase(file, hexKey: _key.toUpperCase()),
      throwsArgumentError,
    );
    expect(file.existsSync(), isFalse);
  });

  test('foreign keys are enforced', () async {
    final db = AppDatabase(openEncryptedDatabase(file, hexKey: _key));
    addTearDown(db.close);
    await expectLater(
      db.customStatement(
        'INSERT INTO occurrences '
        '(id, item_id, cycle_index, due_on, expected_minor, currency, state) '
        "VALUES ('x', 'missing', 0, '2026-01-01', 1, 'TWD', 'pending')",
      ),
      throwsA(isA<Object>()),
    );
    final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(pragma.data.values.first, 1);
  });
}
