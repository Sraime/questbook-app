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

  /// Every version up to 7 predates the local revision counter, so each
  /// fixture below has to take it back off.
  void dropRevision(raw.Database db) {
    db.execute('ALTER TABLE characters DROP COLUMN revision');
  }

  /// Rewinds the file to what schema version 1 looked like and drops a legacy
  /// character into it.
  void downgradeToV1({required DateTime createdAt}) {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('ALTER TABLE characters DROP COLUMN updated_at');
    db.execute('ALTER TABLE characters DROP COLUMN deleted_at');
    db.execute('ALTER TABLE characters DROP COLUMN needs_sync');
    db.execute('DROP TABLE sync_metadata');
    db.execute('DROP TABLE remote_cache');
    db.execute('DROP TABLE session_boards');
    db.execute('DROP TABLE downloaded_scenarios');
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

    expect(version.data.values.first, 8);
  });

  /// Rewinds the file to schema version 2, which still carried the local-only
  /// tables mockup.
  void downgradeToV2() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('DROP TABLE remote_cache');
    db.execute('DROP TABLE session_boards');
    db.execute('DROP TABLE downloaded_scenarios');
    addLegacyGameTables(db);
    db.execute('PRAGMA user_version = 2');
    db.close();
  }

  /// Rewinds to schema version 3: tables gone from the device entirely, before
  /// they came back as a read-only cache.
  void downgradeToV3() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('DROP TABLE remote_cache');
    db.execute('DROP TABLE session_boards');
    db.execute('DROP TABLE downloaded_scenarios');
    db.execute('PRAGMA user_version = 3');
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

  test('opens the tables cache when upgrading from v3', () async {
    downgradeToV3();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    await db.into(db.remoteCache).insert(
          RemoteCacheRow(
            key: 'tables.overview',
            accountId: 'account-1',
            payload: '{"tables":[]}',
            fetchedAt: DateTime.utc(2025, 9, 12),
          ),
        );

    expect(await db.select(db.remoteCache).get(), hasLength(1));
  });

  test('upgrades straight from v1 to v8, mockup dropped and cache opened',
      () async {
    downgradeToV1(createdAt: DateTime.utc(2025, 3, 14));

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    final mockup = await db
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'game_tables'",
        )
        .get();

    expect(version.data.values.first, 8);
    expect(mockup, isEmpty);
    expect(await db.select(db.remoteCache).get(), isEmpty);
    expect(await db.select(db.downloadedScenarios).get(), isEmpty);
    expect(await db.select(db.characters).get(), hasLength(1));
  });

  void downgradeToV4() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('DROP TABLE session_boards');
    db.execute('DROP TABLE downloaded_scenarios');
    db.execute('PRAGMA user_version = 4');
    db.close();
  }

  test('opens the downloaded scenarios table when upgrading from v4', () async {
    downgradeToV4();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    expect(await db.select(db.downloadedScenarios).get(), isEmpty);
  });

  void downgradeToV5() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('DROP TABLE session_boards');
    db.execute('PRAGMA user_version = 5');
    db.close();
  }

  test('opens the game master boards table when upgrading from v5', () async {
    downgradeToV5();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    await db.into(db.sessionBoards).insert(
          SessionBoardRow(
            sessionId: 'session-1',
            accountId: 'account-1',
            tokens: '[]',
            notes: '',
            updatedAt: DateTime.utc(2026, 9, 19),
          ),
        );

    expect(await db.select(db.sessionBoards).get(), hasLength(1));
  });

  void downgradeToV6() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('ALTER TABLE session_boards DROP COLUMN map_id');
    db.execute('PRAGMA user_version = 6');
    db.close();
  }

  void downgradeToV7() {
    final db = raw.sqlite3.open(dbPath);
    dropRevision(db);
    db.execute('PRAGMA user_version = 7');
    db.close();
  }

  test('keeps the boards of a v6 install when adding the map column', () async {
    downgradeToV6();

    final before = raw.sqlite3.open(dbPath);
    before.execute(
      'INSERT INTO session_boards (session_id, account_id, tokens, notes, '
      'updated_at) VALUES (?, ?, ?, ?, ?)',
      ['session-1', 'account-1', '[]', 'Le phare clignote', 0],
    );
    before.close();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final rows = await db.select(db.sessionBoards).get();

    expect(rows, hasLength(1));
    expect(rows.single.notes, 'Le phare clignote');
    // Nulle, donc le catalogue choisira : une session d'avant la sÃ©lection de
    // carte ne doit pas s'ouvrir sur un plateau vide.
    expect(rows.single.mapId, isNull);
  });

  test('donne un compteur de rÃ©vision aux fiches dâ€™une installation en v7',
      () async {
    downgradeToV7();

    final before = raw.sqlite3.open(dbPath);
    before.execute(
      "INSERT INTO game_systems (id, name, occupation_suggestions) "
      "VALUES ('call_of_cthulhu_classique', 'Classique', '[]')",
    );
    before.execute(
      'INSERT INTO characters (id, system_id, name, level, created_at, '
      'updated_at, needs_sync) VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['perso-1', 'call_of_cthulhu_classique', 'Ernest', 1, 0, 0, 1],
    );
    before.close();

    final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    final character = (await db.select(db.characters).get()).single;

    expect(character.name, 'Ernest');
    // Le compteur ne vaut que comparÃ© Ã  lui-mÃªme : repartir de zÃ©ro pour
    // tout le monde ne perd rien, et la fiche reste en attente d'envoi.
    expect(character.revision, 0);
    expect(character.needsSync, isTrue);
  });
}
