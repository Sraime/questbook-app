import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/session_board_dao.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/game_master_screen.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

/// Le canal du plateau vit tant que quelqu'un le regarde, et pas une seconde
/// de plus. C'est ce que promet le `autoDispose` de `liveSessionBoardProvider`,
/// et c'est ce qui se passe — mais rien ne le disait.
///
/// Le jour ou l'on gardera les volets montes pour leur conserver leur etat, un
/// `IndexedStack` suffirait a laisser un socket ouvert toute la soiree : rien
/// ne se verrait a l'ecran, et une table de cinq joueurs qui font l'aller-
/// retour entre les volets ferait tenir au serveur des dizaines de sockets
/// fantomes.
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

  const emptyBoard = RemoteSessionBoard(mapId: null, tokens: '[]', revision: 0);

  /// Ce que le test observe : non pas les octets du socket, mais l'abonnement
  /// au flux qui le tient ouvert. C'est le `onCancel` d'ici qui, en vrai,
  /// declenche le `sink.close()` de `BoardLiveClient`.
  late StreamController<RemoteSessionBoard> live;
  late int watching;
  late int abandoned;

  setUp(() {
    watching = 0;
    abandoned = 0;
    live = StreamController<RemoteSessionBoard>.broadcast(
      onListen: () => watching++,
      onCancel: () => abandoned++,
    );
  });

  tearDown(() => live.close());

  Future<void> pumpSession(
    WidgetTester tester, {
    TableRole role = TableRole.player,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        // Le volet Scenario du MJ passe par la base : sans cet aiguillage, une
        // seconde `AppDatabase` s'ouvrirait pour de vrai a cote de celle-ci.
        appDatabaseProvider.overrideWithValue(db),
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

    // Sortir de la seance passe par `context.go`, donc par un routeur : deux
    // routes suffisent, celle de la seance et celle de la table.
    final router = GoRouter(
      initialLocation: '/tables/table-1/sessions/session-1/mj',
      routes: [
        GoRoute(
          path: '/tables/:id',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Retour à la table'))),
        ),
        GoRoute(
          path: '/tables/:id/sessions/:sessionId/mj',
          builder: (context, state) => const GameMasterScreen(
            tableId: 'table-1',
            sessionId: 'session-1',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Le plateau vide d'un MJ qui n'a encore rien posé. Sans lui, le volet
    // tourne sa roue d'attente et `pumpAndSettle` ne rend jamais la main.
    await tester.pump();
    live.add(emptyBoard);
    await tester.pumpAndSettle();
  }

  testWidgets('le joueur qui regarde le plateau tient un abonnement, un seul',
      (tester) async {
    await pumpSession(tester);

    expect(watching, 1);
    expect(abandoned, 0);
  });

  testWidgets('quitter le volet abandonne le flux', (tester) async {
    await pumpSession(tester);

    await tester.tap(find.text('Investigateurs'));
    await tester.pumpAndSettle();

    expect(abandoned, 1, reason: 'le socket ne survit pas au volet');
  });

  testWidgets('y revenir en ouvre un neuf, plutôt que de rester muet',
      (tester) async {
    await pumpSession(tester);

    await tester.tap(find.text('Investigateurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plateau'));
    // Un abonnement neuf n'herite de rien : le volet attend, roue tournante,
    // que le serveur lui redonne le plateau entier. C'est pour cela que le
    // vrai provider commence par un `GET` avant d'ouvrir le socket.
    await tester.pump();
    live.add(emptyBoard);
    await tester.pumpAndSettle();

    expect(watching, 2);
    expect(abandoned, 1);
  });

  testWidgets('quitter la séance l’abandonne aussi', (tester) async {
    await pumpSession(tester);

    // Sur un ecran etroit, la sortie est le picto de l'entete et non le
    // bouton nomme du rail.
    await tester.tap(find.byIcon(LucideIcons.logOut));
    await tester.pumpAndSettle();

    expect(find.text('Retour à la table'), findsOneWidget);
    expect(abandoned, 1);
  });

  testWidgets('le MJ n’ouvre jamais de canal, même sur son plateau',
      (tester) async {
    await pumpSession(tester, role: TableRole.gameMaster);

    await tester.tap(find.text('Plateau').first);
    await tester.pumpAndSettle();

    expect(watching, 0, reason: 'le MJ écrit le plateau, il ne l’écoute pas');
  });
}
