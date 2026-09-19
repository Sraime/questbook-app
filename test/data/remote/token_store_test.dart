import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/token_store.dart';

/// A Keychain holding an entry the current accessibility cannot see.
///
/// This is what an iPhone that once ran a build older than the privacy fix
/// looks like: reads filter on accessibility and come back empty, while the
/// insert still collides with the hidden entry. Only a delete, which ignores
/// accessibility, gets rid of it.
class HauntedKeychain extends FlutterSecureStorage {
  HauntedKeychain(this.hidden);

  /// Keys written by an older build, invisible until deleted.
  final Set<String> hidden;

  final Map<String, String> visible = {};

  /// Every call received, so a test can tell a retry from a first attempt.
  final List<String> calls = [];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    calls.add('write $key');
    if (hidden.contains(key)) {
      throw PlatformException(
        code: 'Unexpected security result code',
        message: 'Code: -25299, Message: The specified item already exists in '
            'the keychain.',
        details: -25299,
      );
    }
    visible[key] = value!;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    calls.add('read $key');
    return visible[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    calls.add('delete $key');
    hidden.remove(key);
    visible.remove(key);
  }
}

void main() {
  const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

  test('stores the tokens over entries left by an older build', () async {
    final keychain = HauntedKeychain({
      'questbook.access_token',
      'questbook.refresh_token',
    });

    await TokenStore(keychain).write(tokens);

    expect(await TokenStore(keychain).read(), isNotNull);
    expect(keychain.visible['questbook.access_token'], 'access');
    expect(keychain.visible['questbook.refresh_token'], 'refresh');
  });

  test('stores the profile over an entry left by an older build', () async {
    final keychain = HauntedKeychain({'questbook.user'});
    const user = AuthUser(id: 'id', email: 'joueur@example.com');

    await TokenStore(keychain).writeUser(user);

    expect((await TokenStore(keychain).readUser())?.email,
        'joueur@example.com');
  });

  test('writes straight through when nothing is in the way', () async {
    final keychain = HauntedKeychain({});

    await TokenStore(keychain).write(tokens);

    expect(keychain.calls, [
      'write questbook.access_token',
      'write questbook.refresh_token',
    ]);
  });

  test('lets any other keychain failure surface', () async {
    final keychain = _FailingKeychain();

    expect(
      () => TokenStore(keychain).write(tokens),
      throwsA(isA<PlatformException>()),
    );
  });
}

/// Fails every write with something other than a duplicate, which must not be
/// mistaken for the stale-entry case and retried.
class _FailingKeychain extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw PlatformException(
      code: 'Unexpected security result code',
      message: 'Code: -34018',
      details: -34018,
    );
  }
}
