import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';

void main() {
  late List<String> savedMaps;

  setUp(() => savedMaps = []);

  Future<void> pumpDrawer(WidgetTester tester, {String? mapId}) async {
    tester.view.physicalSize = const Size(2000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardPanel(
            initialTokens: const <BoardToken>[],
            initialMapId: mapId,
            onTokensPersisted: (_) {},
            onMapPersisted: savedMaps.add,
          ),
        ),
      ),
    );
  }

  testWidgets('folds a shelf away and brings it back', (tester) async {
    await pumpDrawer(tester);
    expect(find.text('Joueur rouge'), findsOneWidget);

    await tester.tap(find.text('Personnages'));
    await tester.pump();
    expect(find.text('Joueur rouge'), findsNothing);
    // Les autres rayons ne suivent pas : on plie ce qu'on veut.
    expect(find.text('Décor rouge'), findsOneWidget);

    await tester.tap(find.text('Personnages'));
    await tester.pump();
    expect(find.text('Joueur rouge'), findsOneWidget);
  });

  testWidgets('narrows the drawer down to what was typed', (tester) async {
    await pumpDrawer(tester);

    await tester.enterText(find.byType(TextField), 'jaune');
    await tester.pump();

    expect(find.text('Joueur jaune'), findsOneWidget);
    expect(find.text('Joueur rouge'), findsNothing);
  });

  testWidgets('searching opens the shelves it looked into', (tester) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Personnages'));
    await tester.pump();
    expect(find.text('Joueur jaune'), findsNothing);

    await tester.enterText(find.byType(TextField), 'jaune');
    await tester.pump();

    // Le rayon était plié, mais chercher pour tomber sur un tiroir fermé
    // serait une deuxième énigme.
    expect(find.text('Joueur jaune'), findsOneWidget);
  });

  testWidgets('says so when nothing carries that name', (tester) async {
    await pumpDrawer(tester);

    await tester.enterText(find.byType(TextField), 'dragon');
    await tester.pump();

    expect(find.text('Aucun pion ne porte ce nom.'), findsOneWidget);
  });

  testWidgets('picks a map and remembers it', (tester) async {
    await pumpDrawer(tester);

    await tester.tap(find.text('Grille vierge'));
    await tester.pump();

    expect(savedMaps, ['grille']);
  });

  testWidgets('opens on the map the session was left on', (tester) async {
    await pumpDrawer(tester, mapId: 'grille');

    final tile = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Grille vierge'),
            matching: find.byType(Semantics),
          )
          .first,
    );

    expect(tile.properties.selected, isTrue);
    // Rien n'a été choisi pendant l'ouverture : on n'écrit pas sur le disque
    // pour redire ce qui y est déjà.
    expect(savedMaps, isEmpty);
  });
}
