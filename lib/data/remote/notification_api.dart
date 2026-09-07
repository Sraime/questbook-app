import 'api_client.dart';
import 'remote_table.dart';

class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  Future<RemoteNotificationPage> list({int limit = 50}) {
    return _client.send(
      (dio) => dio.get<dynamic>(
        '/notifications',
        queryParameters: {'limit': limit},
      ),
      parse: (data) =>
          RemoteNotificationPage.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  Future<void> markRead(List<String> ids) {
    if (ids.isEmpty) return Future.value();
    return _client.send(
      (dio) => dio.post<dynamic>('/notifications/read', data: {'ids': ids}),
      parse: (_) {},
    );
  }

  Future<void> markAllRead() {
    return _client.send(
      (dio) => dio.post<dynamic>('/notifications/read-all'),
      parse: (_) {},
    );
  }

  /// Replayed on every sign-in and whenever Firebase rotates the token, which
  /// is why the server treats it as an upsert.
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) {
    return _client.send(
      (dio) => dio.put<dynamic>(
        '/devices',
        data: {'token': token, 'platform': platform},
      ),
      parse: (_) {},
    );
  }

  /// Called on sign-out so a shared device stops receiving another player's
  /// notifications.
  Future<void> unregisterDevice(String token) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/devices/${Uri.encodeComponent(token)}'),
      parse: (_) {},
    );
  }
}
