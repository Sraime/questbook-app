// `isNull`/`isNotNull` exist in both drift (SQL predicates) and matcher.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/character_api.dart';
import 'package:questbook/data/remote/remote_character.dart';
import 'package:questbook/data/sync/character_sync_dao.dart';
import 'package:questbook/data/sync/sync_service.dart';

/// Stands in for the HTTP layer so the synchronisation rules can be exercised
/// against a real database without a server.
class FakeCharacterApi implements CharacterApi {
  final List<RemoteCharacter> pushed = [];

  /// Pull results, consumed oldest first. An empty queue answers "nothing new".
  final List<RemoteSyncPage> pages = [];

  /// Ids the server rejects as stale, mapped to the version it says won.
  final Map<String, RemoteCharacter> conflicts = {};

  /// Ids the server plainly fails on.
  final Map<String, ApiException> failures = {};

  /// Hook to simulate the user editing a character while the pass is running.
  Future<void> Function()? beforeList;

  DateTime? lastSince;

  @override
  Future<RemoteSyncPage> list({DateTime? since}) async {
    lastSince = since;
    await beforeList?.call();

    if (pages.isEmpty) {
      return RemoteSyncPage(characters: const [], syncedAt: DateTime.now());
    }
    return pages.removeAt(0);
  }

  @override
  Future<RemoteCharacter> push(RemoteCharacter character) async {
    final failure = failures[character.id];
    if (failure != null) throw failure;

    final winner = conflicts.remove(character.id);
    if (winner != null) {
      throw ApiException(
        code: 'CONFLICT',
        message: 'Le personnage a été modifié ailleurs.',
        statusCode: 409,
        details: {
          'character': {'id': winner.id, ...winner.toJson()},
        },
      );
    }

    pushed.add(character);
    return character;
  }

  @override
  Future<void> delete(String id) async {}
}

RemoteCharacter remoteCharacter({
  required String id,
  required DateTime updatedAt,
  String name = 'Ernest',
  DateTime? deletedAt,
  List<RemoteInventoryItem> inventory = const [],
}) {
  return RemoteCharacter(
    id: id,
    systemId: 'call_of_cthulhu_classique',
    name: name,
    occupation: null,
    description: null,
    level: 1,
    createdAt: DateTime.utc(2025),
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    stats: const [],
    resources: const [],
    inventory: inventory,
  );
}

