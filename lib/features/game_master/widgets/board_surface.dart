import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../design_system/tokens/colors.dart';
import '../models/board_catalog.dart';

/// Le fond de carte, sans les pions.
///
/// Partagé par le plateau du MJ et celui que le joueur regarde : c'est la même
/// carte des deux côtés, et deux dessins finiraient par diverger.
class BoardSurface extends StatelessWidget {
  const BoardSurface({super.key, required this.map});

  final BoardMap map;

  @override
  Widget build(BuildContext context) =>
      _MapImage(map: map, fit: BoxFit.fill, grid: QBColors.paper100);
}

/// La vignette d'une carte, rognée à ses proportions de vignette : le tiroir
/// du MJ et l'écran des assets montrent la même.
class BoardMapPreview extends StatelessWidget {
  const BoardMapPreview({super.key, required this.map});

  final BoardMap map;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 3,
        child: _MapImage(map: map, fit: BoxFit.cover, grid: QBColors.paper200),
      );
}

/// L'image d'une carte, embarquée ou hébergée, et la grille à défaut.
///
/// Une carte hébergée dont l'image manque ou ne se lit pas montre la grille :
/// le plateau reste utilisable, et les pions restent à leur place.
class _MapImage extends StatelessWidget {
  const _MapImage({required this.map, required this.fit, required this.grid});

  final BoardMap map;
  final BoxFit fit;
  final Color grid;

  @override
  Widget build(BuildContext context) {
    final blank = ColoredBox(
      color: grid,
      child: const CustomPaint(painter: BoardGridPainter()),
    );

    final asset = map.asset;
    if (asset != null) return Image.asset(asset, fit: fit);
    final file = map.file;
    if (file != null) {
      return Image.file(
        File(file),
        fit: fit,
        errorBuilder: (_, _, _) => blank,
      );
    }
    return blank;
  }
}

/// La grille de la carte vierge. Douze cases dans la largeur : assez pour
/// situer des personnages les uns par rapport aux autres, pas assez pour
/// transformer le plateau en damier illisible.
class BoardGridPainter extends CustomPainter {
  const BoardGridPainter();

  static const _columns = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _columns;
    final line = Paint()
      ..color = QBColors.borderHairline
      ..strokeWidth = 1;

    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(BoardGridPainter oldDelegate) => false;
}
