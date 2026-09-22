import 'dart:async';

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
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/game_master_screen.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/panels/watched_board_panel.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/game_master/widgets/board_token_view.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

const _account = AuthUser(
  id: 'player-1',
  email: 'robin@example.com',
  displayName: 'Robin',
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

/// Ce qu'un joueur voit de la session qu'il regarde : deux volets, un plateau
/// qui bouge tout seul, et rien de ce que le MJ prépare de son côté.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  RemoteGameTable tableFor(TableRole role) => RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        ownerId: 'gm-1',
        role: role,
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
    startsAt: now.subtract(const Duration(hours: 2)),
    location: 'Chez Marie',
    status: 'scheduled',
    attendances: const [],
    myStatus: AttendanceStatus.yes,
    myCharacter: null,
  );

  const oneToken =
      '[{"id":"t1","kind":"character","color":"red","x":0.5,"y":0.5,"size":0.1}]';

  /// Le canal du plateau, sous contrôle du test : il pousse quand il veut, et
  /// tombe en panne quand on le lui demande.
  late StreamController<RemoteSessionBoard> live;

  setUp(() => live = StreamController<RemoteSessionBoard>.broadcast());
  tearDown(() => live.close());

  const emptyBoard = RemoteSessionBoard(mapId: null, tokens: '[]', revision: 0);

  Future<void> pumpSession(
    WidgetTester tester, {
    TableRole role = TableRole.player,
    Size size = const Size(2000, 1300),
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        sessionBoardDaoProvider.overrideWithValue(SessionBoardDao(db)),
        boardCatalogueProvider.overrideWithValue(boardAssetSections),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async =>
              TableDetail(table: tableFor(role), sessions: [session]),
        ),
        liveSessionBoardProvider.overrideWith((ref, sessionId) => live.stream),
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

    // Le plateau vide d'un MJ qui n'a encore rien posé. Sans lui, le volet
    // tourne sa roue d'attente et `pumpAndSettle` ne rend jamais la main —
    // ce qui est le comportement voulu à l'écran, pas dans un test.
    await tester.pump();
    live.add(emptyBoard);
    await tester.pumpAndSettle();
  }

  Future<void> push(WidgetTester tester, RemoteSessionBoard board) async {
    live.add(board);
    await tester.pumpAndSettle();
  }

  testWidgets('le joueur arrive sur le plateau', (tester) async {
    await pumpSession(tester);

    expect(find.byType(WatchedBoardPanel), findsOneWidget);
  });

  testWidgets('le MJ, lui, arrive toujours sur les détails', (tester) async {
    await pumpSession(tester, role: TableRole.gameMaster);

    expect(find.byType(WatchedBoardPanel), findsNothing);
    expect(find.text('Détails'), findsWidgets);
  });

  testWidgets('deux volets pour le joueur, six pour le MJ', (tester) async {
    await pumpSession(tester);

    expect(find.text('Plateau'), findsOneWidget);
    expect(find.text('Investigateurs'), findsOneWidget);
    // Ni la séance à corriger, ni le scénario que le MJ raconte, ni ses notes.
    expect(find.text('Détails'), findsNothing);
    expect(find.text('Scénario'), findsNothing);
    expect(find.text('Notes'), findsNothing);
  });

  testWidgets('le joueur ne pose rien sur le plateau', (tester) async {
    await pumpSession(tester);
    await push(tester, const RemoteSessionBoard(mapId: null, tokens: oneToken, revision: 1));

    // Pas « désactivé » : aucun tiroir, aucune cible de dépôt, aucun geste.
    expect(find.byType(BoardPanel), findsNothing);
    expect(find.byType(Draggable<BoardAsset>), findsNothing);
    expect(find.byType(DragTarget<BoardAsset>), findsNothing);
    expect(find.text('Rechercher un pion…'), findsNothing);
  });

  testWidgets('ce que le MJ pose apparaît chez le joueur', (tester) async {
    await pumpSession(tester);

    expect(find.byType(BoardTokenView), findsNothing);

    await push(tester, const RemoteSessionBoard(mapId: null, tokens: oneToken, revision: 1));
    expect(find.byType(BoardTokenView), findsOneWidget);

    // Retiré chez le MJ, retiré chez le joueur : c'est le plateau entier qui
    // arrive, pas un correctif.
    await push(tester, const RemoteSessionBoard(mapId: null, tokens: '[]', revision: 2));
    expect(find.byType(BoardTokenView), findsNothing);
  });

  testWidgets('le plateau d’avant reste à l’écran quand le canal tombe',
      (tester) async {
    await pumpSession(tester);
    await push(tester, const RemoteSessionBoard(mapId: null, tokens: oneToken, revision: 1));

    live.addError(
      const ApiException(code: 'NETWORK', message: 'Pas de réseau', statusCode: null),
    );
    // `pump` et non `pumpAndSettle` : Riverpod se rebranche aussitôt sur le
    // canal et efface l'incident, alors qu'à l'écran il dure le temps du
    // tunnel.
    await tester.pump();
    await tester.pump();
    // Un joueur qui passe sous un tunnel n'a pas à voir la table disparaître.
    expect(find.byType(BoardTokenView), findsOneWidget);
    expect(find.text('Pas de réseau'), findsOneWidget);

    // Se rebrancher ne suffit pas à lever l'avertissement : tant que le MJ
    // n'a rien repoussé, ce qui est à l'écran date d'avant la coupure.
    await tester.pumpAndSettle();
    expect(find.text('Pas de réseau'), findsOneWidget);

    await push(tester, const RemoteSessionBoard(mapId: null, tokens: '[]', revision: 2));
    expect(find.text('Pas de réseau'), findsNothing);
  });

  testWidgets('les PNJ restent la préparation du MJ', (tester) async {
    await pumpSession(tester);
    await tester.tap(find.text('Investigateurs').first);
    await tester.pumpAndSettle();

    expect(find.text('Investigateurs'), findsWidgets);
    expect(find.text('Personnages non-joueurs'), findsNothing);
    expect(find.text('PNJ'), findsNothing);
    expect(find.textContaining('Ajouter'), findsNothing);
  });

  testWidgets('sur un téléphone, les deux volets gardent leur nom',
      (tester) async {
    // Six volets tenaient en icônes seules ; deux ont la place d'être nommés,
    // et un joueur qui n'a pas l'habitude de l'écran en a besoin.
    await pumpSession(tester, size: const Size(1080, 2000));

    expect(find.text('Plateau'), findsOneWidget);
    expect(find.text('Investigateurs'), findsOneWidget);
  });

  test('le siège décide des volets et de celui où l’on atterrit', () {
    expect(SessionSeat.gameMaster.panels, GameMasterPanel.values);
    expect(SessionSeat.gameMaster.landing, GameMasterPanel.details);

    expect(SessionSeat.player.panels, [
      GameMasterPanel.board,
      GameMasterPanel.characters,
    ]);
    expect(SessionSeat.player.landing, GameMasterPanel.board);
  });

  testWidgets('un pion acheté par le MJ se dessine chez qui ne l’a pas',
      (tester) async {
    // Le catalogue du joueur est vide : il n'a rien acheté. C'est l'achat qui
    // décide de ce qu'on pose, pas de ce qu'on voit — filtrer ici rendrait des
    // ronds rouges là où le MJ a posé sa créature.
    await pumpSession(tester);
    await push(
      tester,
      const RemoteSessionBoard(
        mapId: null,
        tokens: '[{"id":"t1","kind":"character","color":"red",'
            '"assetKey":"grand_ancien","x":0.5,"y":0.5,"size":0.1}]',
        revision: 1,
      ),
    );

    final drawn = tester.widget<BoardTokenView>(find.byType(BoardTokenView));
    expect(drawn.image, purchasableBoardAssets['grand_ancien']!.image);
  });
}
