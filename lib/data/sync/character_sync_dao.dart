import 'package:drift/drift.dart';

import '../local/database.dart';
import '../remote/remote_character.dart';

/// Drift-side of the synchronisation: reads the aggregates waiting to be
/// pushed, applies the ones coming back from the API, and keeps the pull
/// cursor.
///
/// It works on rows rather than on domain models on purpose — the sync engine
/// needs `updatedAt`/`needsSync`, which are storage concerns deliberately
/// absent from [Character].
class CharacterSyncDao {
  CharacterSyncDao(this._db);

  static const _cursorKey = 'sync.cursor';
  static const _accountKey = 'sync.account_id';

  final AppDatabase _db;

  // --- Bookkeeping ---------------------------------------------------------

  Future<DateTime?> readCursor() async {
    final raw = await _readMeta(_cursorKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> writeCursor(DateTime value) =>
      _writeMeta(_cursorKey, value.toUtc().toIso8601String());

  Future<String?> readAccountId() => _readMeta(_accountKey);

  Future<void> writeAccountId(String value) => _writeMeta(_accountKey, value);

  /// Called when a different account signs in on this device: the previous
  /// user's characters must not leak into the new session, and the cursor from
  /// the old account is meaningless.
  Future<void> resetForNewAccount(String accountId) async {
    await _db.transaction(() async {
      await _db.delete(_db.characters).go();
      await _db.delete(_db.syncMetadata).go();
      await _writeMeta(_accountKey, accountId);
    });
  }

  Future<String?> _readMeta(String key) async {
    final row = await (_db.select(_db.syncMetadata)
          ..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _writeMeta(String key, String value) async {
    await _db
        .into(_db.syncMetadata)
        .insertOnConflictUpdate(SyncMetadataRow(key: key, value: value));
  }

  // --- Push ----------------------------------------------------------------

  /// Every locally modified aggregate, tombstones included.
  Future<List<RemoteCharacter>> pendingPushes() async {
    final rows = await (_db.select(_db.characters)
          ..where((c) => c.needsSync.equals(true)))
        .get();
    return Future.wait(rows.map(_toRemote));
  }

  /// Clears the dirty flag, but only if the row has not been edited again
  /// since the push started — otherwise that concurrent edit would never be
  /// uploaded.
  Future<void> markSynced(String id, DateTime pushedUpdatedAt) async {
    await (_db.update(_db.characters)
          ..where((c) =>
              c.id.equals(id) & c.updatedAt.equals(pushedUpdatedAt)))
        .write(const CharactersCompanion(needsSync: Value(false)));
  }

  /// Once the API knows about a deletion, the local tombstone has no further
  /// purpose and the row can go for good.
  Future<void> purge(String id) async {
    await (_db.delete(_db.characters)..where((c) => c.id.equals(id))).go();
  }

  // --- Pull ----------------------------------------------------------------

  Future<CharacterRow?> findRow(String id) {
    return (_db.select(_db.characters)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Replaces the local aggregate with the server's version, children
  /// included. Mirrors the server's own "replace, do not merge" rule.
  Future<void> applyRemote(RemoteCharacter remote) async {
    await _db.transaction(() async {
      if (remote.isDeleted) {
        await (_db.delete(_db.characters)..where((c) => c.id.equals(remote.id)))
            .go();
        return;
      }

      await _ensureGameSystem(remote.systemId);

      await _db.into(_db.characters).insertOnConflictUpdate(
            CharacterRow(
              id: remote.id,
              systemId: remote.systemId,
              name: remote.name,
              occupation: remote.occupation,
              description: remote.description,
              level: remote.level,
              createdAt: remote.createdAt,
              updatedAt: remote.updatedAt,
              needsSync: false,
            ),
          );

      await (_db.delete(_db.characterStats)
            ..where((s) => s.characterId.equals(remote.id)))
          .go();
      await (_db.delete(_db.characterResources)
            ..where((r) => r.characterId.equals(remote.id)))
          .go();
      await (_db.delete(_db.inventoryItems)
            ..where((i) => i.characterId.equals(remote.id)))
          .go();

      for (final stat in remote.stats) {
        await _db.into(_db.characterStats).insert(CharacterStatRow(
              id: stat.id,
              characterId: remote.id,
              kind: stat.kind,
              key: stat.key,
              label: stat.label,
              value: stat.value,
              base: stat.base,
              sortOrder: stat.sortOrder,
            ));
      }
      for (final resource in remote.resources) {
        await _db.into(_db.characterResources).insert(CharacterResourceRow(
              id: resource.id,
              characterId: remote.id,
              key: resource.key,
              label: resource.label,
              current: resource.current,
              max: resource.max,
              tone: resource.tone,
            ));
      }
      for (final item in remote.inventory) {
        await _db.into(_db.inventoryItems).insert(InventoryItemRow(
              id: item.id,
              characterId: remote.id,
              name: item.name,
              qty: item.qty,
              weight: item.weight,
            ));
      }
    });
  }

  /// `characters.system_id` is a foreign key. A character synced from another
  /// device may reference a universe whose JSON config is not bundled in this
  /// build, so a placeholder row is created rather than failing the whole pull.
  Future<void> _ensureGameSystem(String systemId) async {
    final existing = await (_db.select(_db.gameSystems)
          ..where((s) => s.id.equals(systemId)))
        .getSingleOrNull();
    if (existing != null) return;

    await _db.into(_db.gameSystems).insert(
          GameSystemRow(id: systemId, name: systemId, occupationSuggestions: '[]'),
        );
  }

  Future<RemoteCharacter> _toRemote(CharacterRow row) async {
    final stats = await (_db.select(_db.characterStats)
          ..where((s) => s.characterId.equals(row.id)))
        .get();
    final resources = await (_db.select(_db.characterResources)
          ..where((r) => r.characterId.equals(row.id)))
        .get();
    final inventory = await (_db.select(_db.inventoryItems)
          ..where((i) => i.characterId.equals(row.id)))
        .get();

    return RemoteCharacter(
      id: row.id,
      systemId: row.systemId,
      name: row.name,
      occupation: row.occupation,
      description: row.description,
      level: row.level,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      stats: stats
          .map((s) => RemoteStat(
                id: s.id,
                kind: s.kind,
                key: s.key,
                label: s.label,
                value: s.value,
                base: s.base,
                sortOrder: s.sortOrder,
              ))
          .toList(),
      resources: resources
          .map((r) => RemoteResource(
                id: r.id,
                key: r.key,
                label: r.label,
                current: r.current,
                max: r.max,
                tone: r.tone,
              ))
          .toList(),
      inventory: inventory
          .map((i) => RemoteInventoryItem(
                id: i.id,
                name: i.name,
                qty: i.qty,
                weight: i.weight,
              ))
          .toList(),
    );
  }
}
