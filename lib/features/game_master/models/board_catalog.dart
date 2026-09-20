import 'board_token.dart';

/// Un fond de carte proposé au MJ.
///
/// Le catalogue est écrit en dur pour l'instant. Ajouter une carte, c'est
/// déposer l'image sous `assets/board/` et ajouter une entrée ici ; #39 les
/// fera venir du back avec les scénarios.
class BoardMap {
  const BoardMap({
    required this.id,
    required this.label,
    required this.asset,
    required this.aspectRatio,
  });

  final String id;
  final String label;

  /// `null` pour la grille : il n'y a pas d'illustration, le plateau se
  /// dessine.
  final String? asset;

  /// Les proportions de l'image. Le plateau s'y conforme, sinon les pions
  /// glisseraient sur une carte étirée.
  final double aspectRatio;
}

const boardMaps = <BoardMap>[
  BoardMap(
    id: 'manoir',
    label: 'Manoir dans la clairière',
    asset: 'assets/board/manoir-clairiere.jpg',
    aspectRatio: 1312 / 1199,
  ),
  // Pas toujours besoin d'un décor : une grille nue sert à placer un ordre
  // d'initiative, un plan griffonné à l'oral, ou une scène qui n'existe que
  // dans la tête du MJ.
  BoardMap(
    id: 'grille',
    label: 'Grille vierge',
    asset: null,
    aspectRatio: 16 / 10,
  ),
];

BoardMap boardMapById(String? id) {
  for (final map in boardMaps) {
    if (map.id == id) return map;
  }
  return boardMaps.first;
}

/// Un pion proposé dans le tiroir.
///
/// Le nom sert à deux choses : l'afficher sous la vignette, et le chercher.
/// Les illustrations viendront plus tard ; d'ici là le nom décrit la forme et
/// la couleur, qui sont tout ce qui distingue un pion d'un autre.
class BoardAsset {
  const BoardAsset({
    required this.name,
    required this.kind,
    required this.color,
    this.key,
    this.image,
  });

  final String name;
  final BoardTokenKind kind;
  final BoardTokenColor color;

  /// La clé de l'article qui donne ce pion, `null` pour le socle commun.
  /// C'est elle que le plateau enregistre.
  final String? key;

  /// L'illustration, pour les pions qui en ont une. Le socle se dessine
  /// encore à la forme et à la couleur.
  final String? image;
}

class BoardAssetSection {
  const BoardAssetSection({required this.title, required this.assets});

  final String title;
  final List<BoardAsset> assets;
}

const boardAssetSections = <BoardAssetSection>[
  BoardAssetSection(
    title: 'Personnages',
    assets: [
      BoardAsset(
        name: 'Joueur rouge',
        kind: BoardTokenKind.character,
        color: BoardTokenColor.red,
      ),
      BoardAsset(
        name: 'Joueur vert',
        kind: BoardTokenKind.character,
        color: BoardTokenColor.green,
      ),
      BoardAsset(
        name: 'Joueur bleu',
        kind: BoardTokenKind.character,
        color: BoardTokenColor.blue,
      ),
      BoardAsset(
        name: 'Joueur jaune',
        kind: BoardTokenKind.character,
        color: BoardTokenColor.yellow,
      ),
    ],
  ),
  BoardAssetSection(
    title: 'Environnement',
    assets: [
      BoardAsset(
        name: 'Décor rouge',
        kind: BoardTokenKind.environment,
        color: BoardTokenColor.red,
      ),
      BoardAsset(
        name: 'Décor vert',
        kind: BoardTokenKind.environment,
        color: BoardTokenColor.green,
      ),
      BoardAsset(
        name: 'Décor bleu',
        kind: BoardTokenKind.environment,
        color: BoardTokenColor.blue,
      ),
      BoardAsset(
        name: 'Décor jaune',
        kind: BoardTokenKind.environment,
        color: BoardTokenColor.yellow,
      ),
    ],
  ),
  BoardAssetSection(
    title: 'Effets',
    assets: [
      BoardAsset(
        name: 'Effet rouge',
        kind: BoardTokenKind.effect,
        color: BoardTokenColor.red,
      ),
      BoardAsset(
        name: 'Effet vert',
        kind: BoardTokenKind.effect,
        color: BoardTokenColor.green,
      ),
      BoardAsset(
        name: 'Effet bleu',
        kind: BoardTokenKind.effect,
        color: BoardTokenColor.blue,
      ),
      BoardAsset(
        name: 'Effet jaune',
        kind: BoardTokenKind.effect,
        color: BoardTokenColor.yellow,
      ),
    ],
  ),
  BoardAssetSection(
    title: 'Zones',
    assets: [
      BoardAsset(
        name: 'Zone ronde',
        kind: BoardTokenKind.zoneDisc,
        color: BoardTokenColor.yellow,
      ),
      BoardAsset(
        name: 'Zone carrée',
        kind: BoardTokenKind.zoneSquare,
        color: BoardTokenColor.yellow,
      ),
    ],
  ),
];

