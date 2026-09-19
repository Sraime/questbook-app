import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/game_master/game_master_space.dart';

void main() {
  test('accepte une tablette tenue en paysage', () {
    expect(
      measureGameMasterSpace(const Size(1280, 800)),
      GameMasterSpace.sufficient,
    );
  });

  test('accepte tout juste la plus petite tablette visée', () {
    expect(
      measureGameMasterSpace(
        const Size(gameMasterMinWidth, gameMasterMinHeight),
      ),
      GameMasterSpace.sufficient,
    );
  });

  test('demande de pivoter une tablette tenue en portrait', () {
    expect(
      measureGameMasterSpace(const Size(800, 1280)),
      GameMasterSpace.needsLandscape,
      reason: 'la place existe, elle est simplement dans l’autre sens',
    );
  });

  test('refuse un téléphone, même couché', () {
    expect(
      measureGameMasterSpace(const Size(412, 915)),
      GameMasterSpace.tooSmall,
    );
    expect(
      measureGameMasterSpace(const Size(915, 412)),
      GameMasterSpace.tooSmall,
      reason: 'un téléphone en paysage est large mais reste trop bas pour '
          'poser un plateau',
    );
  });

  test('chaque refus dit quoi faire ensuite', () {
    expect(
      GameMasterSpace.needsLandscape.message,
      contains('paysage'),
    );
    expect(
      GameMasterSpace.tooSmall.message,
      contains('${gameMasterMinWidth.toInt()}'),
      reason: 'annoncer la taille attendue évite de faire croire à une panne',
    );
    expect(GameMasterSpace.sufficient.message, isEmpty);
  });
}
