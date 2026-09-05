import 'package:google_sign_in/google_sign_in.dart';

import '../../config/app_config.dart';
import '../remote/api_client.dart';
import '../remote/api_exception.dart';
import '../remote/auth_api.dart';
import '../remote/auth_tokens.dart';
import '../remote/token_store.dart';

/// A sign-in failure worth showing to the user, in French.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.isCancellation = false});

  final String message;

  /// The user backed out of the Google dialog: not an error to shout about.
  final bool isCancellation;

  @override
  String toString() => message;
}

/// Owns the account lifecycle: Google identity in, Questbook session out.
class AuthRepository {
  AuthRepository(this._api, this._client, this._store);

  final AuthApi _api;
  final ApiClient _client;
  final TokenStore _store;

  bool _initialized = false;

  /// `GoogleSignIn.instance` must be initialised exactly once before any other
  /// call on it, hence the guard.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  /// Restores a session from the securely stored tokens, or returns null when
  /// there is none. A rejected token is discarded; an unreachable server is
  /// not, since being offline must not sign the user out.
  Future<AuthUser?> restoreSession() async {
    if (await _store.read() == null) return null;

    try {
      final user = await _api.me();
      await _store.writeUser(user);
      return user;
    } on ApiException catch (error) {
      if (error.isRetryable) {
        return _store.readUser();
      }
      await _client.clearTokens();
      return null;
    }
  }

  Future<AuthUser> signInWithGoogle() async {
    await _ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const AuthFailure(
        'La connexion Google n’est pas disponible sur cette plateforme.',
      );
    }

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      throw _translate(error);
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      // Almost always a configuration problem: no serverClientId, or an OAuth
      // client whose SHA-1 does not match the signing key of this build.
      throw const AuthFailure(
        'Google n’a pas renvoyé de jeton d’identité. Vérifie la configuration '
        'du client OAuth (identifiant client web et empreinte SHA-1).',
      );
    }

    try {
      final session = await _api.signInWithGoogle(idToken);
      await _client.setTokens(session.tokens);
      await _store.writeUser(session.user);
      return session.user;
    } on ApiException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  Future<void> signOut() async {
    final tokens = await _store.read();

    if (tokens != null) {
      try {
        await _api.logout(tokens.refreshToken);
      } on ApiException {
        // Revoking server-side is best effort: the local tokens are dropped
        // either way, and the refresh token expires on its own.
      }
    }

    await _client.clearTokens();

    if (_initialized) {
      await GoogleSignIn.instance.signOut();
    }
  }

  AuthFailure _translate(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => const AuthFailure(
          'Connexion annulée.',
          isCancellation: true,
        ),
      GoogleSignInExceptionCode.interrupted ||
      GoogleSignInExceptionCode.uiUnavailable =>
        const AuthFailure('Connexion interrompue, réessaie.'),
      GoogleSignInExceptionCode.clientConfigurationError => const AuthFailure(
          'Configuration Google invalide pour cette application.',
        ),
      _ => AuthFailure('Échec de la connexion Google : ${error.description}'),
    };
  }
}
