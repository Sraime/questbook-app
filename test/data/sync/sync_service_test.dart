import 'dart:async';

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

  /// Same, for a single upload: the player keeps tapping while the answer to
  /// the previous tap is in the air.
  Future<void> Function(RemoteCharacter)? beforePush;

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
    await beforePush?.call(character);

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
    int revision = 0,
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
            revision: revision,
          ),
        );
  }

  Future<CharacterRow?> localRow(String id) =>
      (db.select(db.characters)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  /// What the repository does on any local write, revision bump included —
  /// without it a test would model an edit the sync engine cannot see.
  Future<void> editLocally(
    String id, {
    required String name,
    required DateTime updatedAt,
  }) async {
    await (db.update(db.characters)..where((c) => c.id.equals(id)))
        .write(CharactersCompanion.custom(
      name: Variable(name),
      updatedAt: Variable(updatedAt),
      needsSync: const Constant(true),
      revision: db.characters.revision + const Constant(1),
    ));
  }

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

  /// Une fiche part au serveur dans la foulée du geste qui l'a changée, sans
  /// attendre la passe complète : à une table de jeu, le MJ lit les fiches
  /// depuis le serveur, et personne ne quitte l'app pour déclencher une passe.
  group('push immédiat', () {
    test('envoie la fiche touchée, et elle seule', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));
      await insertLocal(id: 'b', updatedAt: DateTime.utc(2025, 6));

      await service.pushCharacter('a');

      expect(api.pushed.map((c) => c.id), ['a']);
      expect((await localRow('a'))!.needsSync, isFalse);
      expect(
        (await localRow('b'))!.needsSync,
        isTrue,
        reason: 'la passe complète s’occupera des autres',
      );
    });

    test('ne rappelle pas le serveur pour une fiche déjà à jour', () async {
      await insertLocal(
        id: 'a',
        updatedAt: DateTime.utc(2025, 6),
        needsSync: false,
      );

      await service.pushCharacter('a');

      expect(api.pushed, isEmpty);
    });

    test('ne va pas chercher ce que le serveur a de neuf', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));
      api.pages.add(RemoteSyncPage(
        characters: [remoteCharacter(id: 'b', updatedAt: DateTime.utc(2025, 8))],
        syncedAt: DateTime.utc(2025, 9),
      ));

      await service.pushCharacter('a');

      expect(
        await localRow('b'),
        isNull,
        reason: 'une pression sur une jauge ne rapatrie pas tout le compte',
      );
      expect(api.pages, hasLength(1), reason: 'la page n’a pas été consommée');
    });

    test('laisse la fiche marquée quand le serveur ne répond pas', () async {
      await insertLocal(id: 'a', updatedAt: DateTime.utc(2025, 6));
      api.failures['a'] = const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur Questbook.',
      );

      await expectLater(
        service.pushCharacter('a'),
        throwsA(isA<ApiException>()),
      );

      expect(
        (await localRow('a'))!.needsSync,
        isTrue,
        reason: 'la prochaine passe complète la reprendra',
      );
    });

    test('deux pressions coup sur coup arrivent dans l’ordre', () async {
      await insertLocal(id: 'a', name: 'Un', updatedAt: DateTime.utc(2025, 6));

      // Le premier envoi est retenu en vol pendant que le second est
      // demandé : sans file par fiche, les deux partiraient de front, et le
      // plus ancien reviendrait en conflit avec la version du serveur.
      final inFlight = Completer<void>();
      final release = Completer<void>();
      api.beforePush = (character) async {
        api.beforePush = null;
        inFlight.complete();
        await release.future;
      };

      final first = service.pushCharacter('a');
      await inFlight.future;

      await editLocally('a', name: 'Deux', updatedAt: DateTime.utc(2025, 7));
      final second = service.pushCharacter('a');

      release.complete();
      await Future.wait([first, second]);

      expect(api.pushed.map((c) => c.name), ['Un', 'Deux']);
      expect(
        (await localRow('a'))!.needsSync,
        isFalse,
        reason: 'le serveur a fini par recevoir le dernier état',
      );
    });

    test('deux pressions dans la même seconde comptent pour deux', () async {
      // Le piège que ce test épingle : Drift range une date à la seconde, si
      // bien que deux pressions coup sur coup portent le même `updatedAt`.
      // Tant que le drapeau était levé sur cette base, la seconde pression
      // était réputée envoyée et restait sur le téléphone — le MJ lisait des
      // points de vie faux sans que rien ne le signale.
      final meme = DateTime.utc(2025, 6, 1, 20, 30, 15);
      await insertLocal(id: 'a', name: 'Un', updatedAt: meme);

      final inFlight = Completer<void>();
      final release = Completer<void>();
      api.beforePush = (character) async {
        api.beforePush = null;
        inFlight.complete();
        await release.future;
      };

      final first = service.pushCharacter('a');
      await inFlight.future;

      await editLocally('a', name: 'Deux', updatedAt: meme);
      final second = service.pushCharacter('a');

      release.complete();
      await Future.wait([first, second]);

      expect(api.pushed.map((c) => c.name), ['Un', 'Deux']);
    });

    test('n’écrase pas une modification faite pendant l’envoi', () async {
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
      // Le joueur enchaîne sur la jauge suivante pendant que la réponse du
      // serveur est en vol.
      api.beforePush = (character) async {
        api.beforePush = null;
        await editLocally(
          'a',
          name: 'Tapé juste après',
          updatedAt: DateTime.utc(2025, 12),
        );
      };

      await service.pushCharacter('a');

      final row = await localRow('a');
      expect(
        row!.name,
        'Tapé juste après',
        reason: 'adopter le serveur ici déferait une modification sous les '
            'yeux du joueur',
      );
      expect(row.needsSync, isTrue);
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
        await editLocally(
          'd',
          name: 'Édité pendant la sync',
          updatedAt: DateTime.utc(2025, 11),
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
      await db.into(db.remoteCache).insert(
            RemoteCacheRow(
              key: 'tables.overview',
              accountId: 'user-1',
              payload: '{"tables":[]}',
              fetchedAt: DateTime.utc(2025, 6),
            ),
          );
      await service.synchronize(accountId: 'user-1');
      api.pushed.clear();

      await service.synchronize(accountId: 'user-2');

      expect(
        await localRow('a'),
        isNull,
        reason: "the previous user's characters must not leak into the new "
            'session',
      );
      expect(
        await db.select(db.remoteCache).get(),
        isEmpty,
        reason: "the previous user's cached tables must not leak either",
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
