import 'dart:convert';

/// Ce qu'un pion pose sur le plateau. La forme en découle directement : le
/// mode MJ n'a pas encore d'illustrations, seulement le vocabulaire minimal
/// dont un MJ a besoin pour dire « ça, c'est toi, et ça, c'est la chose ».
enum BoardTokenKind {
  /// Cercle plein — un investigateur, un PNJ, une créature.
  character('character'),

  /// Triangle plein — un décor, un meuble, un obstacle.
  environment('environment'),

  /// Rectangle plein — un effet en cours, un piège, une zone de dégâts.
  effect('effect'),

  /// Disque blanc semi-transparent — une portée, un rayon de lumière.
  zoneDisc('zone_disc'),

  /// Carré blanc semi-transparent — une pièce, un pan de terrain.
  zoneSquare('zone_square');

  const BoardTokenKind(this.wire);

  /// Valeur écrite sur le disque. Séparée du nom Dart pour qu'un renommage
  /// ne rende pas illisibles les plateaux déjà enregistrés.
  final String wire;

  static BoardTokenKind parse(String value) {
    for (final kind in BoardTokenKind.values) {
      if (kind.wire == value) return kind;
    }
    return BoardTokenKind.character;
  }

  /// Les zones se peignent en blanc translucide, quelle que soit la couleur
  /// portée par le pion.
  bool get isZone => this == zoneDisc || this == zoneSquare;
}

enum BoardTokenColor {
  red('red'),
  green('green'),
  blue('blue'),
  yellow('yellow');

  const BoardTokenColor(this.wire);

  final String wire;

  static BoardTokenColor parse(String value) {
    for (final color in BoardTokenColor.values) {
      if (color.wire == value) return color;
    }
    return BoardTokenColor.red;
  }
}

enum BoardCharacterKind {
  investigator('investigator'),
  npc('npc');

  const BoardCharacterKind(this.wire);

  final String wire;

  static BoardCharacterKind? parse(Object? value) {
    for (final kind in BoardCharacterKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Le personnage qu'un pion représente : un investigateur de la session, ou
/// l'un de ses PNJ.
///
/// Le plateau garde l'identifiant, pas le nom ni la fiche : un PNJ se
/// renomme, et c'est sa fiche du moment qu'on veut ouvrir en touchant le
/// pion.
class BoardCharacterLink {
  const BoardCharacterLink({required this.kind, required this.id, this.userId});

  /// `null` pour un lien illisible : le pion reste sur le plateau, il perd
  /// seulement l'accès à la fiche.
  static BoardCharacterLink? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = BoardCharacterKind.parse(json['type']);
    final id = json['id'];
    if (kind == null || id is! String) return null;
    return BoardCharacterLink(
      kind: kind,
      id: id,
      userId: json['userId'] as String?,
    );
  }

  final BoardCharacterKind kind;

  /// L'investigateur ou le PNJ.
  final String id;

  /// Le joueur de l'investigateur : c'est par lui que la session ouvre une
  /// fiche. `null` pour un PNJ.
  final String? userId;

  Map<String, dynamic> toJson() => {
        'type': kind.wire,
        'id': id,
        if (userId != null) 'userId': userId,
      };
}

/// Un pion posé sur le plateau.
///
/// Les coordonnées sont des fractions de la carte, pas des pixels : le même
/// plateau doit se retrouver identique qu'il soit affiché sur une tablette de
/// 10 pouces ou dans une fenêtre réduite.
class BoardToken {
  const BoardToken({
    required this.id,
    required this.kind,
    required this.color,
    required this.x,
    required this.y,
    this.size = defaultSize,
    this.assetKey,
    this.character,
  });

  factory BoardToken.fromJson(Map<String, dynamic> json) => BoardToken(
        id: json['id'] as String,
        kind: BoardTokenKind.parse(json['kind'] as String? ?? ''),
        color: BoardTokenColor.parse(json['color'] as String? ?? ''),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        size: (json['size'] as num?)?.toDouble() ?? defaultSize,
        // Absente des plateaux enregistrés avant la boutique, et c'est très
        // bien : un pion du socle se décrit entièrement par sa forme et sa
        // couleur, la clé ne sert qu'à ceux qui s'achètent.
        assetKey: json['assetKey'] as String?,
        character: BoardCharacterLink.fromJson(json['character']),
      );

  /// Côté d'un pion, en fraction du plus petit côté de la carte.
  static const double defaultSize = 0.07;
  static const double minSize = 0.03;
  static const double maxSize = 0.45;

  final String id;
  final BoardTokenKind kind;
  final BoardTokenColor color;

  /// L'asset acheté dont ce pion est une copie, `null` pour le socle commun.
  ///
  /// Le plateau garde la clé plutôt que l'image : ce qu'on possède peut
  /// changer, et un pion doit rester identifiable même quand celui qui le
  /// regarde ne l'a pas — c'est ce qui permet de le remplacer par un pion
  /// par défaut au lieu de le perdre.
  final String? assetKey;

  /// Le personnage que ce pion représente, `null` pour un pion anonyme.
  final BoardCharacterLink? character;

  /// Centre du pion, entre 0 et 1.
  final double x;
  final double y;
  final double size;

  BoardToken copyWith({double? x, double? y, double? size}) => BoardToken(
        id: id,
        kind: kind,
        color: color,
        x: x ?? this.x,
        y: y ?? this.y,
        size: size ?? this.size,
        assetKey: assetKey,
        character: character,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.wire,
        'color': color.wire,
        'x': x,
        'y': y,
        'size': size,
        if (assetKey != null) 'assetKey': assetKey,
        if (character != null) 'character': character!.toJson(),
      };

  static List<BoardToken> decode(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded.whereType<Map>())
        BoardToken.fromJson(entry.cast<String, dynamic>()),
    ];
  }

  static String encode(List<BoardToken> tokens) =>
      jsonEncode([for (final token in tokens) token.toJson()]);
}
