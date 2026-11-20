import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';

/// Flat parchment background with a faint ruled-paper texture, matching
/// `--bg-page` + `--texture-paper` from effects.css. CustomPainter draws the
/// repeating hairlines since CSS `repeating-linear-gradient` has no direct
/// BoxDecoration equivalent.
class QBPageBackground extends StatelessWidget {
  const QBPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: QBColors.bgPage,
      child: CustomPaint(
        painter: _PaperTexturePainter(),
        child: child,
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rulePaint = Paint()
      ..color = const Color(0x04241A12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }
    final sheen = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.1,
        colors: [
          const Color(0x80FFFAF0),
          const Color(0x80FFFAF0).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
