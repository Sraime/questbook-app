import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';

enum QBIconButtonVariant { ghost, outline, solid }

/// Ported from components/core/IconButton.jsx.
class QBIconButton extends StatefulWidget {
  const QBIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.size = 40,
    this.variant = QBIconButtonVariant.ghost,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;
  final QBIconButtonVariant variant;

  @override
  State<QBIconButton> createState() => _QBIconButtonState();
}

class _QBIconButtonState extends State<QBIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = switch (widget.variant) {
      QBIconButtonVariant.ghost => BoxDecoration(
          color: QBColors.surfaceSunken,
          border: Border.all(color: QBColors.borderStrong, width: 2),
          borderRadius: BorderRadius.circular(QBRadius.md),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), offset: Offset(0, 2)),
          ],
        ),
      QBIconButtonVariant.outline => BoxDecoration(
          color: QBColors.surfaceRaised,
          border: Border.all(color: QBColors.borderStrong, width: 2),
          borderRadius: BorderRadius.circular(QBRadius.md),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), offset: Offset(0, 2)),
          ],
        ),
      QBIconButtonVariant.solid => BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [QBColors.leather500, QBColors.leather700],
          ),
          border: Border.all(color: const Color(0x59000000), width: 2),
          borderRadius: BorderRadius.circular(QBRadius.md),
          boxShadow: QBShadows.juicy,
        ),
    };

    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onPressed == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: QBMotion.fast,
          curve: QBMotion.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: decoration,
          child: widget.icon,
        ),
      ),
    );
  }
}
