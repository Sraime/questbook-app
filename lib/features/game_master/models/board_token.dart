import 'dart:convert';

/// Ce qu'un pion pose sur le plateau. La forme en découle directement : le
/// mode MJ n'a pas encore d'illustrations, seulement le vocabulaire minimal
/// dont un MJ a besoin pour dire « ça, c'est toi, et ça, c'est la chose ».
enum BoardTokenKind {
  /// Cercle plein — un personnage joueur, un PNJ, une créature.
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
  });

  factory BoardToken.fromJson(Map<String, dynamic> json) => BoardToken(
        id: json['id'] as String,
        kind: BoardTokenKind.parse(json['kind'] as String? ?? ''),
        color: BoardTokenColor.parse(json['color'] as String? ?? ''),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        size: (json['size'] as num?)?.toDouble() ?? defaultSize,
      );

  /// Côté d'un pion, en fraction du plus petit côté de la carte.
  static const double defaultSize = 0.07;
  static const double minSize = 0.03;
  static const double maxSize = 0.45;

  final String id;
  final BoardTokenKind kind;
  final BoardTokenColor color;

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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.wire,
        'color': color.wire,
        'x': x,
        'y': y,
        'size': size,
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
