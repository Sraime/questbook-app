import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/feedback/Tooltip.jsx. Not wired into any of the
/// current screens, kept for design-system completeness.
class QBTooltip extends StatelessWidget {
  const QBTooltip({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      textStyle: QBType.hand().copyWith(fontSize: 16, color: QBColors.paper50),
      decoration: BoxDecoration(
        color: QBColors.ink900,
        borderRadius: BorderRadius.circular(QBRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: child,
    );
  }
}
