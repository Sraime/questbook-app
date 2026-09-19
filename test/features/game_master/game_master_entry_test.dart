import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/game_master/game_master_space.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  RemoteGameTable tableFor(TableRole role) => RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        universeLabel: 'Appel de Cthulhu',
        ownerId: 'gm-1',
        role: role,
        createdAt: now,
        updatedAt: now,
        members: [
          RemoteTableMember(
            userId: 'gm-1',
            role: TableRole.gameMaster,
            joinedAt: now,
            user: const RemoteUser(
              id: 'gm-1',
              displayName: 'Marie',
              pictureUrl: null,
            ),
          ),
        ],
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

  Future<void> pumpTable(
    WidgetTester tester, {
    required Size screen,
    TableRole role = TableRole.gameMaster,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = screen;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          tableDetailProvider.overrideWith((ref, tableId) async {
            return TableDetail(table: tableFor(role), sessions: [session]);
          }),
        ],
        child: const MaterialApp(
          home: TableDetailScreen(tableId: 'table-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // `bySemanticsLabel` lit le binding, qui n'existe pas encore au chargement
  // du fichier : la recherche doit donc se construire dans chaque test.
  Finder animate() => find.bySemanticsLabel('Animer la session');

  testWidgets('le MJ se voit proposer d’animer sa session', (tester) async {
    await pumpTable(tester, screen: const Size(1280, 800));

    expect(animate(), findsOneWidget);
  });

  testWidgets('un joueur ne se voit rien proposer', (tester) async {
    await pumpTable(
      tester,
      screen: const Size(1280, 800),
      role: TableRole.player,
    );

    expect(animate(), findsNothing);
  });

  testWidgets(
      'sur un téléphone, le bouton reste offert mais explique son refus',
      (tester) async {
    await pumpTable(tester, screen: const Size(412, 915));

    expect(
      animate(),
      findsOneWidget,
      reason: 'cacher l’option ferait croire qu’elle n’existe pas, alors '
          'qu’elle attend le MJ sur sa tablette',
    );

    await tester.tap(animate());
    await tester.pumpAndSettle();

    expect(find.text('Écran trop petit'), findsOneWidget);
    expect(find.text(GameMasterSpace.tooSmall.message), findsOneWidget);
  });

  testWidgets('sur une tablette en portrait, il invite à pivoter',
      (tester) async {
    await pumpTable(tester, screen: const Size(800, 1280));

    await tester.tap(animate());
    await tester.pumpAndSettle();

    expect(find.text(GameMasterSpace.needsLandscape.message), findsOneWidget);
  });
}
