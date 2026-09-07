import 'api_client.dart';
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

  Future<RemoteGameSession> setAttendance(String id, AttendanceStatus status) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/sessions/$id/attendance',
        data: {'status': status.wire},
      ),
      parse: _parseSession,
    );
  }

  RemoteGameSession _parseSession(Object? data) =>
      RemoteGameSession.fromJson((data as Map).cast<String, dynamic>());
}
