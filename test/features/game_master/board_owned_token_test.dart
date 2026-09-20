import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/widgets/board_token_view.dart';

/// Un pion acheté, posé au milieu du plateau.
const _achete = BoardToken(
  id: 'pion-1',
  kind: BoardTokenKind.character,
  color: BoardTokenColor.green,
  assetKey: 'grand_ancien',
  x: 0.5,
  y: 0.5,
);

void main() {
  late List<List<BoardToken>> saved;

  setUp(() => saved = []);

  Future<void> pumpBoard(
    WidgetTester tester, {
    List<BoardToken> tokens = const [],
    Set<String> ownedKeys = const {},
  }) async {
    tester.view.physicalSize = const Size(2000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardCatalogueProvider
              .overrideWithValue(boardAssetSectionsFor(ownedKeys)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BoardPanel(
              initialTokens: tokens,
              initialMapId: 'grille',
              onTokensPersisted: saved.add,
              onMapPersisted: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  /// Le pion tel qu'il est dessiné sur la carte — et non dans le tiroir, qui
  /// en montre d'autres.
  BoardTokenView drawnOnBoard(WidgetTester tester) => tester.widget(
        find.descendant(
          of: find.byType(DragTarget<BoardAsset>),
          matching: find.byType(BoardTokenView),
        ),
      );

  testWidgets('un pion acheté se dessine avec son illustration',
      (tester) async {
    await pumpBoard(
      tester,
      tokens: const [_achete],
      ownedKeys: const {'grand_ancien'},
    );

    expect(drawnOnBoard(tester).image, isNotNull);
  });

  testWidgets('un pion qu’on ne possède pas retombe sur le rond rouge',
      (tester) async {
    // Le cas du plateau transmis à un MJ qui n'a pas cet asset. Perdre la
    // position en silence serait pire que l'afficher au mauvais visage.
    await pumpBoard(tester, tokens: const [_achete]);

    final drawn = drawnOnBoard(tester);
    expect(drawn.image, isNull);
    expect(drawn.kind, BoardTokenKind.character);
    expect(drawn.color, BoardTokenColor.red);
  });

  testWidgets('poser un pion acheté enregistre sa clé', (tester) async {
    await pumpBoard(tester, ownedKeys: const {'grand_ancien'});

    // Sa collection ferme la marche du tiroir : on l'y cherche, comme on le
    // ferait à une table, plutôt que d'y descendre à la main.
    await tester.enterText(find.byType(TextField), 'ancien');
    await tester.pumpAndSettle();

    final board = tester.getCenter(find.byType(DragTarget<BoardAsset>));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Le Grand Ancien')),
    );
    await tester.pump();
    // Un premier pas horizontal : la liste du tiroir défile à la verticale et
    // s'emparerait du geste si on visait la carte d'un seul trait.
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveTo(board);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Sans la clé, le pion serait un rond vert au rechargement : c'est elle
    // qui fait qu'un achat reste un achat une fois le plateau relu.
    expect(saved.single.single.assetKey, 'grand_ancien');
  });
}
