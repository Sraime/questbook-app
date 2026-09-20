import 'dart:ui';

/// Comment le mode MJ se dispose sur l'écran qu'on lui donne.
///
/// Une tablette en paysage a de quoi étaler trois colonnes : le rail des
/// volets, le plateau, et le tiroir d'assets ouvert à côté de la carte. Un
/// téléphone n'en a pas la place, et une tablette tenue en portrait non plus :
/// les volets passent alors en onglets sous l'entête, et le tiroir vient
/// recouvrir la carte le temps qu'on y pioche un pion.
///
/// Les valeurs sont celles qui laissent la carte respirer une fois le rail et
/// le tiroir déduits : une tablette 7 pouces en 960×600 garde le rail, la même
/// en portrait passe aux onglets.
const double gameMasterRailMinWidth = 900;
const double gameMasterRailMinHeight = 560;

/// Les deux dispositions du mode MJ.
enum GameMasterLayout {
  /// Rail de volets à gauche, tiroir d'assets ouvert à droite de la carte.
  rail,

  /// Onglets sous l'entête, tiroir en surimpression.
  tabs;

  bool get isCompact => this == tabs;
}

/// Choisit la disposition qui tient dans [size].
///
/// On regarde la fenêtre plutôt que le modèle d'appareil : une tablette dans
/// une fenêtre réduite est aussi à l'étroit qu'un téléphone, et c'est la place
/// disponible qui décide. Mesuré à chaque `build`, donc une rotation en pleine
/// partie fait basculer la disposition sans quitter la session.
GameMasterLayout measureGameMasterLayout(Size size) {
  final fits = size.width >= gameMasterRailMinWidth &&
      size.height >= gameMasterRailMinHeight;
  return fits ? GameMasterLayout.rail : GameMasterLayout.tabs;
}
