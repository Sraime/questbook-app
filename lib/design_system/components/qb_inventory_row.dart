import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Dark inset wood slot for one equipment line. Ported from
/// components/jdr/InventoryRow.jsx.
class QBInventoryRow extends StatelessWidget {
  const QBInventoryRow({
    super.key,
    required this.name,
    this.qty = 1,
    this.weight,
    this.onRemove,
  });

  final String name;
  final int qty;
  final String? weight;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: QBColors.slotEmpty,
        border: Border.all(color: QBColors.slotBorder, width: 2),
        borderRadius: BorderRadius.circular(QBRadius.sm),
        // Approximates the CSS inset shadow (shadow-slot-inset) with a subtle
        // top-edge darkening — Flutter's BoxDecoration has no inset shadow.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x40000000), Colors.transparent],
          stops: [0, 0.3],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: QBType.body()
                  .copyWith(fontSize: QBType.base, color: QBColors.paper100),
            ),
          ),
          Text(
            '×$qty',
            style: QBType.mono()
                .copyWith(fontSize: QBType.sm, color: QBColors.gold500),
          ),
          if (weight != null) ...[
            const SizedBox(width: QBSpace.s3),
            Text(
              weight!,
              style: QBType.mono()
                  .copyWith(fontSize: QBType.xs, color: QBColors.paper300),
            ),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: QBSpace.s3),
            GestureDetector(
              onTap: onRemove,
              child: const Text('×', style: TextStyle(color: QBColors.paper300)),
            ),
          ],
        ],
      ),
    );
  }
}
