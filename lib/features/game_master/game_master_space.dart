import 'dart:ui';

/// Le mode MJ étale trois colonnes de front — le rail des volets, le plateau,
/// puis le tiroir d'assets — et le plateau ne sert à rien s'il ne reste que
/// quelques centimètres pour poser des pions. En dessous de ces bornes, mieux
/// vaut refuser franchement que livrer un écran où rien n'est manipulable.
///
/// Les valeurs correspondent à une tablette tenue en paysage : une 7 pouces en
/// 960×600 passe, la même en portrait non, et aucun téléphone ne passe dans
/// l'une ou l'autre orientation.
const double gameMasterMinWidth = 900;
const double gameMasterMinHeight = 560;

/// Ce qui manque à l'écran pour accueillir le mode MJ, s'il manque quelque
/// chose.
enum GameMasterSpace {
  /// L'écran convient.
  sufficient,

  /// Assez grand une fois pivoté : une tablette tenue en portrait.
  needsLandscape,

  /// Trop petit dans les deux sens : un téléphone.
  tooSmall;

  bool get isSufficient => this == sufficient;

  /// Ce que l'on dit au MJ qui tente d'ouvrir le mode depuis un écran trop
  /// petit. Volontairement concret : « trop petit » sans dire de combien
  /// laisse croire à une panne.
  String get message => switch (this) {
        sufficient => '',
        needsLandscape =>
          'Le mode MJ a besoin de toute la largeur d’une tablette pour poser '
              'côte à côte le plateau et le tiroir d’assets. Fais pivoter la '
              'tienne en paysage et réessaie.',
        tooSmall =>
          'Le mode MJ demande un écran de tablette, au moins '
              '${gameMasterMinWidth.toInt()} × ${gameMasterMinHeight.toInt()} '
              'points. Celui-ci est trop petit pour afficher le plateau, les '
              'pions et le tiroir d’assets en même temps : ouvre la session '
              'depuis une tablette.',
      };
}

/// Mesure [size] à l'aune de ce que le mode MJ réclame.
///
/// On regarde la fenêtre plutôt que le modèle d'appareil : une tablette dans
/// une fenêtre réduite est aussi à l'étroit qu'un téléphone, et c'est la place
/// disponible qui décide.
GameMasterSpace measureGameMasterSpace(Size size) {
  if (size.width >= gameMasterMinWidth && size.height >= gameMasterMinHeight) {
    return GameMasterSpace.sufficient;
  }

  final longest = size.longestSide;
  final shortest = size.shortestSide;
  if (longest >= gameMasterMinWidth && shortest >= gameMasterMinHeight) {
    return GameMasterSpace.needsLandscape;
  }

  return GameMasterSpace.tooSmall;
}
