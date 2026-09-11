import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class QBNavTab {
  const QBNavTab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

const List<QBNavTab> qbNavTabs = [
  QBNavTab(icon: LucideIcons.user, label: 'Perso'),
  QBNavTab(icon: LucideIcons.calendarDays, label: 'Tables'),
];

/// Leather-and-gold bottom tab bar ported from the `bar()` helper embedded in
/// the mockup's screen script (tabBarHome / tabBarTables).
class QBBottomNavBar extends StatelessWidget {
  const QBBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Unread counts keyed by tab index. A tab with no entry, or a zero, shows
  /// no badge at all.
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2415), Color(0xFF1E1109)],
        ),
        border: Border(top: BorderSide(color: QBColors.slotBorder, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Color(0x59000000), offset: Offset(0, -4), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < qbNavTabs.length; i++)
            Expanded(child: _NavTabButton(
              tab: qbNavTabs[i],
              selected: i == currentIndex,
              badge: badges[i] ?? 0,
              onTap: () => onTap(i),
            )),
        ],
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final QBNavTab tab;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform:
            Matrix4.translationValues(0, selected ? -2 : 0, 0),
        padding: const EdgeInsets.fromLTRB(2, 7, 2, 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                )
              : null,
          borderRadius: BorderRadius.circular(QBRadius.md),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x59000000), offset: Offset(0, 3))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? const Color(0x26000000) : null,
                    gradient: selected
                        ? null
                        : const RadialGradient(
                            center: Alignment(-0.36, -0.44),
                            colors: [Color(0xFF5C4326), Color(0xFF2A1C10)],
                          ),
                  ),
                  child: Icon(
                    tab.icon,
                    size: 14,
                    color: selected
                        ? QBColors.ink900
                        : QBColors.paper300.withValues(alpha: 0.75),
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -3,
                    right: -5,
                    child: _UnreadDot(count: badge),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: QBType.game().copyWith(
                fontWeight: QBType.weightSemibold,
                fontSize: 10,
                letterSpacing: 10 * 0.02,
                color: selected ? QBColors.ink900 : QBColors.paper300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wax-red seal used to mark unread notifications on a tab.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: QBColors.wax500,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(QBRadius.full),
        border: Border.all(color: QBColors.leather900, width: 1.5),
      ),
      child: Text(
        // Past nine the exact figure stops being actionable, and the badge
        // would start pushing the icon around.
        count > 9 ? '9+' : '$count',
        style: QBType.game().copyWith(
          fontWeight: QBType.weightBold,
          fontSize: 9,
          height: 1,
          color: QBColors.paper50,
        ),
      ),
    );
  }
}
