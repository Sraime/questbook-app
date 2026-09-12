import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Leather chrome at the top of every signed-in screen: burger on the left,
/// the brand mark centred, the notifications bell and its unread seal on the
/// right. Mirrors the bottom tab bar so the two read as one frame.
///
/// The mark is deliberately taller than the bar and hangs over its bottom
/// edge, which is why this is meant to be stacked *over* the page rather than
/// stacked above it in a column — see [overhang].
class QBTopAppBar extends StatelessWidget {
  const QBTopAppBar({
    super.key,
    required this.onMenu,
    required this.onNotifications,
    this.unread = 0,
  });

  final VoidCallback onMenu;
  final VoidCallback onNotifications;

  /// Zero hides the seal entirely rather than drawing an empty one.
  final int unread;

  /// Height of the chrome itself, status bar excluded.
  static const double barHeight = 54;

  /// How far the mark drops below the chrome. Content must clear this much
  /// extra space, or the mark would sit on top of the first line of the page.
  static const double overhang = 26;

  static const double _markSize = 86;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A2415), Color(0xFF1E1109)],
        ),
        border:
            Border(bottom: BorderSide(color: QBColors.slotBorder, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Color(0x59000000), offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: SizedBox(
        height: barHeight,
        // The mark escapes the bar downwards, so nothing here may clip.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BarButton(
                    tooltip: 'Menu',
                    icon: LucideIcons.menu,
                    onTap: onMenu,
                  ),
                  _BarButton(
                    tooltip: 'Notifications',
                    icon: LucideIcons.bell,
                    onTap: onNotifications,
                    badge: unread,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              // Anchored by its bottom rather than centred: what the eye reads
              // is how far the mark drops past the chrome, and that is the one
              // number the page below has to clear.
              top: barHeight + overhang - _markSize,
              child: Center(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/brand/logo-mark.png',
                    width: _markSize,
                    height: _markSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatefulWidget {
  const _BarButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                widget.icon,
                size: 24,
                color: QBColors.paper50.withValues(alpha: 0.9),
              ),
              if (widget.badge > 0)
                Positioned(
                  top: -5,
                  right: -7,
                  child: _UnreadSeal(count: widget.badge),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same wax seal as the bottom bar's, one size up: it is the only unread
/// marker left now that the bell is visible from every screen.
class _UnreadSeal extends StatelessWidget {
  const _UnreadSeal({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: QBColors.wax500,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: QBColors.leather900, width: 2),
      ),
      child: Text(
        // Past nine the exact figure stops being actionable, and the seal
        // would start pushing the bell around.
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
