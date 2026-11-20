import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/forms/Radio.jsx.
class QBRadio extends StatelessWidget {
  const QBRadio({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QBColors.surfaceRaised,
              border: Border.all(color: QBColors.borderStrong, width: 2),
              shape: BoxShape.circle,
            ),
            child: checked
                ? Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: QBSpace.s2),
          Text(
            label,
            style: QBType.body()
                .copyWith(fontSize: QBType.base, color: QBColors.ink800),
          ),
        ],
      ),
    );
  }
}
