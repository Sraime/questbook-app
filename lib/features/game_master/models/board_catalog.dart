import 'board_token.dart';

/// Un fond de carte proposé au MJ.
///
/// Deux sont embarquées, offertes à tous ; les autres s'achètent en
/// boutique, ajoutées depuis le backoffice, et arrivent par
/// `hostedMapsProvider`. Leur `id` est alors la clé de l'asset.
class BoardMap {
  const BoardMap({
    required this.id,
    required this.label,
    required this.asset,
    required this.aspectRatio,
    this.file,
  });

  final String id;
  final String label;

  /// L'image embarquée. `null` pour la grille, qui se dessine, et pour une
  /// carte hébergée, dont l'image est un [file].
  final String? asset;

  /// L'image d'une carte hébergée, sur l'appareil. `null` tant qu'elle n'est
  /// pas descendue : la carte montre alors la grille.
  final String? file;

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

/// La carte d'un plateau, embarquée ou parmi les [hosted].
///
/// Une carte inconnue rend la première plutôt qu'un plateau vide : une carte
/// achetée par le MJ peut arriver chez un joueur avant la liste qui la décrit.
BoardMap boardMapById(
  String? id, {
  Map<String, BoardMap> hosted = const {},
}) {
  for (final map in boardMaps) {
    if (map.id == id) return map;
  }
  return hosted[id] ?? boardMaps.first;
}

/// Les cartes qu'un compte peut choisir : celles de l'app, puis celles qu'il
/// a achetées, dans l'ordre de la boutique.
List<BoardMap> boardMapsFor(
  Iterable<String> ownedKeys, {
  Map<String, BoardMap> hosted = const {},
}) =>
    [
      ...boardMaps,
      for (final key in ownedKeys) ?hosted[key],
    ];

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
    this.imageFile,
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

  /// L'illustration d'un pion hébergé par le serveur : un fichier sur
  /// l'appareil, et non une image embarquée. `null` tant qu'elle n'est pas
  /// descendue, et le pion se dessine alors à sa forme.
  final String? imageFile;
}

class BoardAssetSection {
  const BoardAssetSection({required this.title, required this.assets});

  final String title;
  final List<BoardAsset> assets;
}

/// Les rayons du tiroir. Ce sont les natures de pion, nommées : c'est ce qui
/// permet de ranger un pion acheté sans rien lui demander de plus.
const _personnages = 'Personnages';
const _environnement = 'Environnement';
const _effets = 'Effets';
const _zones = 'Zones';

/// Le rayon où se range un pion, d'après sa nature.
String boardSectionTitleFor(BoardTokenKind kind) => switch (kind) {
      BoardTokenKind.character => _personnages,
      BoardTokenKind.environment => _environnement,
      BoardTokenKind.effect => _effets,
      BoardTokenKind.zoneDisc || BoardTokenKind.zoneSquare => _zones,
    };

const boardAssetSections = <BoardAssetSection>[
  BoardAssetSection(
    title: _personnages,
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
    title: _environnement,
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
    title: _effets,
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
    title: _zones,
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

/// Les pions qui s'achètent et dont le dessin est embarqué dans l'app, par la
/// clé que la boutique leur donne.
///
/// Ceux qu'on ajoute depuis le backoffice n'y figurent pas : le serveur
/// héberge leur image, et ils arrivent par `hostedAssetsProvider`. Une clé
/// connue ni ici ni de là est ignorée plutôt que de faire tomber le tiroir.
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

/// Le catalogue tel qu'un compte le voit : le socle commun, plus ce qu'il a
/// acheté.
///
/// Les pions achetés se rangent dans les rayons existants, d'après leur
/// nature, et non dans une vitrine « ma collection » à part : un personnage
/// se cherche avec les personnages. Regrouper les achats ferait deux endroits
/// où regarder pour une même question — « qu'est-ce que je peux poser comme
/// PNJ ? » — et l'écart grandirait à chaque achat. Ils arrivent en fin de
/// rayon, après le socle, ce qui les rend repérables sans déplacer ce que le
/// MJ a l'habitude de trouver en tête.
///
/// [hosted] porte les pions dont le serveur héberge l'image ; ils se rangent
/// comme les autres.
List<BoardAssetSection> boardAssetSectionsFor(
  Iterable<String> ownedKeys, {
  Map<String, BoardAsset> hosted = const {},
}) {
  final owned = [
    for (final key in ownedKeys) ?boardAssetForKey(key, hosted: hosted),
  ];
  if (owned.isEmpty) return boardAssetSections;

  return [
    for (final section in boardAssetSections)
      BoardAssetSection(
        title: section.title,
        assets: [
          ...section.assets,
          ...owned.where(
            (asset) => boardSectionTitleFor(asset.kind) == section.title,
          ),
        ],
      ),
  ];
}

/// Le pion que dessine une clé, ou `null` si le compte ne la connaît pas.
///
/// Rendre `null` plutôt qu'un pion par défaut est délibéré : c'est à
/// l'affichage de décider quoi montrer d'un asset qu'on ne possède pas, et
/// lui seul sait qu'un rond rouge vaut mieux qu'un trou.
BoardAsset? boardAssetForKey(
  String? key, {
  Map<String, BoardAsset> hosted = const {},
}) =>
    key == null ? null : purchasableBoardAssets[key] ?? hosted[key];

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