void main() {
  late AppDatabase db;
  late CharacterSyncDao dao;
  late FakeCharacterApi api;
  late SyncService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = CharacterSyncDao(db);
    api = FakeCharacterApi();
    service = SyncService(api, dao);

    await db.into(db.gameSystems).insert(
          GameSystemRow(
            id: 'call_of_cthulhu_classique',
            name: 'Classique',
            occupationSuggestions: '[]',
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> insertLocal({
    required String id,
    required DateTime updatedAt,
    String name = 'Ernest',
    bool needsSync = true,
    DateTime? deletedAt,
  }) async {
    await db.into(db.characters).insert(
          CharacterRow(
            id: id,
            systemId: 'call_of_cthulhu_classique',
            name: name,
            level: 1,
            createdAt: DateTime.utc(2025),
            updatedAt: updatedAt,
            needsSync: needsSync,
            deletedAt: deletedAt,
          ),
        );
  }

  Future<CharacterRow?> localRow(String id) =>
      (db.select(db.characters)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  group('push', () {
    test('uploads dirty characters and clears their flag', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));

      final report = await service.synchronize(accountId: 'user-1');

      expect(report.isSuccess, isTrue);
      expect(report.pushed, 1);
      expect(api.pushed.single.id, 'a');
      expect((await localRow('a'))!.needsSync, isFalse);
    });

    test('leaves already-synced characters alone', () async {
      await insertLocal(
        id: 'a',
        updatedAt: DateTime.utc(2025, 6),
        needsSync: false,
      );

      await service.synchronize(accountId: 'user-1');

      expect(api.pushed, isEmpty);
    });

    test('adopts the server version when the local push is stale', () async {
      await insertLocal(
        id: 'a',
        name: 'Version locale',
        updatedAt: DateTime.utc(2025, 6),
      );
      api.conflicts['a'] = remoteCharacter(
        id: 'a',
        name: 'Version serveur',
        updatedAt: DateTime.utc(2025, 7),
      );

      final report = await service.synchronize(accountId: 'user-1');

      expect(report.isSuccess, isTrue);
      final row = await localRow('a');
      expect(row!.name, 'Version serveur');
      expect(
        row.needsSync,
        isFalse,
        reason: 'adopting the winner leaves nothing left to upload',
      );
    });

    test('drops the local tombstone once the deletion is uploaded', () async {
      await insertLocal(
        id: 'a',
        updatedAt: DateTime.utc(2025, 6),
        deletedAt: DateTime.utc(2025, 6),
      );

      await service.synchronize(accountId: 'user-1');

      expect(api.pushed.single.isDeleted, isTrue);
      expect(await localRow('a'), isNull);
    });

    test('reports a server failure instead of throwing, and stays dirty',
        () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));
      api.failures['a'] = const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur Questbook.',
      );

      final report = await service.synchronize(accountId: 'user-1');

      expect(report.isSuccess, isFalse);
      expect(report.error!.code, 'NETWORK_ERROR');
      expect(
        (await localRow('a'))!.needsSync,
        isTrue,
        reason: 'the character must be retried on the next pass',
      );
    });
  });

  group('pull', () {
    test('writes remote characters and their inventory into the database',
        () async {
      api.pages.add(RemoteSyncPage(
        characters: [
          remoteCharacter(
            id: 'b',
            name: 'Venu d’un autre appareil',
            updatedAt: DateTime.utc(2025, 8),
            inventory: const [
              RemoteInventoryItem(
                id: 'item-1',
                name: 'Lampe torche',
                qty: 1,
                weight: null,
              ),
            ],
          ),
        ],
        syncedAt: DateTime.utc(2025, 9),
      ));

      final report = await service.synchronize(accountId: 'user-1');

      expect(report.pulled, 1);
      expect((await localRow('b'))!.name, 'Venu d’un autre appareil');
      expect(await db.select(db.inventoryItems).get(), hasLength(1));
    });

    test('applies a deletion made on another device', () async {
      await insertLocal(
        id: 'c',
        updatedAt: DateTime.utc(2025, 6),
        needsSync: false,
      );
      api.pages.add(RemoteSyncPage(
        characters: [
          remoteCharacter(
            id: 'c',
            updatedAt: DateTime.utc(2025, 8),
            deletedAt: DateTime.utc(2025, 8),
          ),
        ],
        syncedAt: DateTime.utc(2025, 9),
      ));

      await service.synchronize(accountId: 'user-1');

      expect(await localRow('c'), isNull);
    });

    test('creates a placeholder system for an unknown universe', () async {
      api.pages.add(RemoteSyncPage(
        characters: [
          RemoteCharacter(
            id: 'e',
            systemId: 'systeme_inconnu',
            name: 'Explorateur',
            occupation: null,
            description: null,
            level: 1,
            createdAt: DateTime.utc(2025),
            updatedAt: DateTime.utc(2025, 8),
            deletedAt: null,
            stats: const [],
            resources: const [],
            inventory: const [],
          ),
        ],
        syncedAt: DateTime.utc(2025, 9),
      ));

      final report = await service.synchronize(accountId: 'user-1');

      expect(
        report.isSuccess,
        isTrue,
        reason: 'a universe missing from this build must not break the pull',
      );
      expect((await localRow('e'))!.systemId, 'systeme_inconnu');
    });

    test('does not overwrite an edit made while the pass was running',
        () async {
      await insertLocal(
        id: 'd',
        name: 'Nom initial',
        updatedAt: DateTime.utc(2025, 6),
      );

      api.beforeList = () async {
        await (db.update(db.characters)..where((c) => c.id.equals('d'))).write(
          CharactersCompanion(
            name: const Value('Édité pendant la sync'),
            updatedAt: Value(DateTime.utc(2025, 11)),
            needsSync: const Value(true),
          ),
        );
      };
      api.pages.add(RemoteSyncPage(
        characters: [
          remoteCharacter(
            id: 'd',
            name: 'Nom initial',
            updatedAt: DateTime.utc(2025, 6),
          ),
        ],
        syncedAt: DateTime.utc(2025, 9),
      ));

      final report = await service.synchronize(accountId: 'user-1');

      final row = await localRow('d');
      expect(row!.name, 'Édité pendant la sync');
      expect(row.needsSync, isTrue, reason: 'the edit still has to be uploaded');
      expect(report.pulled, 0);
    });

    test('remembers the cursor and sends it on the next pass', () async {
      api.pages.add(RemoteSyncPage(
        characters: const [],
        syncedAt: DateTime.utc(2025, 9, 15, 12),
      ));

      await service.synchronize(accountId: 'user-1');
      expect(api.lastSince, isNull, reason: 'the first pull is a full one');

      await service.synchronize(accountId: 'user-1');
      expect(api.lastSince?.toUtc(), DateTime.utc(2025, 9, 15, 12));
    });
  });

  group('account switching', () {
    test('adopts characters created offline on the first sign-in', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));

      await service.synchronize(accountId: 'user-1');

      expect(api.pushed.single.id, 'a');
      expect(await dao.readAccountId(), 'user-1');
    });

    test('wipes local data when a different account signs in', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));
      await service.synchronize(accountId: 'user-1');
      api.pushed.clear();

      await service.synchronize(accountId: 'user-2');

      expect(
        await localRow('a'),
        isNull,
        reason: "the previous user's characters must not leak into the new "
            'session',
      );
      expect(api.pushed, isEmpty);
      expect(await dao.readAccountId(), 'user-2');
    });

    test('restarts from a full pull after an account switch', () async {
      api.pages.add(RemoteSyncPage(
        characters: const [],
        syncedAt: DateTime.utc(2025, 9, 15, 12),
      ));
      await service.synchronize(accountId: 'user-1');
      await service.synchronize(accountId: 'user-1');
      expect(api.lastSince, isNotNull);

      await service.synchronize(accountId: 'user-2');

      expect(
        api.lastSince,
        isNull,
        reason: "the previous account's cursor says nothing about this one",
      );
    });
  });
}
