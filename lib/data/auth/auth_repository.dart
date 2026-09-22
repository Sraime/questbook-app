import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/app_config.dart';
import '../../firebase_options.dart';
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
      // iOS reads GIDClientID from Info.plist too; passing it here keeps the
      // Dart init self-contained if a future plugin version stops doing that.
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
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
        'du client OAuth (identifiant client web, empreinte SHA-1 Android, '
        'schéma d’URL iOS).',
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

  /// L'autre porte, celle qu'Apple impose sur son store.
  ///
  /// Le nom est demandé dans les scopes et remis **une seule fois**, à la
  /// première autorisation : Apple ne le redonne jamais, et il n'est pas dans
  /// le jeton. C'est donc ici qu'il faut le transmettre, sous peine de ne plus
  /// jamais l'avoir.
  Future<AuthUser> signInWithApple() async {
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleException catch (error) {
      throw _translateApple(error);
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw const AuthFailure(
        'Apple n’a pas renvoyé de jeton d’identité. Réessaie, ou connecte-toi '
        'avec Google.',
      );
    }

    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .join(' ')
        .trim();

    try {
      final session = await _api.signInWithApple(
        identityToken,
        displayName: name.isEmpty ? null : name,
      );
      await _client.setTokens(session.tokens);
      await _store.writeUser(session.user);
      return session.user;
    } on ApiException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  /// Le profil en cache suit aussitôt : c'est lui qu'un démarrage hors ligne
  /// relit, et il montrerait sinon l'ancien pseudo jusqu'à la prochaine
  /// connexion réussie.
  Future<AuthUser> rename(String displayName) async {
    final user = await _api.rename(displayName);
    await _store.writeUser(user);
    return user;
  }

  /// Accepte les conditions d'utilisation. Le profil en cache suit, sans
  /// quoi un démarrage hors ligne rebarrerait l'écran sur un consentement
  /// déjà donné.
  Future<AuthUser> acceptTerms() async {
    final user = await _api.acceptTerms();
    await _store.writeUser(user);
    return user;
  }

  /// Efface le compte côté serveur, puis referme la session ici.
  ///
  /// L'appel réseau passe d'abord : si le serveur refuse, l'appareil reste
  /// connecté à un compte qui existe toujours, ce qui est la vérité. Ensuite
  /// seulement les jetons partent — inutile de révoquer quoi que ce soit, la
  /// suppression a emporté jusqu'aux jetons de rafraîchissement.
  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    await _client.clearTokens();

    if (_initialized) {
      await GoogleSignIn.instance.signOut();
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

  AuthFailure _translateApple(SignInWithAppleException error) {
    assert(() {
      debugPrint('SignInWithAppleException: $error');
      return true;
    }());

    if (error case SignInWithAppleAuthorizationException(:final code)) {
      return switch (code) {
        AuthorizationErrorCode.canceled => const AuthFailure(
            'Connexion annulée.',
            isCancellation: true,
          ),
        // « notInteractive » signale une demande faite sans interface
        // disponible, ce qui du point de vue du joueur ressemble a un
        // renoncement : rien ne s'est affiche.
        AuthorizationErrorCode.notInteractive ||
        AuthorizationErrorCode.notHandled =>
          const AuthFailure('Connexion interrompue, réessaie.'),
        AuthorizationErrorCode.invalidResponse => const AuthFailure(
            'Réponse inattendue d’Apple. Réessaie.',
          ),
        _ => const AuthFailure(
            'Échec de la connexion Apple. Réessaie, ou connecte-toi avec '
            'Google.',
          ),
      };
    }

    // Un appareil ou une plateforme qui ne sait pas la servir : le bouton ne
    // devrait pas y etre, mais le dire vaut mieux qu'un echec muet.
    if (error is SignInWithAppleNotSupportedException) {
      return const AuthFailure(
        'La connexion Apple n’est pas disponible sur cet appareil.',
      );
    }

    return const AuthFailure(
      'Échec de la connexion Apple. Réessaie, ou connecte-toi avec Google.',
    );
  }

  AuthFailure _translate(GoogleSignInException error) {
    // Credential Manager reports an environment it simply cannot serve — Play
    // Services too old to parse the request, no Google account on the device —
    // as an ordinary cancellation. Silence is right for the user, who did tap
    // "cancel" as far as the system is concerned, but it leaves the button
    // looking inert to whoever is debugging, hence the trace.
    assert(() {
      debugPrint(
        'GoogleSignInException(${error.code.name}): ${error.description}',
      );
      return true;
    }());

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
      GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
          'Les services Google Play de cet appareil sont trop anciens ou '
          'indisponibles. Mets-les à jour puis réessaie.',
        ),
      _ => AuthFailure('Échec de la connexion Google : ${error.description}'),
    };
  }
}
