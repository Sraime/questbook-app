import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/game_master/models/board_token.dart';

void main() {
  const pion = BoardToken(
    id: 't1',
    kind: BoardTokenKind.character,
    color: BoardTokenColor.blue,
    x: 0.25,
    y: 0.5,
    size: 0.09,
  );

  test('un plateau relu est le plateau enregistré', () {
    final relu = BoardToken.decode(BoardToken.encode([pion]));

    expect(relu, hasLength(1));
    expect(relu.single.id, 't1');
    expect(relu.single.kind, BoardTokenKind.character);
    expect(relu.single.color, BoardTokenColor.blue);
    expect(relu.single.x, 0.25);
    expect(relu.single.size, 0.09);
  });

  test('une taille absente retombe sur la taille par défaut', () {
    final relu = BoardToken.decode('[{"id":"t1","kind":"character",'
        '"color":"red","x":0.1,"y":0.1}]');

    expect(relu.single.size, BoardToken.defaultSize);
  });

  test('un pion écrit par une version future ne vide pas le plateau', () {
    final relu = BoardToken.decode('[{"id":"t1","kind":"hologramme",'
        '"color":"mauve","x":0.1,"y":0.1}]');

    expect(relu.single.kind, BoardTokenKind.character);
    expect(relu.single.color, BoardTokenColor.red);
  });

  test('un contenu illisible rend un plateau vide plutôt qu’une exception', () {
    expect(BoardToken.decode('{}'), isEmpty);
  });

  test('les zones se peignent en blanc, quelle que soit leur couleur', () {
    expect(BoardTokenKind.zoneDisc.isZone, isTrue);
    expect(BoardTokenKind.zoneSquare.isZone, isTrue);
    expect(BoardTokenKind.character.isZone, isFalse);
  });

  test('déplacer un pion ne change que sa position', () {
    final deplace = pion.copyWith(x: 0.8, y: 0.2);

    expect(deplace.id, pion.id);
    expect(deplace.size, pion.size);
    expect(deplace.x, 0.8);
    expect(deplace.y, 0.2);
  });
}
