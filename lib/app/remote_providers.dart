import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/auth/auth_repository.dart';
import '../data/local/remote_cache_dao.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';
import '../data/remote/auth_api.dart';
import '../data/remote/auth_tokens.dart';
import '../data/remote/character_api.dart';
import '../data/remote/notification_api.dart';
import '../data/remote/session_api.dart';
import '../data/remote/table_api.dart';
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

  // One direction only. The controller needs a way to knock on the server's
  // door, and reaching for `apiClientProvider` from inside it would close a
  // cycle with the line below.
  final connectivity = ref.read(connectivityProvider.notifier)..attach(client);
  client.onReachability = (reachable) =>
      connectivity.report(reachable: reachable);

  return client;
});

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final characterApiProvider = Provider<CharacterApi>(
  (ref) => CharacterApi(ref.watch(apiClientProvider)),
);

final tableApiProvider = Provider<TableApi>(
  (ref) => TableApi(ref.watch(apiClientProvider)),
);

final sessionApiProvider = Provider<SessionApi>(
  (ref) => SessionApi(ref.watch(apiClientProvider)),
);

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(apiClientProvider)),
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
      // in, but starting that pass from here would close a dependency cycle:
      // SyncController already listens to this provider. Publishing the new
      // user above is enough to set it off.
      return null;
    } on AuthFailure catch (error) {
      state = const AsyncValue.data(null);
      return error.isCancellation ? null : error.message;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    // The cached tables belong to the account that just left. They are keyed
    // by it and so could never be shown to anyone else, but keeping another
    // player's table around on a shared device serves no one.
    await RemoteCacheDao(ref.read(appDatabaseProvider)).clear();
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

/// Whether the API can be reached right now.
///
/// Deliberately measured rather than declared: the device can hold a perfect
/// Wi-Fi signal behind a captive portal, so what counts is whether the server
/// answers. Every request reports back, and while the answer is no, a light
/// probe keeps asking so the app notices the network returning on its own.
class ConnectivityController extends Notifier<bool> {
  static const _probeInterval = Duration(seconds: 20);

  Timer? _probe;
  ApiClient? _client;

  /// Handed over by [apiClientProvider] as it builds.
  void attach(ApiClient client) => _client = client;

  @override
  bool build() {
    ref.onDispose(() => _probe?.cancel());

    // Coming back to the app is the likeliest moment for the network to have
    // changed — the user may well have gone looking for it.
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (!state) unawaited(recheck());
      },
    );
    ref.onDispose(lifecycle.dispose);

    // Optimistic: the first request will say otherwise soon enough, and
    // starting offline would flash the banner on every launch.
    return true;
  }

  void report({required bool reachable}) {
    if (reachable == state) return;
    state = reachable;
    reachable ? _probe?.cancel() : _scheduleProbe();
  }

  void _scheduleProbe() {
    _probe?.cancel();
    _probe = Timer.periodic(_probeInterval, (_) => unawaited(recheck()));
  }

  /// Checks immediately rather than waiting for the next tick — used when the
  /// app comes back to the foreground, and behind the banner's retry.
  Future<void> recheck() async {
    if (_client case final client?) {
      report(reachable: await client.ping());
    }
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityController, bool>(ConnectivityController.new);

/// True when the user may change anything at all.
///
/// Without a network the app is an archive: the tables live on the server and
/// are shared with other players, and a character edited here would race with
/// whatever the account did elsewhere. Reading is welcome, writing waits.
final canWriteProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).value != null &&
      ref.watch(connectivityProvider);
});
