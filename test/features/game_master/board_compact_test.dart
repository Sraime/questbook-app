import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';

/// Le plateau sur un écran de téléphone : le tiroir n'a plus de colonne à lui,
/// il recouvre la carte et s'efface dès qu'on tire un pion.
void main() {
  Future<void> pumpBoard(
    WidgetTester tester, {
    Size screen = const Size(412, 915),
    bool compact = true,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardCatalogueProvider
              .overrideWithValue(boardAssetSectionsFor(const {})),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BoardPanel(
              initialTokens: const <BoardToken>[],
              initialMapId: null,
              compact: compact,
              onTokensPersisted: (_) {},
              onMapPersisted: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('le tiroir démarre rangé, la carte a tout l’écran',
      (tester) async {
    await pumpBoard(tester);

    expect(find.text('Joueur rouge'), findsNothing);
    expect(find.bySemanticsLabel('Afficher les pions'), findsOneWidget);
  });

  testWidgets('la languette l’ouvre par-dessus la carte', (tester) async {
    await pumpBoard(tester);

    await tester.tap(find.bySemanticsLabel('Afficher les pions'));
    await tester.pump();

    expect(find.text('Joueur rouge'), findsOneWidget);
    // Recouvrir, pas pousser : la carte garde la moitié de l'écran.
    final drawer = tester.getRect(find.byType(ListView).last);
    expect(drawer.right, closeTo(412, 1));
    expect(drawer.left, greaterThan(412 / 2));
  });

  testWidgets('resserré, le tiroir empile une vignette par ligne',
      (tester) async {
    await pumpBoard(tester);

    await tester.tap(find.bySemanticsLabel('Afficher les pions'));
    await tester.pump();

    final premier = tester.getRect(find.text('Joueur rouge'));
    final second = tester.getRect(find.text('Joueur vert'));

    // L'un sous l'autre, sur la même colonne : deux par ligne ne tiendraient
    // plus dans un tiroir resserré.
    expect(second.top, greaterThan(premier.bottom));
    expect(second.center.dx, closeTo(premier.center.dx, 1));
  });

  testWidgets('tirer un pion range le tiroir, sinon on viserait derrière lui',
      (tester) async {
    await pumpBoard(tester);

    await tester.tap(find.bySemanticsLabel('Afficher les pions'));
    await tester.pump();

    final tile = find.text('Joueur rouge');
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump();
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();

    expect(find.text('Joueur rouge'), findsNothing);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('sur un grand écran, le tiroir reste ouvert à côté de la carte',
      (tester) async {
    await pumpBoard(
      tester,
      screen: const Size(1280, 800),
      compact: false,
    );

    expect(find.text('Joueur rouge'), findsOneWidget);
    expect(find.bySemanticsLabel('Masquer le tiroir des pions'), findsOneWidget);
  });
}
