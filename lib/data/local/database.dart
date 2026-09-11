import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('GameSystemRow')
class GameSystems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// JSON-encoded `List<String>` of suggested occupations for this system.
  TextColumn get occupationSuggestions => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CharacterRow')
class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get systemId => text().references(GameSystems, #id)();
  TextColumn get name => text()();
  TextColumn get occupation => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  /// Drives last-write-wins against the API: every local mutation bumps it,
  /// and the server keeps whichever side carries the later value.
  /// The epoch default only exists so the v1 → v2 `ALTER TABLE ADD COLUMN`
  /// stays a constant expression; the migration immediately backfills it
  /// from [createdAt].
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  /// Tombstone. Rows are kept after a delete so the deletion can be pushed to
  /// the API and replicated to the user's other devices.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Set on every local write, cleared once the API has acknowledged the push.
  /// Defaults to true so characters created before this feature existed are
  /// uploaded on the first sign-in.
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value store for synchronisation bookkeeping: the incremental pull
/// cursor and the id of the account the local data belongs to.
@DataClassName('SyncMetadataRow')
class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The last answer the API gave for a given request, kept so the tables tab
/// still has something to show without a network.
///
/// Deliberately opaque: the payload is the raw JSON envelope, replayed through
/// the very same `fromJson` the live path uses. Mirroring the server's shape
/// into columns would mean migrating this table every time the API grows a
/// field, for a cache that is only ever read.
@DataClassName('RemoteCacheRow')
class RemoteCache extends Table {
  TextColumn get key => text()();

  /// The account the entry belongs to. Another user signing in on the device
  /// must never be shown the previous one's tables.
  TextColumn get accountId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Stores 'characteristic' or 'skill' — see domain/models/character_stat.dart's
/// StatKind, mapped to/from this text value in LocalCharacterRepository.
@DataClassName('CharacterStatRow')
class CharacterStats extends Table {
  TextColumn get id => text()();
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get key => text()();
  TextColumn get label => text()();
  IntColumn get value => integer()();
  TextColumn get base => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores the resource's tone as text ('neutral'/'danger'/…) — see
/// domain/models/tone.dart's Tone, mapped in LocalCharacterRepository.
@DataClassName('CharacterResourceRow')
class CharacterResources extends Table {
  TextColumn get id => text()();
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get key => text()();
  TextColumn get label => text()();
  IntColumn get current => integer()();
  IntColumn get max => integer()();
  TextColumn get tone => text().withDefault(const Constant('neutral'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get weight => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    GameSystems,
    Characters,
    CharacterStats,
    CharacterResources,
    InventoryItems,
    SyncMetadata,
    RemoteCache,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'questbook'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(characters, characters.updatedAt);
            await m.addColumn(characters, characters.deletedAt);
            await m.addColumn(characters, characters.needsSync);
            await m.createTable(syncMetadata);
            // Characters that predate synchronisation have never been edited
            // as far as the API is concerned, so their creation date is the
            // most honest "last modified" value available.
            await customStatement(
              'UPDATE characters SET updated_at = created_at',
            );
          }
          if (from < 3) {
            // Tables became a shared, server-owned feature: they are no longer
            // stored on the device at all. The rows held nothing but a local
            // mockup, so there is nothing to migrate out of them.
            await m.deleteTable('game_tables');
          }
          if (from < 4) {
            // Tables come back to the device, but as a read-only copy of what
            // the server last said — not as the local mockup dropped in v3.
            await m.createTable(remoteCache);
          }
        },
      );
}
