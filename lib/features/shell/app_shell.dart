import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/qb_bottom_nav_bar.dart';
import '../tables/providers/table_providers.dart';

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

    return Scaffold(
      body: navigationShell,
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
