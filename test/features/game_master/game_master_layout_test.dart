import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/game_master/game_master_layout.dart';

/// Le mode MJ tourne partout ; c'est sa disposition qui change. Ces tests
/// fixent la frontière entre le rail de la tablette et les onglets du
/// téléphone, et surtout qu'aucun écran n'est refusé.
void main() {
  test('une tablette en paysage garde le rail', () {
    expect(
      measureGameMasterLayout(const Size(1280, 800)),
      GameMasterLayout.rail,
    );
  });

  test('le seuil exact passe encore', () {
    expect(
      measureGameMasterLayout(
        const Size(gameMasterRailMinWidth, gameMasterRailMinHeight),
      ),
      GameMasterLayout.rail,
    );
  });

  test('une tablette en portrait passe aux onglets plutôt que de refuser', () {
    expect(
      measureGameMasterLayout(const Size(800, 1280)),
      GameMasterLayout.tabs,
    );
  });

  test('un téléphone passe aux onglets, dans les deux orientations', () {
    expect(measureGameMasterLayout(const Size(412, 915)), GameMasterLayout.tabs);
    expect(measureGameMasterLayout(const Size(915, 412)), GameMasterLayout.tabs);
  });

  test('seule la disposition rail n’est pas compacte', () {
    expect(GameMasterLayout.rail.isCompact, isFalse);
    expect(GameMasterLayout.tabs.isCompact, isTrue);
  });
}
