import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/sync/sync_service.dart';

/// Signing in used to kick off a pass by reading the sync controller from the
/// auth controller, which closed a dependency cycle — the sync controller
/// already listens to the auth one — and blew up at runtime the moment anyone
/// actually signed in. Publishing the user is now the only trigger, so these
/// tests guard the wiring that carries that responsibility.
class _RecordingSyncService implements SyncService {
  final List<String> accountIds = [];

  @override
  Future<SyncReport> synchronize({required String accountId}) async {
    accountIds.add(accountId);
    return const SyncReport();
  }
}

const _user = AuthUser(
  id: 'user-1',
  email: 'joueur@example.com',
  displayName: 'Joueur',
  pictureUrl: null,
);

void main() {
  // The sync controller installs an AppLifecycleListener.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSyncService service;
  late ProviderContainer container;

  setUp(() {
    service = _RecordingSyncService();
    container = ProviderContainer(
      overrides: [syncServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  /// Reading the notifier is what the auth gate does to keep the controller
  /// alive; it is also the read that used to throw.
  ///
  /// The auth controller's own asynchronous build is settled first, so that
  /// the session changes each test makes are the only thing the listener has
  /// to react to.
  Future<SyncController> startSession() async {
    final controller = container.read(syncControllerProvider.notifier);
    await container.read(authControllerProvider.future);
    return controller;
  }

  void publishSession(AuthUser? user) {
    container.read(authControllerProvider.notifier).state =
        AsyncValue.data(user);
  }

  test('the sync controller can be created without a circular dependency', () {
    expect(() => container.read(syncControllerProvider.notifier),
        returnsNormally);
  });

  test('signing in starts a pass for the new account', () async {
    await startSession();
    expect(service.accountIds, isEmpty);

    publishSession(_user);
    await pumpEventQueue();

    expect(service.accountIds, ['user-1']);
  });

  test('a pass is not restarted when the same account is republished',
      () async {
    await startSession();
    publishSession(_user);
    await pumpEventQueue();

    publishSession(_user);
    await pumpEventQueue();

    expect(service.accountIds, hasLength(1));
  });

  test('switching account starts a pass for the new one', () async {
    await startSession();
    publishSession(_user);
    await pumpEventQueue();

    publishSession(const AuthUser(
      id: 'user-2',
      email: 'autre@example.com',
      displayName: 'Autre',
      pictureUrl: null,
    ));
    await pumpEventQueue();

    expect(service.accountIds, ['user-1', 'user-2']);
  });

  test('signing out does not start a pass', () async {
    await startSession();

    publishSession(null);
    await pumpEventQueue();

    expect(service.accountIds, isEmpty);
  });

  test('a manual pass is ignored while nobody is signed in', () async {
    final controller = await startSession();

    await controller.synchronize();

    expect(service.accountIds, isEmpty);
  });
}
