import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Glossy gradient pill used for resource tracks / status labels.
/// Ported from components/core/Badge.jsx.
class QBBadge extends StatelessWidget {
  const QBBadge({super.key, required this.label, this.tone = QBTone.neutral});

  final String label;
  final QBTone tone;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = tone.juicyGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(QBRadius.full),
        border: Border.all(color: const Color(0x4D000000), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: QBType.mono().copyWith(
          fontSize: QBType.xs,
          fontWeight: QBType.weightBold,
          letterSpacing: QBType.xs * QBType.trackingWide,
          color: tone.foreground,
        ),
      ),
    );
  }
}

/// Handwritten-style removable chip. Ported from components/core/Badge.jsx (Tag).
class QBTag extends StatelessWidget {
  const QBTag({super.key, required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: QBColors.paper100,
        border: Border.all(color: QBColors.borderStrong, width: 2),
        borderRadius: BorderRadius.circular(QBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: QBType.hand().copyWith(
              fontSize: 18,
              color: QBColors.leather800,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: QBSpace.s1),
            GestureDetector(
              onTap: onRemove,
              child: const Text(
                '×',
                style: TextStyle(color: QBColors.ink500, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
