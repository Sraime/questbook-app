import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/remote/api_client.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/data/remote/table_api.dart';
import 'package:questbook/data/remote/token_store.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

/// Tables live on the server, so losing the network used to leave the tab with
/// nothing but a retry button. These tests cover the deal struck instead: the
/// last answer is kept, replayed when the server cannot be reached, and dated
/// so nobody mistakes it for the truth.

const _user = AuthUser(
  id: 'user-1',
  email: 'joueur@example.com',
  displayName: 'Joueur',
  pictureUrl: null,
);

final _networkDown = const ApiException(
  code: 'NETWORK_ERROR',
  message: 'Impossible de joindre le serveur Questbook.',
);

final _refused = const ApiException(
  code: 'FORBIDDEN',
  message: 'Tu ne fais pas partie de cette table.',
  statusCode: 403,
);

/// Answers from memory, and can be told to fail instead. Extends the real API
/// classes so the parsing under test is the production one.
class _FakeTableApi extends TableApi {
  _FakeTableApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  ApiException? failure;
  String title = 'Les Inspecteurs Chavillois';
  int calls = 0;

  @override
  Future<dynamic> listRaw() async {
    calls++;
    if (failure case final error?) throw error;
    return {
      'tables': [_table('table-1')],
    };
  }

  Map<String, dynamic> _table(String id) => {
        'id': id,
        'title': title,
        'universeLabel': 'L’Appel de Cthulhu',
        'ownerId': 'user-1',
        'role': 'gm',
        'createdAt': '2026-09-01T10:00:00.000Z',
        'updatedAt': '2026-09-01T10:00:00.000Z',
        'members': <dynamic>[],
        'pendingInvitations': <dynamic>[],
        'nextSessionAt': null,
      };

  @override
  Future<dynamic> pendingInvitationsRaw() async {
    if (failure case final error?) throw error;
    return {'invitations': <dynamic>[]};
  }

  @override
  Future<dynamic> getRaw(String id) async {
    if (failure case final error?) throw error;
    return _table(id);
  }
}

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  ApiException? failure;

  @override
  Future<dynamic> listForTableRaw(String tableId) async {
    if (failure case final error?) throw error;
    return {
      'sessions': [
        {
          'id': 'session-1',
          'tableId': tableId,
          'title': 'Le manoir Corbitt',
          'startsAt': '2026-12-24T19:00:00.000Z',
          'location': 'Chez Robin',
          'status': 'scheduled',
          'attendances': <dynamic>[],
        },
      ],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeTableApi tables;
  late _FakeSessionApi sessions;
  late ProviderContainer container;

  /// The auth controller's own asynchronous build has to settle first: it ends
  /// by publishing "nobody", and would otherwise overwrite the session set
  /// here a moment later.
  Future<void> signIn(AuthUser user) async {
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        AsyncValue.data(user);
  }

  /// The failing cases below all read the `AsyncValue` rather than awaiting
  /// `.future`. That is what the screens watch, and it is also the only form
  /// that reports anything here: a provider nobody listens to is disposed
  /// while its future is still in flight, and that future never completes.

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tables = _FakeTableApi();
    sessions = _FakeSessionApi();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tableApiProvider.overrideWithValue(tables),
        sessionApiProvider.overrideWithValue(sessions),
      ],
    );
    addTearDown(container.dispose);

    await signIn(_user);
  });

  tearDown(() => db.close());

  group('tables overview', () {
    test('serves the cached tables when the server cannot be reached',
        () async {
      final fresh = await container.read(tablesOverviewProvider.future);
      expect(fresh.tables.single.title, 'Les Inspecteurs Chavillois');
      expect(fresh.cachedAt, isNull, reason: 'this one came from the server');

      tables.failure = _networkDown;
      container.invalidate(tablesOverviewProvider);

      final offline = await container.read(tablesOverviewProvider.future);

      expect(offline.tables.single.title, 'Les Inspecteurs Chavillois');
      expect(
        offline.cachedAt,
        isNotNull,
        reason: 'the screen has to be able to say how old this is',
      );
    });

    test('replays the last answer, not an older one', () async {
      await container.read(tablesOverviewProvider.future);

      tables.title = 'Les Inspecteurs Chavillois (renommée)';
      container.invalidate(tablesOverviewProvider);
      await container.read(tablesOverviewProvider.future);

      tables.failure = _networkDown;
      container.invalidate(tablesOverviewProvider);
      final offline = await container.read(tablesOverviewProvider.future);

      expect(offline.tables.single.title, contains('renommée'));
    });

    /// A refusal is news about the account, and showing yesterday's tables
    /// underneath it would bury the one thing worth reading.
    test('lets a refusal through rather than papering over it', () async {
      await container.read(tablesOverviewProvider.future);

      tables.failure = _refused;
      container.invalidate(tablesOverviewProvider);

      final subscription = container.listen(tablesOverviewProvider, (_, _) {});
      addTearDown(subscription.close);
      await pumpEventQueue();

      final error = container.read(tablesOverviewProvider).error;
      expect(error, isA<ApiException>());
      expect((error! as ApiException).statusCode, 403);
    });

    test('fails when there is nothing cached to fall back on', () async {
      tables.failure = _networkDown;

      final subscription = container.listen(tablesOverviewProvider, (_, _) {});
      addTearDown(subscription.close);
      await pumpEventQueue();

      expect(container.read(tablesOverviewProvider).error, isA<ApiException>());
    });

    test('keeps one account out of another one’s cache', () async {
      await container.read(tablesOverviewProvider.future);

      await signIn(const AuthUser(
        id: 'user-2',
        email: 'autre@example.com',
        displayName: 'Autre',
        pictureUrl: null,
      ));
      tables.failure = _networkDown;
      container.invalidate(tablesOverviewProvider);

      final subscription = container.listen(tablesOverviewProvider, (_, _) {});
      addTearDown(subscription.close);
      await pumpEventQueue();

      expect(container.read(tablesOverviewProvider).error, isA<ApiException>());
    });
  });

  group('table detail', () {
    test('serves the cached table and its sessions offline', () async {
      await container.read(tableDetailProvider('table-1').future);

      tables.failure = _networkDown;
      sessions.failure = _networkDown;
      container.invalidate(tableDetailProvider('table-1'));

      final offline = await container.read(tableDetailProvider('table-1').future);

      expect(offline.table.title, 'Les Inspecteurs Chavillois');
      expect(offline.sessions.single.title, 'Le manoir Corbitt');
      expect(offline.cachedAt, isNotNull);
    });

    test('does not answer one table with another one’s copy', () async {
      await container.read(tableDetailProvider('table-1').future);

      tables.failure = _networkDown;
      sessions.failure = _networkDown;

      final provider = tableDetailProvider('table-2');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await pumpEventQueue();

      expect(container.read(provider).error, isA<ApiException>());
    });
  });

  group('writing', () {
    test('is refused while the server is out of reach', () async {
      expect(container.read(canWriteProvider), isTrue);

      container.read(connectivityProvider.notifier).report(reachable: false);

      expect(container.read(canWriteProvider), isFalse);
    });

    test('is refused while nobody is signed in', () async {
      container.read(authControllerProvider.notifier).state =
          const AsyncValue.data(null);

      expect(container.read(canWriteProvider), isFalse);
    });

    test('comes back with the network', () async {
      container.read(connectivityProvider.notifier).report(reachable: false);
      container.read(connectivityProvider.notifier).report(reachable: true);

      expect(container.read(canWriteProvider), isTrue);
    });
  });
}
