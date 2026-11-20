import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/forms/Switch.jsx.
class QBSwitch extends StatelessWidget {
  const QBSwitch({
    super.key,
    this.label,
    required this.checked,
    required this.onChanged,
  });

  final String? label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: QBMotion.base,
            curve: QBMotion.easeOut,
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2),
            alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: checked ? null : QBColors.surfaceSunken,
              gradient: checked
                  ? const LinearGradient(
                      colors: [QBColors.juicyGreenTop, QBColors.juicyGreenBottom],
                    )
                  : null,
              border: Border.all(color: QBColors.borderStrong, width: 2),
              borderRadius: BorderRadius.circular(QBRadius.full),
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QBColors.paper50,
                boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 2)],
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: QBSpace.s2),
            Text(
              label!,
              style: QBType.body()
                  .copyWith(fontSize: QBType.base, color: QBColors.ink800),
            ),
          ],
        ],
      ),
    );
  }
}
