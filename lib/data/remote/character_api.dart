import 'api_client.dart';
import 'remote_character.dart';

class CharacterApi {
  CharacterApi(this._client);

  final ApiClient _client;

  /// Incremental pull when [since] is given — the response then also contains
  /// tombstones, so deletions made on another device are replicated.
  Future<RemoteSyncPage> list({DateTime? since}) {
    return _client.send(
      (dio) => dio.get<dynamic>(
        '/characters',
        queryParameters: since == null
            ? null
            : {'since': since.toUtc().toIso8601String()},
      ),
      parse: (data) =>
          RemoteSyncPage.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Pushes the full aggregate. Throws an [ApiException] with `CONFLICT` when
  /// the server holds a newer version.
  Future<RemoteCharacter> push(RemoteCharacter character) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/characters/${character.id}',
        data: character.toJson(),
      ),
      parse: (data) =>
          RemoteCharacter.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  Future<void> delete(String id) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/characters/$id'),
      parse: (_) {},
    );
  }
}
