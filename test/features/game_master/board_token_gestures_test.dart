import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/widgets/board_token_view.dart';

/// Un pion posé au milieu d'un plateau vide.
const _token = BoardToken(
  id: 'pion-1',
  kind: BoardTokenKind.character,
  color: BoardTokenColor.red,
  x: 0.5,
  y: 0.5,
);

void main() {
  late List<List<BoardToken>> saved;

  setUp(() => saved = []);

  /// Le mode MJ tourne sur une tablette : on lui en donne une.
  Future<void> pumpBoard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardCatalogueProvider.overrideWithValue(boardAssetSections),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BoardPanel(
              initialTokens: const [_token],
              initialMapId: 'grille',
              onTokensPersisted: saved.add,
              onMapPersisted: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  /// Le centre du pion à l'écran, d'où partent tous les gestes.
  Offset tokenCentre(WidgetTester tester) {
    final board = tester.getRect(find.byType(DragTarget<BoardAsset>).first);
    return board.topLeft +
        Offset(board.width * _token.x, board.height * _token.y);
  }

  testWidgets('un pion du plateau répond au doigt qui le touche',
      (tester) async {
    await pumpBoard(tester);

    final remove = find.bySemanticsLabel('Retirer le pion du plateau');
    expect(remove, findsNothing);

    await tester.tapAt(tokenCentre(tester));
    await tester.pump();

    expect(remove, findsOneWidget);
  });

  testWidgets('un pion du plateau suit le doigt qui le traîne',
      (tester) async {
    await pumpBoard(tester);

    // Le pion dessiné sur la carte, pas les vignettes du tiroir.
    final drawn = find.descendant(
      of: find.byType(DragTarget<BoardAsset>),
      matching: find.byType(BoardTokenView),
    );
    final start = tester.getCenter(drawn);

    final gesture = await tester.startGesture(start);
    await tester.pump();

    // Le premier pas paie le seuil de déclenchement : c'est à partir du
    // deuxième que le pion doit coller au doigt.
    await gesture.moveBy(const Offset(20, 10));
    await tester.pump();
    final anchor = tester.getCenter(drawn);

    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
    }

    // Il a suivi au point près, avant même qu'on relâche, et rien n'a encore
    // été écrit sur le disque.
    final travelled = tester.getCenter(drawn) - anchor;
    expect(travelled.dx, moreOrLessEquals(100, epsilon: 0.5));
    expect(travelled.dy, moreOrLessEquals(50, epsilon: 0.5));
    expect(saved, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(saved, hasLength(1));
    final token = saved.single.single;
    expect(token.x, greaterThan(_token.x));
    expect(token.y, greaterThan(_token.y));
  });

  testWidgets('toucher la carte à côté repose le pion', (tester) async {
    await pumpBoard(tester);

    await tester.tapAt(tokenCentre(tester));
    await tester.pump();
    expect(find.bySemanticsLabel('Retirer le pion du plateau'), findsOneWidget);

    final board = tester.getRect(find.byType(DragTarget<BoardAsset>).first);
    await tester.tapAt(board.topLeft + const Offset(12, 12));
    await tester.pump();

    expect(find.bySemanticsLabel('Retirer le pion du plateau'), findsNothing);
  });

  testWidgets('retirer un pion le fait disparaître et l’enregistre',
      (tester) async {
    await pumpBoard(tester);

    await tester.tapAt(tokenCentre(tester));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Retirer le pion du plateau'));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single, isEmpty);
  });
}
