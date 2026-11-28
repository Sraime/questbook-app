import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/remote_cache_dao.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/game_master/widgets/projection_dialog.dart';

import 'board_test_session.dart';

const _marie = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _marie;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

/// Le serveur tel que la fenêtre le voit : un lien au plus, qu'il sait dire
/// actif ou non, sans jamais le redonner.
class _FakeSessionApi implements SessionApi {
  _FakeSessionApi({this.active = false});

  bool active;
  int created = 0;
  int stopped = 0;

  @override
  Future<bool> projectionActive(String sessionId) async => active;

  @override
  Future<ProjectionLink> createProjection(String sessionId) async {
    created++;
    active = true;
    return ProjectionLink(
      url: 'https://questbook.nextuscorp.com/projection/jeton-$created',
      opensAt: DateTime.now().subtract(const Duration(hours: 1)),
      closesAt: DateTime.now().add(const Duration(hours: 23)),
    );
  }

  @override
  Future<void> stopProjection(String sessionId) async {
    stopped++;
    active = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppDatabase database;
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  final cacheKey = RemoteCacheDao.projectionKey('session-1');

  Future<void> remember(String url) => RemoteCacheDao(database).write(
        cacheKey,
        _marie.id,
        ProjectionLink(
          url: url,
          opensAt: DateTime.now().subtract(const Duration(hours: 1)),
          closesAt: DateTime.now().add(const Duration(hours: 23)),
        ).toJson(),
      );

  Future<void> openDialog(WidgetTester tester, _FakeSessionApi api) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        appDatabaseProvider.overrideWithValue(database),
        sessionApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_marie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProjectionDialog(
                  context,
                  session: boardTestSession(),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sans lien, le MJ en crée un, et l’appareil le garde',
      (tester) async {
    final api = _FakeSessionApi();
    await openDialog(tester, api);

    await tester.tap(find.widgetWithText(QBButton, 'Créer le lien'));
    await tester.pumpAndSettle();

    expect(api.created, 1);
    expect(
      find.text('https://questbook.nextuscorp.com/projection/jeton-1'),
      findsOneWidget,
    );
    expect(find.textContaining('Valable jusqu’à'), findsOneWidget);

    final cached = await RemoteCacheDao(database).read(cacheKey, _marie.id);
    expect((cached!.data as Map)['url'], endsWith('/jeton-1'));
  });

  testWidgets('un lien gardé et encore actif se montre sans en recréer',
      (tester) async {
    await remember('https://questbook.nextuscorp.com/projection/garde');
    final api = _FakeSessionApi(active: true);
    await openDialog(tester, api);

    expect(
      find.text('https://questbook.nextuscorp.com/projection/garde'),
      findsOneWidget,
    );
    expect(api.created, 0);
  });

  testWidgets('un lien gardé que le serveur a révoqué disparaît',
      (tester) async {
    // Remplacé depuis un autre appareil, ou arrêté : le recopier enverrait la
    // salle sur une page morte.
    await remember('https://questbook.nextuscorp.com/projection/revoque');
    await openDialog(tester, _FakeSessionApi(active: false));

    expect(find.textContaining('/revoque'), findsNothing);
    expect(find.widgetWithText(QBButton, 'Créer le lien'), findsOneWidget);
    expect(await RemoteCacheDao(database).read(cacheKey, _marie.id), isNull);
  });

  testWidgets('copier met le lien dans le presse-papiers', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await remember('https://questbook.nextuscorp.com/projection/garde');
    await openDialog(tester, _FakeSessionApi(active: true));

    await tester.tap(find.widgetWithText(QBButton, 'Copier le lien'));
    await tester.pumpAndSettle();

    expect(copied, 'https://questbook.nextuscorp.com/projection/garde');
  });

  testWidgets('arrêter coupe le lien et l’oublie', (tester) async {
    await remember('https://questbook.nextuscorp.com/projection/garde');
    final api = _FakeSessionApi(active: true);
    await openDialog(tester, api);

    await tester.tap(find.widgetWithText(QBButton, 'Arrêter'));
    await tester.pumpAndSettle();

    expect(api.stopped, 1);
    expect(find.widgetWithText(QBButton, 'Créer le lien'), findsOneWidget);
    expect(await RemoteCacheDao(database).read(cacheKey, _marie.id), isNull);
  });

  testWidgets('un nouveau lien remplace celui qu’on montrait', (tester) async {
    await remember('https://questbook.nextuscorp.com/projection/garde');
    final api = _FakeSessionApi(active: true);
    await openDialog(tester, api);

    await tester.tap(find.widgetWithText(QBButton, 'Nouveau lien'));
    await tester.pumpAndSettle();

    expect(api.created, 1);
    expect(find.textContaining('/garde'), findsNothing);
    expect(find.textContaining('/jeton-1'), findsOneWidget);
  });
}
