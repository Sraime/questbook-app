import 'api_client.dart';
import 'auth_tokens.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Exchanges a Google ID token for a Questbook session. Creates the account
  /// on the very first call, signs in on every later one.
  Future<AuthSession> signInWithGoogle(String idToken) {
    return _client.send(
      // No access token exists yet, so this must skip the auth interceptor.
      authenticated: false,
      (dio) => dio.post<dynamic>('/auth/google', data: {'idToken': idToken}),
      parse: _sessionFrom,
    );
  }

  Future<AuthUser> me() {
    return _client.send(
      (dio) => dio.get<dynamic>('/auth/me'),
      parse: (data) => AuthUser.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  Future<void> logout(String refreshToken) {
    return _client.send(
      authenticated: false,
      (dio) => dio.post<dynamic>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      ),
      parse: (_) {},
    );
  }

  AuthSession _sessionFrom(dynamic data) {
    final body = (data as Map).cast<String, dynamic>();
    return AuthSession(
      tokens: AuthTokens(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      ),
      user: AuthUser.fromJson((body['user'] as Map).cast<String, dynamic>()),
    );
  }
}
