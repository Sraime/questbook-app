import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Persists the API token pair in the platform keystore (Android EncryptedShared
/// Preferences / iOS Keychain) rather than in SharedPreferences, since a
/// refresh token is a 30-day credential.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'questbook.access_token';
  static const _refreshKey = 'questbook.refresh_token';
  static const _userKey = 'questbook.user';

  final FlutterSecureStorage _storage;

  /// Cached profile, so a launch without connectivity can still show the user
  /// as signed in instead of bouncing them to the sign-in screen.
  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeUser(AuthUser user) async {
    await _storage.write(
      key: _userKey,
      value: jsonEncode({
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'pictureUrl': user.pictureUrl,
      }),
    );
  }

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
