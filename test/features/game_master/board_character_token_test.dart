import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/assets/providers/hosted_assets_provider.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/widgets/board_token_view.dart';

import 'board_test_session.dart';

/// Le MJ a donné le Grand Ancien à Ernest pour la séance. Le catalogue du
/// test ne le compte pas parmi ses pions : la vignette doit se dessiner quand
/// même, comme chez un joueur qui regarde le plateau.
final _ernest = RemoteAttendance(
  userId: 'joueur-1',
  status: AttendanceStatus.yes,
  respondedAt: DateTime.utc(2026, 9, 1),
  user: const RemoteUser(
    id: 'joueur-1',
    displayName: 'Marie',
    pictureUrl: null,
  ),
  character: const RemoteAttendanceCharacter(
    id: 'perso-1',
    name: 'Ernest Blackwood',
    occupation: 'Antiquaire',
  ),
  token: 'asset:grand_ancien',
);

const _gardien = RemoteNpc(
  id: 'pnj-1',
  name: 'Le gardien du phare',
  description: 'Ne dort jamais.',
  origin: 'scenario',
  token: 'socle:blue',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('les références de pion', () {
    test('un pion du socle se retrouve par sa couleur', () {
      final asset = boardAssetForRef('socle:blue')!;
      expect(asset.name, 'Joueur bleu');
      expect(asset.ref, 'socle:blue');
    });

    test('un pion de la boutique se retrouve par sa clé', () {
      expect(boardAssetForRef('asset:grand_ancien')!.ref, 'asset:grand_ancien');
    });

    test('ce que l’app ne sait pas dessiner ne rend rien', () {
      expect(boardAssetForRef('asset:inconnu'), isNull);
      expect(boardAssetForRef('socle:violet'), isNull);
      expect(boardAssetForRef('n_importe_quoi'), isNull);
      expect(boardAssetForRef(null), isNull);
    });

    test('un pion posé garde le personnage qu’il représente', () {
      const token = BoardToken(
        id: 'pion-1',
        kind: BoardTokenKind.character,
        color: BoardTokenColor.red,
        x: 0.5,
        y: 0.5,
        character: BoardCharacterLink(
          kind: BoardCharacterKind.investigator,
          id: 'perso-1',
          userId: 'joueur-1',
        ),
      );

      final read = BoardToken.decode(BoardToken.encode(const [token])).single;
      expect(read.character!.kind, BoardCharacterKind.investigator);
      expect(read.character!.id, 'perso-1');
      expect(read.character!.userId, 'joueur-1');
    });
  });

  group('le plateau', () {
    late List<List<BoardToken>> saved;

    setUp(() => saved = []);

    Future<void> pumpBoard(
      WidgetTester tester, {
      List<BoardToken> tokens = const [],
    }) async {
      tester.view.physicalSize = const Size(2000, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            boardTestNpcs(const [_gardien]),
            boardCatalogueProvider.overrideWithValue(boardAssetSections),
            hostedAssetsProvider.overrideWith((ref) async => const {}),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BoardPanel(
                session: boardTestSession(attendances: [_ernest]),
                initialTokens: tokens,
                initialMapId: 'grille',
                onTokensPersisted: saved.add,
                onMapPersisted: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Color tileFill(WidgetTester tester, String name) {
      final box = tester.widget<Container>(
        find
            .ancestor(of: find.text(name), matching: find.byType(Container))
            .first,
      );
      return (box.decoration! as BoxDecoration).color!;
    }

    testWidgets(
        'le tiroir propose les personnages sous leur nom, jaune pour '
        'l’investigateur, rouge pour le PNJ', (tester) async {
      await pumpBoard(tester);

      expect(find.text('Ernest Blackwood'), findsOneWidget);
      expect(find.text('Le gardien du phare'), findsOneWidget);
      // Le pion d'origine reste là, anonyme.
      expect(find.text('Joueur bleu'), findsOneWidget);

      expect(tileFill(tester, 'Ernest Blackwood'), const Color(0xFFFFE89A));
      expect(tileFill(tester, 'Le gardien du phare'), const Color(0xFFF8C4C2));
    });

    testWidgets('poser le pion d’un personnage en garde le lien',
        (tester) async {
      await pumpBoard(tester);

      final board = tester.getCenter(find.byType(DragTarget<BoardAsset>));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Le gardien du phare')),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveTo(board);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final placed = saved.single.single;
      expect(placed.color, BoardTokenColor.blue);
      expect(placed.character!.kind, BoardCharacterKind.npc);
      expect(placed.character!.id, 'pnj-1');
    });

    testWidgets(
        'le pion d’un investigateur se dessine même quand le MJ ne le '
        'possède pas', (tester) async {
      await pumpBoard(tester, tokens: const [
        BoardToken(
          id: 'pion-1',
          kind: BoardTokenKind.character,
          color: BoardTokenColor.green,
          assetKey: 'grand_ancien',
          x: 0.5,
          y: 0.5,
          character: BoardCharacterLink(
            kind: BoardCharacterKind.investigator,
            id: 'perso-1',
            userId: 'joueur-1',
          ),
        ),
      ]);

      final drawn = tester.widget<BoardTokenView>(find.descendant(
        of: find.byType(DragTarget<BoardAsset>),
        matching: find.byType(BoardTokenView),
      ));
      expect(drawn.image, isNotNull);
    });

    testWidgets('un pion lié ouvre la fiche de son personnage', (tester) async {
      await pumpBoard(tester, tokens: const [
        BoardToken(
          id: 'pion-1',
          kind: BoardTokenKind.character,
          color: BoardTokenColor.blue,
          x: 0.5,
          y: 0.5,
          character: BoardCharacterLink(kind: BoardCharacterKind.npc, id: 'pnj-1'),
        ),
      ]);

      await tester.tap(find.descendant(
        of: find.byType(DragTarget<BoardAsset>),
        matching: find.byType(BoardTokenView),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Ouvrir la fiche du personnage'));
      await tester.pumpAndSettle();

      expect(find.text('Ne dort jamais.'), findsOneWidget);
    });

    testWidgets('un pion anonyme n’offre pas de fiche', (tester) async {
      await pumpBoard(tester, tokens: const [
        BoardToken(
          id: 'pion-1',
          kind: BoardTokenKind.character,
          color: BoardTokenColor.blue,
          x: 0.5,
          y: 0.5,
        ),
      ]);

      await tester.tap(find.descendant(
        of: find.byType(DragTarget<BoardAsset>),
        matching: find.byType(BoardTokenView),
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Retirer le pion du plateau'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ouvrir la fiche du personnage'),
        findsNothing,
      );
    });
  });
}
