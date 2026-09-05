// `isNull`/`isNotNull` exist in both drift (SQL predicates) and matcher.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/local_character_repository.dart';
import 'package:questbook/domain/models/character_resource.dart';
import 'package:questbook/domain/models/character_stat.dart';
import 'package:questbook/domain/models/tone.dart';

/// Covers the synchronisation bookkeeping the repository is now responsible
/// for: every write must mark the aggregate dirty and move its clock, or the
/// change would never reach the API.
void main() {
  late AppDatabase db;
  late LocalCharacterRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocalCharacterRepository(db);

    await db.into(db.gameSystems).insert(
          GameSystemRow(
            id: 'call_of_cthulhu_classique',
            name: 'Classique',
            occupationSuggestions: '[]',
          ),
        );
  });

  tearDown(() => db.close());

  Future<String> createCharacter() async {
    final character = await repository.create(
      systemId: 'call_of_cthulhu_classique',
      name: 'Ernest',
      stats: const [
        CharacterStat(
          id: '',
          characterId: '',
          kind: StatKind.skill,
          key: 'bibliotheque',
          label: 'Bibliothèque',
          value: 20,
        ),
      ],
      resources: const [
        CharacterResource(
          id: '',
          characterId: '',
          key: 'pv',
          label: 'PV',
          current: 11,
          max: 11,
          tone: Tone.danger,
        ),
      ],
    );
    return character.id;
  }

  Future<CharacterRow> row(String id) =>
      (db.select(db.characters)..where((c) => c.id.equals(id))).getSingle();

  Future<void> markClean(String id) async {
    await (db.update(db.characters)..where((c) => c.id.equals(id)))
        .write(const CharactersCompanion(needsSync: Value(false)));
  }

  test('a freshly created character is queued for upload', () async {
    final id = await createCharacter();
    final created = await row(id);

    expect(created.needsSync, isTrue);
    expect(created.deletedAt, isNull);
    expect(created.updatedAt, created.createdAt);
  });

  test('changing a resource marks the character dirty again', () async {
    final id = await createCharacter();
    await markClean(id);
    final before = await row(id);

    await repository.updateResourceCurrent(id, 'pv', 7);
    final after = await row(id);

    expect(after.needsSync, isTrue);
    expect(
      after.updatedAt.isAfter(before.updatedAt) ||
          after.updatedAt == before.updatedAt,
      isTrue,
    );
  });

  test('changing a stat marks the character dirty again', () async {
    final id = await createCharacter();
    await markClean(id);

    await repository.updateStatValue(id, 'bibliotheque', 65);

    expect((await row(id)).needsSync, isTrue);
  });

  test('adding an inventory item marks the character dirty again', () async {
    final id = await createCharacter();
    await markClean(id);

    await repository.addInventoryItem(id, name: 'Lampe torche');

    expect((await row(id)).needsSync, isTrue);
  });

  test('removing an inventory item marks its character dirty again', () async {
    final id = await createCharacter();
    await repository.addInventoryItem(id, name: 'Corde');
    await markClean(id);

    final items = await db.select(db.inventoryItems).get();
    await repository.removeInventoryItem(items.single.id);

    expect((await row(id)).needsSync, isTrue);
    expect(await db.select(db.inventoryItems).get(), isEmpty);
  });

  test('deleting keeps a tombstone but hides the character from the list',
      () async {
    final id = await createCharacter();

    await repository.delete(id);

    final tombstone = await row(id);
    expect(tombstone.deletedAt, isNotNull);
    expect(tombstone.needsSync, isTrue);

    expect(await repository.watchAll().first, isEmpty);
    expect(await repository.watchById(id).first, isNull);
  });
}
