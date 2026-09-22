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

  /// Idem depuis un jeton d'identité Apple.
  ///
  /// Le nom voyage à part parce qu'Apple ne le met pas dans le jeton : il est
  /// remis au client une seule fois, à la première autorisation, et jamais
  /// ensuite. Le serveur ne s'en sert qu'à la création du compte.
  Future<AuthSession> signInWithApple(
    String identityToken, {
    String? displayName,
  }) {
    return _client.send(
      authenticated: false,
      (dio) => dio.post<dynamic>(
        '/auth/apple',
        data: {
          'identityToken': identityToken,
          // Absente plutot que nulle : le serveur ne veut pas d'un nom vide,
          // et un compte peut tres bien n'en avoir jamais partage.
          'displayName': ?displayName,
        },
      ),
      parse: _sessionFrom,
    );
  }

  Future<AuthUser> me() {
    return _client.send(
      (dio) => dio.get<dynamic>('/auth/me'),
      parse: (data) => AuthUser.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Le pseudo est la seule chose qu'un compte peut changer de lui-même :
  /// l'adresse et la photo restent celles de Google.
  Future<AuthUser> rename(String displayName) {
    return _client.send(
      (dio) => dio.patch<dynamic>(
        '/auth/me',
        data: {'displayName': displayName},
      ),
      parse: (data) => AuthUser.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Enregistre l'acceptation des conditions d'utilisation. Sans corps : il
  /// n'y a rien à nuancer dans un consentement, et la version acceptée se
  /// déduit de la date.
  Future<AuthUser> acceptTerms() {
    return _client.send(
      (dio) => dio.post<dynamic>('/auth/terms'),
      parse: (data) => AuthUser.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Efface le compte et tout ce que le serveur y rattache. Sans retour :
  /// il n'y a plus rien à renvoyer.
  Future<void> deleteAccount() {
    return _client.send(
      (dio) => dio.delete<dynamic>('/auth/me'),
      parse: (_) {},
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
