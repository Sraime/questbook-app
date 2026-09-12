import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_bottom_nav_bar.dart';
import '../../design_system/components/qb_top_app_bar.dart';
import '../tables/providers/table_providers.dart';
import 'app_drawer.dart';
import 'last_tab.dart';
import 'offline_banner.dart';

/// Hosts the two persistent tabs (Perso/Tables) from the mockup's bottom tab
/// bar, plus the chrome that frames every signed-in screen: the top bar and
/// the menu it opens.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Index of the branch holding what the chrome opens: notifications, profile
  /// and the rulebook. It has no tab, so none lights up while it is showing.
  static const _chromeBranch = 2;

  @override
  Widget build(BuildContext context) {
    final branch = widget.navigationShell.currentIndex;

    // Recorded after the frame rather than during it: a notifier must not be
    // written to while the tree that reads it is still building.
    if (branch != _chromeBranch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(lastTabProvider.notifier).remember(branch);
      });
    }

    // The bell lives in the top bar now, so the count belongs to it and to
    // nothing else: repeating it on the Tables tab said the same thing twice.
    final unread = ref.watch(unreadNotificationCountProvider);

    // The network coming back has to end the archive, not merely unlock the
    // buttons: whoever is reading a dated copy would otherwise keep reading it
    // until they thought to pull the screen down.
    ref.listen(connectivityProvider, (was, isNow) {
      if (isNow && was == false) refreshTables(ref);
    });

    final offline = !ref.watch(connectivityProvider);

    // Everything the chrome occupies, handed to the pages as if it were a
    // status bar. They already wrap themselves in a SafeArea, so this is all
    // it takes for each of them to start below the mark — and it leaves them
    // painting their own background edge to edge, behind the bar included.
    final padding = MediaQuery.paddingOf(context);
    final chrome = padding.top +
        QBTopAppBar.barHeight +
        QBTopAppBar.overhang +
        (offline ? OfflineBanner.height : 0);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      // Stacked over the page rather than above it: the brand mark hangs below
      // the bar, and a column would paint the page on top of the overhang.
      body: Stack(
        children: [
          // Left unpositioned on purpose: it is what gives the stack its size.
          // Positioning both children would leave the chrome — a hundred-odd
          // pixels tall — to decide how tall the page is.
          MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: padding.copyWith(top: chrome)),
            child: widget.navigationShell,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QBTopAppBar(
                  unread: unread,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotifications: () => context.go('/notifications'),
                ),
                // Under the bar rather than above it: being offline is a
                // property of the app, but the chrome is the app's frame and
                // nothing should push it around.
                const OfflineBanner(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: QBBottomNavBar(
        currentIndex: branch,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          // Tapping the tab you are already on is the gesture for "take me
          // back to the top", so only then is the branch reset.
          initialLocation: index == branch,
        ),
      ),
    );
  }
}
