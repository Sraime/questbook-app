import 'api_client.dart';
import 'remote_table.dart';

/// Tables, their members and their invitations.
///
/// Reads come in two flavours: the parsed one for normal use, and a `…Raw`
/// one that hands back the envelope untouched so it can be stored and read
/// again without a network. Both end in the same parser, so an offline screen
/// and an online one can never disagree about what a table is.
class TableApi {
  TableApi(this._client);

  final ApiClient _client;

  Future<List<RemoteGameTable>> list() async => parseTables(await listRaw());

  Future<dynamic> listRaw() {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables'),
      parse: (data) => data,
    );
  }

  static List<RemoteGameTable> parseTables(Object? data) {
    final tables = (data as Map)['tables'];
    if (tables is! List) return const <RemoteGameTable>[];
    return tables
        .whereType<Map>()
        .map((entry) => RemoteGameTable.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<RemoteGameTable> get(String id) async => _parseTable(await getRaw(id));

  Future<dynamic> getRaw(String id) {
    return _client.send(
      (dio) => dio.get<dynamic>('/tables/$id'),
      parse: (data) => data,
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
  Future<List<RemoteTableInvitation>> pendingInvitations() async =>
      parseInvitations(await pendingInvitationsRaw());

  Future<dynamic> pendingInvitationsRaw() {
    return _client.send(
      (dio) => dio.get<dynamic>('/invitations'),
      parse: (data) => data,
    );
  }

  static List<RemoteTableInvitation> parseInvitations(Object? data) {
    final invitations = (data as Map)['invitations'];
    if (invitations is! List) return const <RemoteTableInvitation>[];
    return invitations
        .whereType<Map>()
        .map((entry) =>
            RemoteTableInvitation.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static RemoteGameTable parseTable(Object? data) =>
      RemoteGameTable.fromJson((data as Map).cast<String, dynamic>());

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

  RemoteGameTable _parseTable(Object? data) => parseTable(data);
}
