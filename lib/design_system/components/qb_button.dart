import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum QBButtonVariant { primary, secondary, ghost, danger }

enum QBButtonSize { sm, md, lg }

/// Chunky "juicy" gradient button: gradient fill, near-black border, and a
/// hard offset drop shadow that collapses into a press-down squash on tap —
/// ported from components/core/Button.jsx.
class QBButton extends StatefulWidget {
  const QBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = QBButtonVariant.primary,
    this.size = QBButtonSize.md,
    this.iconLeft,
    this.iconRight,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final QBButtonVariant variant;
  final QBButtonSize size;
  final Widget? iconLeft;
  final Widget? iconRight;

  /// Stretch to fill the available width (most call sites in the mockup use
  /// full-width buttons stacked in a column).
  final bool expand;

  @override
  State<QBButton> createState() => _QBButtonState();
}

class _QBButtonState extends State<QBButton> {
  bool _pressed = false;

  ({Color background, Color backgroundEnd, Color foreground}) get _colors =>
      switch (widget.variant) {
        QBButtonVariant.primary => (
            background: QBColors.juicyGoldTop,
            backgroundEnd: QBColors.juicyGoldBottom,
            foreground: QBColors.ink900,
          ),
        QBButtonVariant.secondary => (
            background: QBColors.leather500,
            backgroundEnd: QBColors.leather700,
            foreground: QBColors.paper50,
          ),
        QBButtonVariant.ghost => (
            background: QBColors.surfaceSunken,
            backgroundEnd: QBColors.surfaceSunken,
            foreground: QBColors.leather800,
          ),
        QBButtonVariant.danger => (
            background: QBColors.juicyRedTop,
            backgroundEnd: QBColors.juicyRedBottom,
            foreground: QBColors.paper50,
          ),
      };

  ({EdgeInsets padding, double fontSize}) get _sizing => switch (widget.size) {
        QBButtonSize.sm => (
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            fontSize: 14,
          ),
        QBButtonSize.md => (
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            fontSize: 17,
          ),
        QBButtonSize.lg => (
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            fontSize: 20,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final colors = _colors;
    final sizing = _sizing;
    final hasShadow = !disabled && widget.variant != QBButtonVariant.ghost;

    Widget child = AnimatedContainer(
      duration: QBMotion.fast,
      curve: QBMotion.easeOut,
      transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
      padding: sizing.padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.background, colors.backgroundEnd],
        ),
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: const Color(0x59000000), width: 2),
        boxShadow: !hasShadow
            ? null
            : (_pressed ? QBShadows.juicyPress : QBShadows.juicy),
      ),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        // Some labels (notably longer French strings like "RELANCER") can
        // exceed the available width when this button sits in a tight
        // Expanded row (e.g. side-by-side dialog actions). Scaling the row
        // down to fit avoids a RenderFlex overflow instead of clipping or
        // wrapping the label.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconLeft != null) ...[
                widget.iconLeft!,
                const SizedBox(width: QBSpace.s2),
              ],
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: sizing.fontSize,
                  letterSpacing: sizing.fontSize * 0.03,
                  color: colors.foreground,
                ),
              ),
              if (widget.iconRight != null) ...[
                const SizedBox(width: QBSpace.s2),
                widget.iconRight!,
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.expand) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: disabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: child,
      ),
    );
  }
}
