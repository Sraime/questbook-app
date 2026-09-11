import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_bottom_nav_bar.dart';
import '../tables/providers/table_providers.dart';
import 'offline_banner.dart';

/// Hosts the two persistent tabs (Perso/Tables) from the mockup's bottom
/// tab bar, driven by go_router's StatefulShellRoute.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Invitations, sessions and answers all live under Tables, so that is
    // where the unread badge belongs.
    final unread = ref.watch(unreadNotificationCountProvider);

    // The network coming back has to end the archive, not merely unlock the
    // buttons: whoever is reading a dated copy would otherwise keep reading it
    // until they thought to pull the screen down.
    ref.listen(connectivityProvider, (was, isNow) {
      if (isNow && was == false) refreshTables(ref);
    });

    return Scaffold(
      // Above the tabs rather than inside each screen: being offline is a
      // property of the whole app, and repeating the notice per screen would
      // mean forgetting it on the next one.
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: QBBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        badges: {1: unread},
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
