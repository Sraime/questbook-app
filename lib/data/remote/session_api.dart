import 'api_client.dart';
import 'remote_character.dart';
import 'remote_table.dart';
import 'table_api.dart';

/// Sessions are created under their table but addressed by their own id
/// afterwards, so a notification can link straight to one.
class SessionApi {
  SessionApi(this._client);

  final ApiClient _client;

  Future<List<RemoteGameSession>> listForTable(String tableId) async =>
      parseSessions(await listForTableRaw(tableId));

  /// The envelope untouched, for the offline cache. See [TableApi.listRaw].
  Future<dynamic> listForTableRaw(String tableId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables/$tableId/sessions'),
      parse: (data) => data,
    );
  }

  static List<RemoteGameSession> parseSessions(Object? data) {
    final sessions = (data as Map)['sessions'];
    if (sessions is! List) return const <RemoteGameSession>[];
    return sessions
        .whereType<Map>()
        .map((entry) => RemoteGameSession.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<RemoteGameSession> get(String id) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$id'),
      parse: _parseSession,
    );
  }

  Future<RemoteGameSession> create(
    String tableId, {
    required String title,
    String? description,
    required DateTime startsAt,
    required String location,
    String? scenarioId,
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/tables/$tableId/sessions',
        data: {
          'title': title,
          'description': description,
          'startsAt': startsAt.toUtc().toIso8601String(),
          'location': location,
          'scenarioId': ?scenarioId,
        },
      ),
      parse: _parseSession,
    );
  }

  /// Only the fields actually being changed are sent: the server decides
  /// whether the change is worth notifying anyone about, and a needless
  /// `startsAt` would look like the date moved.
  Future<RemoteGameSession> update(
    String id, {
    String? title,
    String? description,
    DateTime? startsAt,
    String? location,
    String? scenarioId,
    bool clearScenario = false,
  }) {
    return _client.send(
      (dio) => dio.patch<dynamic>(
        '/sessions/$id',
        data: {
          'title': ?title,
          'description': ?description,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          'location': ?location,
          if (clearScenario) 'scenarioId': null,
          if (!clearScenario) 'scenarioId': ?scenarioId,
        },
      ),
      parse: _parseSession,
    );
  }

  /// Cancels rather than deletes: players who had blocked out the evening
  /// deserve to see what became of it.
  Future<RemoteGameSession> cancel(String id) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/sessions/$id'),
      parse: _parseSession,
    );
  }

  /// Answering may already name a character, or not: omitting [characterId]
  /// leaves any earlier choice untouched.
  Future<RemoteGameSession> setAttendance(
    String id,
    AttendanceStatus status, {
    String? characterId,
  }) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/sessions/$id/attendance',
        data: {
          'status': status.wire,
          'characterId': ?characterId,
        },
      ),
      parse: _parseSession,
    );
  }

  /// Naming, changing or dropping the character without touching the answer.
  /// Passing null detaches it. The game master is notified separately from an
  /// answer change, because it tells them something different.
  Future<RemoteGameSession> setAttendanceCharacter(
    String id,
    String? characterId,
  ) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/sessions/$id/attendance/character',
        data: {'characterId': characterId},
      ),
      parse: _parseSession,
    );
  }

  /// The sheet of another player at the same session, which they opened by
  /// registering it. Addressed by player, because that is what authorises the
  /// read.
  Future<RemoteCharacter> attendeeCharacter(String sessionId, String userId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$sessionId/attendances/$userId/character'),
      parse: (data) =>
          RemoteCharacter.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  // --- Personnages non-joueurs ---
  //
  // Réservés au MJ, lectures comprises : ce qu'il a préparé est exactement ce
  // que ses joueurs ne doivent pas savoir. Appeler ces routes depuis un compte
  // joueur vaut un 403, et c'est voulu.

  Future<List<RemoteNpc>> listNpcs(String sessionId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$sessionId/npcs'),
      parse: (data) {
        final npcs = (data as Map)['npcs'];
        if (npcs is! List) return const <RemoteNpc>[];
        return npcs
            .whereType<Map>()
            .map((entry) => RemoteNpc.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  Future<RemoteNpc> createNpc(
    String sessionId, {
    required String name,
    String? description,
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/sessions/$sessionId/npcs',
        data: {'name': name, 'description': ?description},
      ),
      parse: _parseNpc,
    );
  }

  Future<RemoteNpc> updateNpc(
    String sessionId,
    String npcId, {
    String? name,
    String? description,
  }) {
    return _client.send(
      (dio) => dio.patch<dynamic>(
        '/sessions/$sessionId/npcs/$npcId',
        data: {'name': ?name, 'description': ?description},
      ),
      parse: _parseNpc,
    );
  }

  Future<void> deleteNpc(String sessionId, String npcId) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/sessions/$sessionId/npcs/$npcId'),
      parse: (_) {},
    );
  }

  // --- Les indices ---
  //
  // Composer reste réservé au MJ, comme les PNJ. Seul [myClues] est ouvert à
  // un joueur, et ne lui rend que ce qu'on lui a ouvert.

  Future<List<RemoteClue>> listClues(String sessionId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$sessionId/clues'),
      parse: (data) {
        final clues = (data as Map)['clues'];
        if (clues is! List) return const <RemoteClue>[];
        return clues
            .whereType<Map>()
            .map((entry) => RemoteClue.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  Future<List<RemoteSharedClue>> myClues(String sessionId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$sessionId/clues/mine'),
      parse: (data) {
        final clues = (data as Map)['clues'];
        if (clues is! List) return const <RemoteSharedClue>[];
        return clues
            .whereType<Map>()
            .map((entry) =>
                RemoteSharedClue.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  Future<RemoteClue> createClue(
    String sessionId, {
    required String title,
    String? contentMarkdown,
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/sessions/$sessionId/clues',
        data: {'title': title, 'contentMarkdown': ?contentMarkdown},
      ),
      parse: _parseClue,
    );
  }

  Future<RemoteClue> updateClue(
    String sessionId,
    String clueId, {
    String? title,
    String? contentMarkdown,
  }) {
    return _client.send(
      (dio) => dio.patch<dynamic>(
        '/sessions/$sessionId/clues/$clueId',
        data: {'title': ?title, 'contentMarkdown': ?contentMarkdown},
      ),
      parse: _parseClue,
    );
  }

  Future<void> deleteClue(String sessionId, String clueId) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/sessions/$sessionId/clues/$clueId'),
      parse: (_) {},
    );
  }

  /// Remplace la liste des destinataires, au lieu d'y ajouter : c'est le geste
  /// de l'écran, où le MJ coche des noms et valide. Reprendre un indice est
  /// donc le même appel avec un nom de moins, et une liste vide le reprend à
  /// tout le monde.
  Future<RemoteClue> shareClue(
    String sessionId,
    String clueId, {
    required List<String> userIds,
  }) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/sessions/$sessionId/clues/$clueId/access',
        data: {'userIds': userIds},
      ),
      parse: _parseClue,
    );
  }

  // --- Le plateau ---
  //
  // L'inverse des PNJ juste au-dessus : tout membre lit, seul le MJ écrit. Un
  // plateau est fait pour être vu.

  Future<RemoteSessionBoard> board(String sessionId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/sessions/$sessionId/board'),
      parse: _parseBoard,
    );
  }

  /// Remonte le plateau entier, et non ce qui vient de changer : l'appareil du
  /// MJ détient la vérité complète, et envoyer une différence laisserait les
  /// deux s'écarter au premier message perdu.
  Future<RemoteSessionBoard> pushBoard(
    String sessionId, {
    required String tokens,
    String? mapId,
  }) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/sessions/$sessionId/board',
        data: {'tokens': tokens, 'mapId': mapId},
      ),
      parse: _parseBoard,
    );
  }

  RemoteGameSession _parseSession(Object? data) =>
      RemoteGameSession.fromJson((data as Map).cast<String, dynamic>());

  RemoteNpc _parseNpc(Object? data) =>
      RemoteNpc.fromJson((data as Map).cast<String, dynamic>());

  RemoteClue _parseClue(Object? data) =>
      RemoteClue.fromJson((data as Map).cast<String, dynamic>());

  RemoteSessionBoard _parseBoard(Object? data) =>
      RemoteSessionBoard.fromJson((data as Map).cast<String, dynamic>());
}
