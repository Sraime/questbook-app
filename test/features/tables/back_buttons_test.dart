import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/session_form_screen.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

/// Les flèches de retour en haut des écrans ont disparu : l'onglet Tables,
/// en bas, ramène à la liste et ne bouge jamais. Renoncer à une session, en
/// revanche, se dit en toutes lettres au bas du formulaire.
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

  Future<GoRouter> pump(WidgetTester tester, String at) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(
          path: '/tables/:id',
          // Le Scaffold vient du shell dans l'app ; les champs de texte le
          // réclament, et ces écrans ne le portent pas eux-mêmes.
          builder: (context, state) => const Scaffold(
            body: TableDetailScreen(tableId: 'table-1'),
          ),
          routes: [
            GoRoute(
              path: 'sessions/new',
              builder: (context, state) => const Scaffold(
                body: SessionFormScreen(tableId: 'table-1'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          tableDetailProvider.overrideWith(
            (ref, tableId) async =>
                TableDetail(table: table, sessions: const []),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('le détail d’une table n’a plus de flèche de retour',
      (tester) async {
    await pump(tester, '/tables/table-1');

    expect(find.text('Les ombres d’Arkham'), findsOneWidget);
    expect(find.bySemanticsLabel('Retour'), findsNothing);
  });

  testWidgets('le formulaire d’une session non plus', (tester) async {
    await pump(tester, '/tables/table-1/sessions/new');

    expect(find.text('Nouvelle session'), findsOneWidget);
    expect(find.bySemanticsLabel('Retour'), findsNothing);
  });

  testWidgets('il porte un bouton Annuler sous celui qui enregistre',
      (tester) async {
    await pump(tester, '/tables/table-1/sessions/new');

    final propose = tester.getRect(
      find.widgetWithText(QBButton, 'Proposer la session'),
    );
    final cancel = tester.getRect(find.widgetWithText(QBButton, 'Annuler'));

    expect(
      cancel.top,
      greaterThan(propose.bottom),
      reason: 'renoncer est la symétrie d’enregistrer, et se décide après '
          'avoir relu ses champs',
    );
  });

  testWidgets('Annuler ramène à la table', (tester) async {
    final router = await pump(tester, '/tables/table-1/sessions/new');

    await tester.tap(find.widgetWithText(QBButton, 'Annuler'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/tables/table-1',
    );
  });
}
