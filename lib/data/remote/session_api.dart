import 'api_client.dart';
import 'remote_character.dart';
import 'remote_table.dart';

/// Sessions are created under their table but addressed by their own id
/// afterwards, so a notification can link straight to one.
class SessionApi {
  SessionApi(this._client);

  final ApiClient _client;

  Future<List<RemoteGameSession>> listForTable(String tableId) {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables/$tableId/sessions'),
      parse: (data) {
        final sessions = (data as Map)['sessions'];
        if (sessions is! List) return const <RemoteGameSession>[];
        return sessions
            .whereType<Map>()
            .map((entry) =>
                RemoteGameSession.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
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
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/tables/$tableId/sessions',
        data: {
          'title': title,
          'description': description,
          'startsAt': startsAt.toUtc().toIso8601String(),
          'location': location,
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
  }) {
    return _client.send(
      (dio) => dio.patch<dynamic>(
        '/sessions/$id',
        data: {
          'title': ?title,
          'description': ?description,
          if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
          'location': ?location,
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

  RemoteGameSession _parseSession(Object? data) =>
      RemoteGameSession.fromJson((data as Map).cast<String, dynamic>());
}
