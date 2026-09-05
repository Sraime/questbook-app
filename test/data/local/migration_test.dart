import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// The v1 → v2 migration runs on the phone of every existing player, on a
/// database full of characters they care about. These tests exercise it on a
/// real file rather than trusting it by inspection.
///
/// Rather than hand-copying drift's v1 DDL, the v2 schema is created and then
/// stripped back down to v1, which keeps the fixture honest even if the older
/// tables are edited later.
void main() {
  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('questbook_migration');
    dbPath = '${tempDir.path}/questbook.sqlite';

    final fresh = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    await fresh.customSelect('SELECT 1').get();
    await fresh.close();
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// Rewinds the file to what schema version 1 looked like and drops a legacy
  /// character into it.
  void downgradeToV1({required DateTime createdAt}) {
    final db = raw.sqlite3.open(dbPath);
    db.execute('ALTER TABLE characters DROP COLUMN updated_at');
    db.execute('ALTER TABLE characters DROP COLUMN deleted_at');
    db.execute('ALTER TABLE characters DROP COLUMN needs_sync');
    db.execute('DROP TABLE sync_metadata');

    db.execute(
      "INSERT INTO game_systems (id, name, occupation_suggestions) "
      "VALUES ('call_of_cthulhu_classique', 'Classique', '[]')",
    );
    db.execute(
      'INSERT INTO characters (id, system_id, name, occupation, description, '
      'level, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        'legacy-character',
        'call_of_cthulhu_classique',
        'Ernest Blackwood',
        'Antiquaire',
        null,
        3,
        createdAt.millisecondsSinceEpoch ~/ 1000,
      ],
    );

    db.execute('PRAGMA user_version = 1');
    db.close();
  }

  test('upgrades a v1 database without losing its characters', () async {
    final createdAt = DateTime.utc(2025, 3, 14, 10, 30);
    downgradeToV1(createdAt: createdAt);

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final characters = await db.select(db.characters).get();
    expect(characters, hasLength(1));

    final character = characters.single;
    expect(character.name, 'Ernest Blackwood');
    expect(character.occupation, 'Antiquaire');
    expect(character.level, 3);
  });

  test('backfills updatedAt from createdAt instead of leaving it at the epoch',
      () async {
    final createdAt = DateTime.utc(2025, 3, 14, 10, 30);
    downgradeToV1(createdAt: createdAt);

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final character = (await db.select(db.characters).get()).single;

    expect(
      character.updatedAt.toUtc(),
      createdAt,
      reason: 'a pre-sync character has never been modified, so its creation '
          'date is its last-modified date',
    );
    expect(character.updatedAt.millisecondsSinceEpoch, isNot(0));
  });

  test('queues pre-existing characters for upload on the first sign-in',
      () async {
    downgradeToV1(createdAt: DateTime.utc(2025, 3, 14));

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final character = (await db.select(db.characters).get()).single;

    expect(character.needsSync, isTrue);
    expect(character.deletedAt, isNull);
  });

  test('creates the sync metadata table', () async {
    downgradeToV1(createdAt: DateTime.utc(2025, 3, 14));

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    await db
        .into(db.syncMetadata)
        .insert(SyncMetadataRow(key: 'sync.cursor', value: 'value'));

    expect(await db.select(db.syncMetadata).get(), hasLength(1));
  });

  test('a fresh install starts directly at the current schema version',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();

    expect(version.data.values.first, 2);
  });
}
