import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/auth_tokens.dart';

/// Signing in used to report only the failures the repository had foreseen.
/// Anything else — a platform channel giving way, typically the iOS keychain
/// refusing to store the token pair — escaped `signIn()` into the caller's
/// `await`, so the sign-in screen never cleared its spinner and the cause was
/// readable nowhere. These tests guard that no failure can stay invisible.
class _FailingAuthRepository implements AuthRepository {
  _FailingAuthRepository(this.failure);

  final Object failure;

  @override
  Future<AuthUser> signInWithGoogle() async => throw failure;

  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> rename(String displayName) async => throw failure;

  @override
  Future<void> deleteAccount() async => throw failure;

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<String?> signInWith(Object failure) async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider
          .overrideWithValue(_FailingAuthRepository(failure)),
    ]);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    return container.read(authControllerProvider.notifier).signIn();
  }

  test('an unexpected platform failure is reported instead of thrown',
      () async {
    final message = await signInWith(
      PlatformException(code: 'keychain error', message: 'OSStatus -34018'),
    );

    expect(message, isNotNull);
    expect(message, contains('keychain error'));
  });

  test('an anticipated failure keeps its own wording', () async {
    final message = await signInWith(
      const AuthFailure('Configuration Google invalide pour cette application.'),
    );

    expect(message, 'Configuration Google invalide pour cette application.');
  });

  test('a cancellation stays silent', () async {
    final message = await signInWith(
      const AuthFailure('Connexion annulée.', isCancellation: true),
    );

    expect(message, isNull);
  });

  test('the session is left signed out after a failure', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(
        _FailingAuthRepository(Exception('boom')),
      ),
    ]);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await container.read(authControllerProvider.notifier).signIn();

    expect(container.read(authControllerProvider).value, isNull);
  });
}
