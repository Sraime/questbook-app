import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/auth/auth_repository.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';
import '../data/remote/auth_api.dart';
import '../data/remote/auth_tokens.dart';
import '../data/remote/character_api.dart';
import '../data/remote/token_store.dart';
import '../data/sync/character_sync_dao.dart';
import '../data/sync/sync_service.dart';
import 'providers.dart';

/// Wiring for everything that talks to the Questbook API. Kept apart from
/// `providers.dart` so the purely local half of the app stays readable.

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    AppConfig.apiBaseUrl,
    ref.watch(tokenStoreProvider),
  );

  // A refresh token the server refuses is unrecoverable: re-running the auth
  // controller finds no tokens left and drops the app back to signed out.
  client.onSessionExpired = () => ref.invalidate(authControllerProvider);

  return client;
});

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final characterApiProvider = Provider<CharacterApi>(
  (ref) => CharacterApi(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  );
});

/// The signed-in account, or null when the app runs offline-only.
class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    if (!AppConfig.isRemoteEnabled) return null;
    return ref.read(authRepositoryProvider).restoreSession();
  }

  /// Returns the error message to display, or null on success. Cancelling the
  /// Google dialog is silent.
  Future<String?> signIn() async {
    state = const AsyncValue.loading();

    try {
      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
      state = AsyncValue.data(user);
      // Uploading whatever was created offline is the whole point of signing
      // in, so it happens immediately rather than waiting for a manual pull.
      unawaited(ref.read(syncControllerProvider.notifier).synchronize());
      return null;
    } on AuthFailure catch (error) {
      state = const AsyncValue.data(null);
      return error.isCancellation ? null : error.message;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(characterApiProvider),
    CharacterSyncDao(ref.watch(appDatabaseProvider)),
  );
});

class SyncState {
  const SyncState({this.isRunning = false, this.lastSyncedAt, this.errorMessage});

  final bool isRunning;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
}

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() {
    // Signing in (or restoring a session at launch) should immediately bring
    // the device back in step with the account.
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (previous, next) {
      final user = next.value;
      if (user != null && previous?.value?.id != user.id) {
        unawaited(synchronize());
      }
    }, fireImmediately: true);

    // Coming back to the app is both the moment its data is most likely stale
    // and the moment edits made offline need to leave the device. Without
    // this, a character created offline would sit here until the user thought
    // to press the refresh button.
    final lifecycle = AppLifecycleListener(onResume: () => unawaited(synchronize()));
    ref.onDispose(lifecycle.dispose);

    return const SyncState();
  }

  Future<void> synchronize() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || state.isRunning) return;

    state = SyncState(isRunning: true, lastSyncedAt: state.lastSyncedAt);

    try {
      final report =
          await ref.read(syncServiceProvider).synchronize(accountId: user.id);

      state = SyncState(
        lastSyncedAt: report.isSuccess ? DateTime.now() : state.lastSyncedAt,
        errorMessage: report.error?.message,
      );
    } on ApiException catch (error) {
      state = SyncState(
        lastSyncedAt: state.lastSyncedAt,
        errorMessage: error.message,
      );
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);

/// Set when the user chooses "Continuer hors ligne" on the sign-in screen, so
/// the gate lets them through for the rest of the session without an account.
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
}

final offlineModeProvider =
    NotifierProvider<OfflineModeNotifier, bool>(OfflineModeNotifier.new);
