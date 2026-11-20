import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';

/// Riveted wood-and-parchment panel: 3px leather border, four corner "bolts",
/// soft paper shadow. Ported from components/navigation/Card.jsx.
class QBCard extends StatelessWidget {
  const QBCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(QBSpace.s6),
  });

  final Widget child;
  final EdgeInsets padding;

  static const double _rivetSize = 9;
  static const double _rivetInset = 6;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QBColors.surfaceCard,
        border: Border.all(color: QBColors.leather800, width: 3),
        borderRadius: BorderRadius.circular(QBRadius.lg),
        boxShadow: QBShadows.paperMd,
      ),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          const Positioned(top: _rivetInset, left: _rivetInset, child: _RivetSlot()),
          const Positioned(top: _rivetInset, right: _rivetInset, child: _RivetSlot()),
          const Positioned(bottom: _rivetInset, left: _rivetInset, child: _RivetSlot()),
          const Positioned(bottom: _rivetInset, right: _rivetInset, child: _RivetSlot()),
        ],
      ),
    );
  }
}

class _RivetSlot extends StatelessWidget {
  const _RivetSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: QBCard._rivetSize,
      height: QBCard._rivetSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFCFA15A), Color(0xFF5A4023)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 1)),
        ],
      ),
    );
  }
}
