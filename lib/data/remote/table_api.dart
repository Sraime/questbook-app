import 'api_client.dart';
import 'remote_table.dart';

/// Tables, their members and their invitations. Everything here needs the
/// network: unlike characters, none of it has a local copy to fall back on.
class TableApi {
  TableApi(this._client);

  final ApiClient _client;

  Future<List<RemoteGameTable>> list() {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables'),
      parse: (data) {
        final tables = (data as Map)['tables'];
        if (tables is! List) return const <RemoteGameTable>[];
        return tables
            .whereType<Map>()
            .map((entry) =>
                RemoteGameTable.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  Future<RemoteGameTable> get(String id) {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables/$id'),
      parse: _parseTable,
    );
  }

  Future<RemoteGameTable> create({
    required String title,
    String? universeLabel,
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/tables',
        data: {'title': title, 'universeLabel': universeLabel},
      ),
      parse: _parseTable,
    );
  }

  Future<RemoteGameTable> rename(String id, {required String title}) {
    return _client.send(
      (dio) => dio.patch<dynamic>('/tables/$id', data: {'title': title}),
      parse: _parseTable,
    );
  }

  Future<void> delete(String id) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/tables/$id'),
      parse: (_) {},
    );
  }

  Future<void> leave(String id) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/tables/$id/members/me'),
      parse: (_) {},
    );
  }

  Future<void> removeMember(String id, String userId) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/tables/$id/members/$userId'),
      parse: (_) {},
    );
  }

  /// Hands the table over. The caller becomes a plain player, and stops being
  /// able to do any of this.
  Future<RemoteGameTable> transferGameMaster(String id, String userId) {
    return _client.send(
      (dio) => dio.put<dynamic>('/tables/$id/game-master', data: {'userId': userId}),
      parse: (data) =>
          RemoteGameTable.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Throws an [ApiException] with a 404 when no Questbook account uses this
  /// address, which is the one refusal the invitation dialog has to explain.
  Future<RemoteTableInvitation> invite(String id, {required String email}) {
    return _client.send(
      (dio) => dio.post<dynamic>('/tables/$id/invitations', data: {'email': email}),
      parse: (data) =>
          RemoteTableInvitation.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  Future<void> revokeInvitation(String id, String invitationId) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/tables/$id/invitations/$invitationId'),
      parse: (_) {},
    );
  }

  /// Invitations waiting for the signed-in user, across every table.
  Future<List<RemoteTableInvitation>> pendingInvitations() {
    return _client.send(
      (dio) => dio.get<dynamic>('/invitations'),
      parse: (data) {
        final invitations = (data as Map)['invitations'];
        if (invitations is! List) return const <RemoteTableInvitation>[];
        return invitations
            .whereType<Map>()
            .map((entry) =>
                RemoteTableInvitation.fromJson(entry.cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  Future<RemoteGameTable> acceptInvitation(String invitationId) {
    return _client.send(
      (dio) => dio.post<dynamic>('/invitations/$invitationId/accept'),
      parse: _parseTable,
    );
  }

  Future<void> declineInvitation(String invitationId) {
    return _client.send(
      (dio) => dio.post<dynamic>('/invitations/$invitationId/decline'),
      parse: (_) {},
    );
  }

  RemoteGameTable _parseTable(Object? data) =>
      RemoteGameTable.fromJson((data as Map).cast<String, dynamic>());
}
