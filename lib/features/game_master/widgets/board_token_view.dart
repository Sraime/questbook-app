import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../models/board_token.dart';

/// Le dessin d'un pion, identique dans le tiroir d'assets et sur le plateau —
/// ce que le MJ attrape est exactement ce qu'il pose.
class BoardTokenView extends StatelessWidget {
  const BoardTokenView({
    super.key,
    required this.kind,
    required this.color,
    this.selected = false,
  });

  BoardTokenView.of(BoardToken token, {super.key, this.selected = false})
      : kind = token.kind,
        color = token.color;

  final BoardTokenKind kind;
  final BoardTokenColor color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final outline = selected
        ? Border.all(color: QBColors.gold500, width: 3)
        : Border.all(color: _edge, width: 2);

    return switch (kind) {
      BoardTokenKind.character => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _fill,
            border: outline,
            boxShadow: _shadow,
          ),
        ),
      BoardTokenKind.environment => CustomPaint(
          painter: _TrianglePainter(
            fill: _fill,
            edge: selected ? QBColors.gold500 : _edge,
            width: selected ? 3 : 2,
          ),
        ),
      // Un effet s'étale : une bande, pas un pavé, pour qu'on le distingue
      // d'une zone au premier coup d'œil.
      BoardTokenKind.effect => Center(
          child: FractionallySizedBox(
            heightFactor: 0.62,
            child: Container(
              decoration: BoxDecoration(
                color: _fill,
                border: outline,
                borderRadius: BorderRadius.circular(3),
                boxShadow: _shadow,
              ),
            ),
          ),
        ),
      BoardTokenKind.zoneDisc => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _zoneFill,
            border: Border.all(
              color: selected ? QBColors.gold500 : _zoneEdge,
              width: selected ? 3 : 2,
            ),
          ),
        ),
      BoardTokenKind.zoneSquare => Container(
          decoration: BoxDecoration(
            color: _zoneFill,
            border: Border.all(
              color: selected ? QBColors.gold500 : _zoneEdge,
              width: selected ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    };
  }

  static const _zoneFill = Color(0x59FFFAF0);
  static const _zoneEdge = Color(0xCCFFFAF0);

  static const _shadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  Color get _fill => switch (color) {
        BoardTokenColor.red => QBColors.juicyRedTop,
        BoardTokenColor.green => QBColors.juicyGreenTop,
        BoardTokenColor.blue => QBColors.juicyBlueTop,
        BoardTokenColor.yellow => QBColors.juicyGoldTop,
      };

  Color get _edge => switch (color) {
        BoardTokenColor.red => QBColors.juicyRedBottom,
        BoardTokenColor.green => QBColors.juicyGreenBottom,
        BoardTokenColor.blue => QBColors.juicyBlueBottom,
        BoardTokenColor.yellow => QBColors.juicyGoldBottom,
      };
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.fill,
    required this.edge,
    required this.width,
  });

  final Color fill;
  final Color edge;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.edge != edge ||
      oldDelegate.width != width;
}
