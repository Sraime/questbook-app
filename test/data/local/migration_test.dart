import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// Migrations run on the phone of every existing player, on a database full of
/// characters they care about. These tests exercise them on a real file rather
/// than trusting them by inspection.
///
/// Rather than hand-copying drift's older DDL, the current schema is created
/// and then stripped back down, which keeps the fixtures honest even if the
/// surviving tables are edited later.
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

  /// Recreates the `game_tables` table exactly as schema versions 1 and 2 had
  /// it, since the current schema no longer declares it at all.
  void addLegacyGameTables(raw.Database db) {
    db.execute(
      'CREATE TABLE game_tables ('
      'id TEXT NOT NULL, '
      'title TEXT NOT NULL, '
      'universe_label TEXT NOT NULL, '
      'next_session INTEGER NULL, '
      'system_id TEXT NULL REFERENCES game_systems (id), '
      'PRIMARY KEY (id))',
    );
    db.execute(
      "INSERT INTO game_tables (id, title, universe_label) "
      "VALUES ('local-table', 'Les Inspecteurs Chavillois', 'Cthulhu')",
    );
  }

  /// Rewinds the file to what schema version 1 looked like and drops a legacy
  /// character into it.
  void downgradeToV1({required DateTime createdAt}) {
    final db = raw.sqlite3.open(dbPath);
    db.execute('ALTER TABLE characters DROP COLUMN updated_at');
    db.execute('ALTER TABLE characters DROP COLUMN deleted_at');
    db.execute('ALTER TABLE characters DROP COLUMN needs_sync');
    db.execute('DROP TABLE sync_metadata');
    addLegacyGameTables(db);

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

    expect(version.data.values.first, 3);
  });

  /// Rewinds the file to schema version 2, which still carried the local-only
  /// tables mockup.
  void downgradeToV2() {
    final db = raw.sqlite3.open(dbPath);
    addLegacyGameTables(db);
    db.execute('PRAGMA user_version = 2');
    db.close();
  }

  test('drops the local tables mockup when upgrading from v2', () async {
    downgradeToV2();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final remaining = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'game_tables'",
        )
        .get();

    expect(
      remaining,
      isEmpty,
      reason: 'game tables are now owned by the server, not the device',
    );
  });

  test('keeps characters and their sync state across the v2 upgrade', () async {
    downgradeToV2();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    // A v2 database created by the setUp fixture has no characters, so the
    // point here is simply that the upgrade leaves a working schema behind.
    await db.into(db.gameSystems).insert(
          GameSystemRow(
            id: 'call_of_cthulhu_classique',
            name: 'Classique',
            occupationSuggestions: '[]',
          ),
        );

    expect(await db.select(db.characters).get(), isEmpty);
    expect(await db.select(db.syncMetadata).get(), isEmpty);
  });

  test('upgrades straight from v1 to v3, mockup included', () async {
    downgradeToV1(createdAt: DateTime.utc(2025, 3, 14));

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final remaining = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'game_tables'",
        )
        .get();

    expect(version.data.values.first, 3);
    expect(remaining, isEmpty);
    expect(await db.select(db.characters).get(), hasLength(1));
  });
}
