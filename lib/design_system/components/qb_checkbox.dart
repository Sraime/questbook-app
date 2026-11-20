import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Ported from components/forms/Checkbox.jsx.
class QBCheckbox extends StatelessWidget {
  const QBCheckbox({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
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
            duration: const Duration(milliseconds: 120),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? null : QBColors.surfaceRaised,
              gradient: checked
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [QBColors.juicyGreenTop, QBColors.juicyGreenBottom],
                    )
                  : null,
              border: Border.all(color: QBColors.borderStrong, width: 2),
              borderRadius: BorderRadius.circular(QBRadius.xs),
            ),
            child: checked
                ? const Text('✓',
                    style: TextStyle(
                        color: QBColors.paper50,
                        fontSize: 14,
                        fontWeight: FontWeight.bold))
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
