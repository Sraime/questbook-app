import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/character.dart';
import '../../domain/models/character_resource.dart';
import '../../domain/models/character_stat.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/tone.dart';
import '../../domain/repositories/character_repository.dart';
import 'database.dart';

class LocalCharacterRepository implements CharacterRepository {
  LocalCharacterRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<void> get _changes => _db.tableUpdates(TableUpdateQuery.onAllTables([
        _db.characters,
        _db.characterStats,
        _db.characterResources,
        _db.inventoryItems,
      ]));

  @override
  Stream<List<Character>> watchAll() async* {
    yield await _fetchAll();
    yield* _changes.asyncMap((_) => _fetchAll());
  }

  @override
  Stream<Character?> watchById(String id) async* {
    yield await _fetchOne(id);
    yield* _changes.asyncMap((_) => _fetchOne(id));
  }

  @override
  Future<Character> create({
    required String systemId,
    required String name,
    String? occupation,
    String? description,
    required List<CharacterStat> stats,
    required List<CharacterResource> resources,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.characters).insert(
            CharacterRow(
              id: id,
              systemId: systemId,
              name: name,
              occupation: occupation,
              description: description,
              level: 1,
              createdAt: now,
              updatedAt: now,
              needsSync: true,
            ),
          );

      for (final stat in stats) {
        await _db.into(_db.characterStats).insert(
              CharacterStatRow(
                id: _uuid.v4(),
                characterId: id,
                kind: stat.kind.name,
                key: stat.key,
                label: stat.label,
                value: stat.value,
                base: stat.base,
                sortOrder: stat.sortOrder,
              ),
            );
      }

      for (final resource in resources) {
        await _db.into(_db.characterResources).insert(
              CharacterResourceRow(
                id: _uuid.v4(),
                characterId: id,
                key: resource.key,
                label: resource.label,
                current: resource.current,
                max: resource.max,
                tone: resource.tone.name,
              ),
            );
      }
    });

    return (await _fetchOne(id))!;
  }

  @override
  Future<void> updateResourceCurrent(
    String characterId,
    String resourceKey,
    int newCurrent,
  ) async {
    await _db.transaction(() async {
      await (_db.update(_db.characterResources)
            ..where((r) =>
                r.characterId.equals(characterId) & r.key.equals(resourceKey)))
          .write(CharacterResourcesCompanion(current: Value(newCurrent)));
      await _touch(characterId);
    });
  }

  @override
  Future<void> updateStatValue(
    String characterId,
    String statKey,
    int newValue,
  ) async {
    await _db.transaction(() async {
      await (_db.update(_db.characterStats)
            ..where((s) =>
                s.characterId.equals(characterId) & s.key.equals(statKey)))
          .write(CharacterStatsCompanion(value: Value(newValue)));
      await _touch(characterId);
    });
  }

  @override
  Future<void> addInventoryItem(
    String characterId, {
    required String name,
    int qty = 1,
    String? weight,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.inventoryItems).insert(
            InventoryItemRow(
              id: _uuid.v4(),
              characterId: characterId,
              name: name,
              qty: qty,
              weight: weight,
            ),
          );
      await _touch(characterId);
    });
  }

  @override
  Future<void> removeInventoryItem(String itemId) async {
    await _db.transaction(() async {
      // The owning character has to be resolved before the row disappears,
      // otherwise its clock could not be bumped for the sync engine.
      final item = await (_db.select(_db.inventoryItems)
            ..where((i) => i.id.equals(itemId)))
          .getSingleOrNull();
      if (item == null) return;

      await (_db.delete(_db.inventoryItems)..where((i) => i.id.equals(itemId)))
          .go();
      await _touch(item.characterId);
    });
  }

  @override
  Future<void> delete(String characterId) async {
    final now = DateTime.now();
    await (_db.update(_db.characters)..where((c) => c.id.equals(characterId)))
        .write(CharactersCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
      needsSync: const Value(true),
    ));
  }

  /// Marks the aggregate as locally modified. Every mutation goes through it,
  /// including changes to stats, resources and inventory, because the API
  /// treats a character and its children as a single versioned document.
  Future<void> _touch(String characterId) async {
    await (_db.update(_db.characters)..where((c) => c.id.equals(characterId)))
        .write(CharactersCompanion(
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    ));
  }

  Future<List<Character>> _fetchAll() async {
    final rows = await (_db.select(_db.characters)
          ..where((c) => c.deletedAt.isNull()))
        .get();
    return Future.wait(rows.map(_hydrate));
  }

  Future<Character?> _fetchOne(String id) async {
    final row = await (_db.select(_db.characters)
          ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<Character> _hydrate(CharacterRow row) async {
    final statRows = await (_db.select(_db.characterStats)
          ..where((s) => s.characterId.equals(row.id)))
        .get();
    final resourceRows = await (_db.select(_db.characterResources)
          ..where((r) => r.characterId.equals(row.id)))
        .get();
    final inventoryRows = await (_db.select(_db.inventoryItems)
          ..where((i) => i.characterId.equals(row.id)))
        .get();

    return Character(
      id: row.id,
      systemId: row.systemId,
      name: row.name,
      occupation: row.occupation,
      description: row.description,
      level: row.level,
      createdAt: row.createdAt,
      stats: statRows.map(_statFromRow).toList(),
      resources: resourceRows.map(_resourceFromRow).toList(),
      inventory: inventoryRows
          .map((i) => InventoryItem(
                id: i.id,
                characterId: i.characterId,
                name: i.name,
                qty: i.qty,
                weight: i.weight,
              ))
          .toList(),
    );
  }

  CharacterStat _statFromRow(CharacterStatRow row) => CharacterStat(
        id: row.id,
        characterId: row.characterId,
        kind: StatKind.values.byName(row.kind),
        key: row.key,
        label: row.label,
        value: row.value,
        base: row.base,
        sortOrder: row.sortOrder,
      );

  CharacterResource _resourceFromRow(CharacterResourceRow row) =>
      CharacterResource(
        id: row.id,
        characterId: row.characterId,
        key: row.key,
        label: row.label,
        current: row.current,
        max: row.max,
        tone: Tone.values.byName(row.tone),
      );
}
