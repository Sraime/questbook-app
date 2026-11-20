import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Glossy gem-style circular characteristic display.
/// Ported from components/jdr/StatDial.jsx.
class QBStatDial extends StatelessWidget {
  const QBStatDial({super.key, required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0x66000000), width: 3),
              ),
              gradient: RadialGradient(
                center: Alignment(-0.36, -0.44),
                colors: [Color(0xFFFFF6DF), QBColors.gemTopaz, QBColors.juicyGoldBottom],
                stops: [0, 0.45, 1],
              ),
              boxShadow: [
                BoxShadow(color: Color(0x59000000), offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              '$value',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 19,
                color: QBColors.ink900,
              ),
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: QBType.game().copyWith(
              fontSize: 12,
              fontWeight: QBType.weightSemibold,
              letterSpacing: 12 * QBType.trackingWide,
              color: QBColors.leather800,
            ),
          ),
        ],
      ),
    );
  }
}
