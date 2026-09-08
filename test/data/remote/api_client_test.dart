import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/api_client.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/token_store.dart';

/// Keeps the token pair in memory, so the client can be exercised without the
/// platform keystore.
class FakeTokenStore extends TokenStore {
  FakeTokenStore(this.tokens);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<AuthUser?> readUser() async => null;

  @override
  Future<void> writeUser(AuthUser user) async {}
}

/// A real HTTP server on the loopback interface. The refresh path lives partly
/// in Dio configuration, so a fake adapter would test the wrong thing.
class StubApi {
  StubApi(this._server) {
    unawaited(_serve());
  }

  static Future<StubApi> start() async =>
      StubApi(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;

  /// The only access token the server accepts; anything else gets a 401.
  String validAccessToken = 'access-2';

  /// The only refresh token the server accepts.
  String? validRefreshToken = 'refresh-1';

  /// Paths served, in order, so a test can count refreshes and retries.
  final List<String> hits = [];

  /// Held open while set, to line several requests up on the same 401.
  Completer<void>? gate;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> close() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server) {
      hits.add(request.uri.path);

      if (request.uri.path.endsWith('/auth/refresh')) {
        await _handleRefresh(request);
      } else {
        await _handleAuthenticated(request);
      }
    }
  }

  Future<void> _handleRefresh(HttpRequest request) async {
    final body = jsonDecode(await utf8.decodeStream(request)) as Map;

    if (body['refreshToken'] != validRefreshToken) {
      return _reply(request, 401, {
        'error': {'code': 'UNAUTHORIZED', 'message': 'Refresh token is invalid'},
      });
    }

    // Rotation: the presented token dies with this answer.
    validRefreshToken = 'refresh-2';
    validAccessToken = 'access-2';

    return _reply(request, 200, {
      'accessToken': 'access-2',
      'refreshToken': 'refresh-2',
      'expiresIn': '15m',
    });
  }

  Future<void> _handleAuthenticated(HttpRequest request) async {
    if (gate != null) await gate!.future;

    final authorized =
        request.headers.value('authorization') == 'Bearer $validAccessToken';

    if (!authorized) {
      return _reply(request, 401, {
        'error': {'code': 'UNAUTHORIZED', 'message': 'Access token expired'},
      });
    }

    return _reply(request, 200, {'ok': true});
  }

  Future<void> _reply(HttpRequest request, int status, Object body) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    return request.response.close();
  }
}

void main() {
  late StubApi api;
  late FakeTokenStore store;
  late ApiClient client;
  var expiredSessions = 0;

  setUp(() async {
    api = await StubApi.start();
    store = FakeTokenStore(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    expiredSessions = 0;
    client = ApiClient(api.baseUrl, store)
      ..onSessionExpired = () => expiredSessions++;
  });

  tearDown(() => api.close());

  Future<Map<String, dynamic>> get() => client.send<Map<String, dynamic>>(
        (dio) => dio.get<dynamic>('/characters'),
        parse: (data) => (data as Map).cast<String, dynamic>(),
      );

  test('refreshes an expired access token and replays the request', () async {
    expect(await get(), {'ok': true});

    expect(
      api.hits,
      ['/api/v1/characters', '/api/v1/auth/refresh', '/api/v1/characters'],
    );
    expect(store.tokens?.accessToken, 'access-2');
    expect(store.tokens?.refreshToken, 'refresh-2');
    expect(expiredSessions, 0);
  });

  test('reuses the refreshed token for later requests', () async {
    await get();
    api.hits.clear();

    expect(await get(), {'ok': true});
    expect(api.hits, ['/api/v1/characters']);
  });

  test('gives up and expires the session when the refresh is refused',
      () async {
    api.validRefreshToken = 'someone-elses-token';

    await expectLater(
      get(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );

    expect(store.tokens, isNull);
    expect(expiredSessions, 1);
  });

  test('burns a single refresh token when requests fail together', () async {
    // Rotation revokes the presented token, so three parallel 401s must not
    // each try to spend it: the second would sign the user out.
    api.gate = Completer<void>();
    final pending = Future.wait([get(), get(), get()]);
    api.gate!.complete();

    await pending;

    expect(
      api.hits.where((path) => path.endsWith('/auth/refresh')),
      hasLength(1),
    );
    expect(expiredSessions, 0);
  });
}
