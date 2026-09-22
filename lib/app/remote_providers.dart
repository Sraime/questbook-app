import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/auth/auth_repository.dart';
import '../data/local/remote_cache_dao.dart';
import '../data/local/downloaded_scenario_dao.dart';
import '../data/local/session_board_dao.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';
import '../data/remote/auth_api.dart';
import '../data/remote/auth_tokens.dart';
import '../data/remote/character_api.dart';
import '../data/remote/notification_api.dart';
import '../data/remote/report_api.dart';
import '../data/remote/session_api.dart';
import '../data/remote/scenario_api.dart';
import '../data/remote/shop_api.dart';
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

final scenarioApiProvider = Provider<ScenarioApi>(
  (ref) => ScenarioApi(ref.watch(apiClientProvider)),
);

final shopApiProvider = Provider<ShopApi>(
  (ref) => ShopApi(ref.watch(apiClientProvider)),
);

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(apiClientProvider)),
);

final reportApiProvider = Provider<ReportApi>(
  (ref) => ReportApi(ref.watch(apiClientProvider)),
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
    } catch (error, stack) {
      // Everything the repository anticipates arrives as an AuthFailure. What
      // lands here is a platform channel giving way — a keychain refusing a
      // write, a plugin raising on its own. Letting it through would escape
      // into the caller's `await` and leave a spinner turning with the cause
      // shown nowhere, so it is named on screen instead.
      state = const AsyncValue.data(null);
      debugPrint('Sign-in failed: $error\n$stack');
      return 'La connexion a échoué : $error';
    }
  }

  /// Renomme le compte. Lève une [ApiException] que l'écran de profil
  /// affiche : c'est un geste explicite, son échec doit se voir.
  Future<void> rename(String displayName) async {
    final user = await ref.read(authRepositoryProvider).rename(displayName);
    state = AsyncValue.data(user);
  }

  /// Supprime le compte, puis n'en laisse rien sur l'appareil.
  ///
  /// La déconnexion épargne les investigateurs, parce qu'ils remonteront à la
  /// prochaine connexion. Ici il n'y a plus rien où les remonter : les garder
  /// serait conserver ce qu'on a demandé d'effacer.
  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();

    final database = ref.read(appDatabaseProvider);
    await CharacterSyncDao(database).forgetAccount();
    await DownloadedScenarioDao(database).clear();
    await SessionBoardDao(database).clear();
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    // The cached tables belong to the account that just left. They are keyed
    // by it and so could never be shown to anyone else, but keeping another
    // player's table around on a shared device serves no one.
    await RemoteCacheDao(ref.read(appDatabaseProvider)).clear();
    await DownloadedScenarioDao(ref.read(appDatabaseProvider)).clear();
    await SessionBoardDao(ref.read(appDatabaseProvider)).clear();
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
        // Repoussé d'une microtâche : avec `fireImmediately`, un compte déjà
        // connecté déclencherait la passe depuis ce `build`, et
        // `synchronize()` lirait un état qui n'existe pas encore.
        unawaited(Future.microtask(synchronize));
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

  /// Envoie une fiche au serveur dans la foulée du geste qui l'a changée.
  ///
  /// Sans cela, une fiche modifiée attend le prochain retour de l'app au
  /// premier plan — et pendant une partie, personne ne quitte l'app. Le MJ
  /// lit les fiches depuis le serveur : des points de vie perdus à la table
  /// ne lui parviendraient jamais.
  ///
  /// L'état de synchronisation n'est pas touché : `isRunning` sert à décrire
  /// une passe complète, et le faire clignoter à chaque pression sur une
  /// jauge ne dirait plus rien.
  Future<void> pushCharacter(String id) async {
    if (ref.read(authControllerProvider).value == null) return;

    try {
      await ref.read(syncServiceProvider).pushCharacter(id);
    } on ApiException {
      // L'écriture locale, elle, a eu lieu, et la fiche reste marquée : la
      // prochaine passe complète la reprendra. Rien à dire au joueur, qui
      // voit déjà sa modification à l'écran.
    }
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
