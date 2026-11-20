import 'package:material_ui/material_ui.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Dark-slot segmented control with a "juicy" gold active pill.
/// Ported from components/navigation/Tabs.jsx.
class QBTabs extends StatelessWidget {
  const QBTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onChanged,
  });

  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: QBColors.slotEmpty,
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: QBColors.slotBorder, width: 2),
      ),
      child: Row(
        children: [
          for (final tab in tabs) ...[
            if (tab != tabs.first) const SizedBox(width: 6),
            Expanded(
              child: _TabButton(
                label: tab,
                selected: tab == active,
                onTap: () => onChanged(tab),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                )
              : null,
          borderRadius: BorderRadius.circular(QBRadius.sm),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 13,
            letterSpacing: 13 * 0.02,
            color: selected ? QBColors.ink900 : QBColors.paper300,
          ),
        ),
      ),
    );
  }
}
