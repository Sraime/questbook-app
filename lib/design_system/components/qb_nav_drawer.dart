import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class QBNavDrawerItem {
  const QBNavDrawerItem({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

/// The leather panel the top bar's burger slides in, holding the destinations
/// that do not earn a tab of their own.
///
/// Meant to be handed to [Scaffold.drawer], which supplies the scrim, the
/// slide and the swipe-to-close.
class QBNavDrawer extends StatelessWidget {
  const QBNavDrawer({
    super.key,
    required this.items,
    required this.onSelect,
    this.activeKey,
    this.header,
    this.footer,
  });

  final List<QBNavDrawerItem> items;
  final ValueChanged<String> onSelect;
  final String? activeKey;

  /// Sits above the destinations. Used for the signed-in account.
  final Widget? header;

  /// Pinned to the bottom, past a hairline. Used for signing out.
  final Widget? footer;

  static const double _width = 262;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return SizedBox(
      width: _width,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2415), Color(0xFF1E1109)],
            ),
            border: Border(
                right: BorderSide(color: QBColors.slotBorder, width: 3)),
          ),
          padding: EdgeInsets.fromLTRB(
            14,
            padding.top + QBSpace.s4,
            14,
            padding.bottom + QBSpace.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header case final header?) ...[
                header,
                const SizedBox(height: QBSpace.s4),
              ],
              for (final item in items) ...[
                _DrawerRow(
                  item: item,
                  active: item.key == activeKey,
                  onTap: () => onSelect(item.key),
                ),
                const SizedBox(height: QBSpace.s1 + 2),
              ],
              if (footer case final footer?) ...[
                const Spacer(),
                const Divider(
                  height: QBSpace.s6,
                  thickness: 1,
                  color: Color(0x26F4E9D1),
                ),
                footer,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final QBNavDrawerItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                )
              : null,
          borderRadius: BorderRadius.circular(QBRadius.md),
          border: Border.all(
            color: active ? const Color(0x59000000) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 17,
              color: active
                  ? QBColors.ink900
                  : QBColors.paper100.withValues(alpha: 0.8),
            ),
            const SizedBox(width: QBSpace.s3 - 2),
            Expanded(
              child: Text(
                item.label,
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: 13,
                  color: active ? QBColors.ink900 : QBColors.paper100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
