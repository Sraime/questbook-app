import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Persists the API token pair in the platform keystore (Android EncryptedShared
/// Preferences / iOS Keychain) rather than in SharedPreferences, since a
/// refresh token is a 30-day credential.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  static const _accessKey = 'questbook.access_token';
  static const _refreshKey = 'questbook.refresh_token';
  static const _userKey = 'questbook.user';

  /// `errSecDuplicateItem`, as the Keychain reports it through the plugin.
  static const _duplicateItem = -25299;

  final FlutterSecureStorage _storage;

  /// Writes through the accessibility mismatch left by builds older than the
  /// one that pinned [KeychainAccessibility.first_unlock_this_device].
  ///
  /// Accessibility filters reads but is not part of what makes a Keychain item
  /// unique. An entry written under the previous, laxer setting is therefore
  /// invisible to [FlutterSecureStorage.read] — which asks for the current one
  /// — while still colliding on insert. Sign-in then fails for good on a device
  /// that once ran an older build, since the Keychain outlives even an
  /// uninstall. Deleting ignores accessibility, so it clears the stale entry.
  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      if (error.details != _duplicateItem) rethrow;
      await _storage.delete(key: key);
      await _storage.write(key: key, value: value);
    }
  }

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
    await _write(
      _userKey,
      jsonEncode({
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
    await _write(_accessKey, tokens.accessToken);
    await _write(_refreshKey, tokens.refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}
