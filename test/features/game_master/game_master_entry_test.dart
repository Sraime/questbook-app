import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/design_system/components/qb_card.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

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

  RemoteGameSession sessionStarting(Duration startsIn) {
    final startsAt = DateTime.now().add(startsIn);
    return RemoteGameSession(
      id: 'session-1',
      tableId: 'table-1',
      title: 'Chapitre III — Les ruines',
      description: null,
      startsAt: startsAt,
      location: 'Chez Marie',
      status: 'scheduled',
      attendances: const [],
      myStatus: null,
      myCharacter: null,
      scenarioId: null,
      scenario: null,
      closesAt: startsAt.add(const Duration(hours: 24)),
      answersCloseAt: startsAt,
    );
  }

  Future<void> pumpTable(
    WidgetTester tester, {
    required Size screen,
    TableRole role = TableRole.gameMaster,
    Duration startsIn = const Duration(days: 2),
  }) async {
    final session = sessionStarting(startsIn);

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
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/tables/table-1',
            routes: [
              GoRoute(
                path: '/tables/:id',
                builder: (context, state) =>
                    const TableDetailScreen(tableId: 'table-1'),
              ),
              GoRoute(
                path: '/tables/:id/sessions/:sessionId/mj',
                builder: (context, state) =>
                    const Scaffold(body: Text('mode mj')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder entry(String label) => find.widgetWithText(QBButton, label);

  testWidgets('avant l’heure, le MJ prépare sa séance', (tester) async {
    await pumpTable(tester, screen: const Size(1280, 800));

    expect(entry('Préparer'), findsOneWidget);
    expect(entry('Animer'), findsNothing);
  });

  testWidgets('une fois commencée, il l’anime', (tester) async {
    await pumpTable(
      tester,
      screen: const Size(1280, 800),
      startsIn: const Duration(hours: -2),
    );

    expect(entry('Animer'), findsOneWidget);
    expect(entry('Préparer'), findsNothing);
  });

  testWidgets('la carte n’encombre plus son titre de boutons', (tester) async {
    await pumpTable(tester, screen: const Size(1280, 800));

    expect(find.bySemanticsLabel('Modifier la session'), findsNothing);
    expect(
      find.bySemanticsLabel('Annuler la session'),
      findsNothing,
      reason: 'corriger et annuler ont rejoint le volet Détails du mode MJ',
    );
  });

  testWidgets('le bouton mène au mode MJ', (tester) async {
    await pumpTable(tester, screen: const Size(1280, 800));

    await tester.tap(entry('Préparer'));
    await tester.pumpAndSettle();

    expect(find.text('mode mj'), findsOneWidget);
  });

  testWidgets('le reste de la carte ne mène plus nulle part', (tester) async {
    await pumpTable(tester, screen: const Size(1280, 800));

    await tester.tap(find.text('Chapitre III — Les ruines'));
    await tester.pumpAndSettle();

    expect(
      find.text('mode mj'),
      findsNothing,
      reason: 'un geste qu’aucun mot n’annonce ne se devine pas : c’est le '
          'bouton qui ouvre le mode MJ, et lui seul',
    );
  });

  testWidgets('un joueur ne se voit rien proposer', (tester) async {
    await pumpTable(
      tester,
      screen: const Size(1280, 800),
      role: TableRole.player,
    );

    expect(entry('Préparer'), findsNothing);
    expect(entry('Animer'), findsNothing);
  });

  testWidgets('le bouton prend toute la largeur de la carte', (tester) async {
    await pumpTable(tester, screen: const Size(412, 915));

    final card = tester.getRect(find.byType(QBCard).first);
    final button = tester.getRect(entry('Préparer'));

    // À la marge intérieure près, celle que la carte impose à tout son
    // contenu : le bouton est aussi large que le titre au-dessus de lui.
    expect(button.width, greaterThan(card.width - 40));
  });

  testWidgets('sur un téléphone aussi, le MJ entre dans sa session',
      (tester) async {
    await pumpTable(tester, screen: const Size(412, 915));

    await tester.tap(entry('Préparer'));
    await tester.pumpAndSettle();

    expect(
      find.text('mode mj'),
      findsOneWidget,
      reason: 'le mode MJ tourne désormais sur téléphone : plus rien à '
          'refuser au MJ qui n’a pas de tablette sous la main',
    );
  });
}
