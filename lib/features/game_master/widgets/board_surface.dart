import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final asset = map.asset;
    if (asset != null) return Image.asset(asset, fit: BoxFit.fill);
    return const ColoredBox(
      color: QBColors.paper100,
      child: CustomPaint(painter: BoardGridPainter()),
    );
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