/// Les pions qui s'achètent, par la clé que la boutique leur donne.
///
/// Le serveur ne décrit pas à quoi ressemble un pion — il n'envoie qu'une
/// clé — donc son dessin vit ici, du côté qui peint, comme le reste du
/// catalogue. Une clé absente de cette table est un article que cette
/// version de l'app ne sait pas encore montrer : elle est ignorée plutôt que
/// de faire tomber le tiroir.
const purchasableBoardAssets = <String, BoardAsset>{
  'grand_ancien': BoardAsset(
    key: 'grand_ancien',
    name: 'Le Grand Ancien',
    image: 'assets/brand/logo-mark.png',
    // Un personnage : il se pose au milieu des joueurs et se déplace comme
    // eux, ce n'est ni un décor ni une zone.
    kind: BoardTokenKind.character,
    color: BoardTokenColor.green,
  ),
};

/// Le catalogue tel qu'un compte le voit : le socle commun, puis ce qu'il a
/// acheté.
///
/// Sa collection vient en dernier et non en tête : le socle est ce dont on se
/// sert à chaque partie, et le reléguer sous une rubrique qui grandira au fil
/// des achats ferait dérouler le tiroir pour atteindre un rond rouge.
List<BoardAssetSection> boardAssetSectionsFor(Iterable<String> ownedKeys) {
  final owned = [
    for (final key in ownedKeys) ?purchasableBoardAssets[key],
  ];
  if (owned.isEmpty) return boardAssetSections;

  return [
    ...boardAssetSections,
    BoardAssetSection(title: 'Ma collection', assets: owned),
  ];
}

/// Le pion que dessine une clé, ou `null` si le compte ne la connaît pas.
///
/// Rendre `null` plutôt qu'un pion par défaut est délibéré : c'est à
/// l'affichage de décider quoi montrer d'un asset qu'on ne possède pas, et
/// lui seul sait qu'un rond rouge vaut mieux qu'un trou.
BoardAsset? boardAssetForKey(String? key) =>
    key == null ? null : purchasableBoardAssets[key];

/// Ce qui reste de [sections] une fois [query] saisi.
///
/// La recherche porte aussi sur le titre de la section : taper « zone » ou
/// « personnage » doit rendre le rayon entier, c'est ce qu'on attend d'un
/// champ de recherche au-dessus de rubriques nommées. Les sections vidées
/// disparaissent plutôt que de rester en titres orphelins.
List<BoardAssetSection> filterBoardAssets(
  String query, {
  List<BoardAssetSection> sections = boardAssetSections,
}) {
  final needle = foldForSearch(query);
  if (needle.isEmpty) return sections;

  final kept = <BoardAssetSection>[];
  for (final section in sections) {
    if (foldForSearch(section.title).contains(needle)) {
      kept.add(section);
      continue;
    }

    final assets = section.assets
        .where((asset) => foldForSearch(asset.name).contains(needle))
        .toList();
    if (assets.isNotEmpty) {
      kept.add(BoardAssetSection(title: section.title, assets: assets));
    }
  }
  return kept;
}

/// Minuscules et sans accents : « Zone carrée » doit se trouver en tapant
/// « carree » d'une main, au-dessus d'une table de jeu.
String foldForSearch(String value) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
  };

  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString();
}
