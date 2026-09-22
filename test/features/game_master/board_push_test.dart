import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/session_board_dao.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/game_master_screen.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

const _account = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _account;

  @override
  Future<AuthUser> signInWithGoogle() async => _account;

  @override
  Future<AuthUser> rename(String displayName) async => _account;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

/// Note ce que le MJ remonte. `noSuchMethod` laisse le reste de l'API de
/// côté : ce test ne parle que du plateau, et tout autre appel doit échouer
/// bruyamment plutôt que de rendre une valeur inventée.
class _RecordingSessionApi implements SessionApi {
  final List<({String tokens, String? mapId})> pushes = [];
  bool offline = false;

  @override
  Future<RemoteSessionBoard> pushBoard(
    String sessionId, {
    required String tokens,
    String? mapId,
  }) async {
    if (offline) {
      throw const ApiException(
        code: 'NETWORK',
        message: 'Pas de réseau',
        statusCode: null,
      );
    }

    pushes.add((tokens: tokens, mapId: mapId));
    return RemoteSessionBoard(
      tokens: tokens,
      mapId: mapId,
      revision: pushes.length,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  final table = RemoteGameTable(
    id: 'table-1',
    title: 'Les ombres d’Arkham',
    ownerId: 'gm-1',
    role: TableRole.gameMaster,
    createdAt: now,
    updatedAt: now,
    members: const [],
    pendingInvitations: const [],
    nextSessionAt: null,
  );

  final session = RemoteGameSession(
    id: 'session-1',
    tableId: 'table-1',
    title: 'Chapitre III — Les ruines',
    description: null,
    startsAt: now.add(const Duration(days: 2)),
    location: 'Chez Marie',
    status: 'scheduled',
    attendances: const [],
    myStatus: null,
    myCharacter: null,
    scenarioId: null,
    scenario: null,
  );

  Future<_RecordingSessionApi> pumpGameMaster(WidgetTester tester) async {
    final api = _RecordingSessionApi();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Une tablette : le mode MJ y déploie son rail, et le plateau y a la
    // place qu'un glissement demande.
    tester.view.physicalSize = const Size(2000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        sessionApiProvider.overrideWithValue(api),
        sessionBoardDaoProvider.overrideWithValue(SessionBoardDao(db)),
        boardCatalogueProvider.overrideWithValue(boardAssetSections),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async => TableDetail(table: table, sessions: [session]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_account);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameMasterScreen(tableId: 'table-1', sessionId: 'session-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  /// Ouvre le volet du plateau, qui n'est pas celui d'accueil.
  Future<void> openBoard(WidgetTester tester) async {
    await tester.tap(find.text('Plateau').first);
    await tester.pumpAndSettle();
    expect(find.byType(BoardPanel), findsOneWidget);
  }

  /// Fait glisser le premier pion du tiroir au centre de la carte.
  Future<void> dropToken(WidgetTester tester) async {
    final drawn = find.byType(Draggable<BoardAsset>).first;
    final board = tester.getRect(find.byType(DragTarget<BoardAsset>).first);

    final gesture = await tester.startGesture(tester.getCenter(drawn));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(board.center);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('poser un pion le montre aussi aux joueurs', (tester) async {
    final api = await pumpGameMaster(tester);
    await openBoard(tester);

    expect(api.pushes, isEmpty);

    await dropToken(tester);

    expect(api.pushes, hasLength(1));
    // Le plateau entier, et non ce qui vient de changer : l'appareil du MJ
    // détient la vérité complète.
    expect(api.pushes.single.tokens, startsWith('[{'));
  });

  testWidgets('changer de carte se voit aussi', (tester) async {
    final api = await pumpGameMaster(tester);
    await openBoard(tester);

    await tester.tap(find.text('Grille vierge').first);
    await tester.pumpAndSettle();

    expect(api.pushes, isNotEmpty);
    expect(api.pushes.last.mapId, 'grille');
  });

  testWidgets('sans réseau, le plateau reste jouable', (tester) async {
    // L'appareil du MJ garde la vérité : une soirée dans une cave doit
    // continuer de marcher, et un plateau qui demanderait le réseau pour
    // déplacer un pion serait inutile là où on l'utilise.
    final api = await pumpGameMaster(tester);
    api.offline = true;
    await openBoard(tester);

    await dropToken(tester);

    expect(api.pushes, isEmpty);
    // Le pion est bien sur la carte malgré le refus du serveur.
    expect(find.byType(BoardPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le réseau qui revient rattrape ce qui s’est joué sans lui',
      (tester) async {
    // Sinon un MJ ayant déplacé ses pions hors couverture les verrait figés
    // chez ses joueurs jusqu'à son geste suivant, qui peut ne jamais venir.
    final api = await pumpGameMaster(tester);
    api.offline = true;
    await openBoard(tester);
    await dropToken(tester);
    expect(api.pushes, isEmpty);

    api.offline = false;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BoardPanel)),
    );
    container.read(connectivityProvider.notifier).report(reachable: false);
    await tester.pump();
    container.read(connectivityProvider.notifier).report(reachable: true);
    await tester.pumpAndSettle();

    expect(api.pushes, hasLength(1));
  });
}
