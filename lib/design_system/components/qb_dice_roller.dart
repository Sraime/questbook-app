import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Roll-a-skill control: name + base %, last result, and a "1d100" roll
/// button. Ported from components/jdr/DiceRoller.jsx.
class QBDiceRoller extends StatelessWidget {
  const QBDiceRoller({
    super.key,
    required this.skill,
    required this.percent,
    this.result,
    this.onRoll,
  });

  final String skill;
  final int percent;
  final int? result;
  final VoidCallback? onRoll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: QBColors.surfaceCard,
        border: Border.all(color: QBColors.leather800, width: 3),
        borderRadius: BorderRadius.circular(QBRadius.md),
        boxShadow: QBShadows.paperSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 15,
                    color: QBColors.ink900,
                  ),
                ),
                Text(
                  '$percent%',
                  style: QBType.mono()
                      .copyWith(fontSize: QBType.sm, color: QBColors.textMuted),
                ),
              ],
            ),
          ),
          if (result != null) ...[
            Text(
              '$result',
              style: QBType.game().copyWith(
                fontSize: 26,
                fontWeight: QBType.weightBold,
                color: result! <= percent
                    ? QBColors.juicyGreenBottom
                    : QBColors.juicyRedBottom,
              ),
            ),
            const SizedBox(width: QBSpace.s3),
          ],
          GestureDetector(
            onTap: onRoll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                ),
                border: Border.all(color: const Color(0x59000000), width: 2),
                borderRadius: BorderRadius.circular(QBRadius.md),
                boxShadow: QBShadows.juicy,
              ),
              child: Text(
                '1d100',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  letterSpacing: 0.5,
                  color: QBColors.ink900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
