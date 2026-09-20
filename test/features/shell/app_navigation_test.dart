import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/router.dart';
import 'package:questbook/design_system/components/qb_bottom_nav_bar.dart';
import 'package:questbook/features/shell/app_drawer.dart';

/// Scénarios left the tab bar for the burger menu. The bar, the drawer and the
/// router each hold one end of that move, and nothing in the type system keeps
/// them agreeing — hence these tests.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  StatefulShellRoute shellRoute() =>
      appRouter.configuration.routes.whereType<StatefulShellRoute>().single;

  List<String> pathsOfBranch(int index) => shellRoute()
      .branches[index]
      .routes
      .whereType<GoRoute>()
      .map((route) => route.path)
      .toList();

  test('the tab bar is down to the two places one works in', () {
    expect(
      qbNavTabs.map((tab) => tab.label),
      ['Perso', 'Tables'],
    );
  });

  test('every tab has its branch, and the tab-less one comes last', () {
    final branches = shellRoute().branches;

    expect(branches, hasLength(qbNavTabs.length + 1));
    expect(pathsOfBranch(0), ['/perso']);
    expect(pathsOfBranch(1), ['/tables']);
  });

  test('scenarios are filed with what the chrome opens', () {
    // Filed anywhere else, reading a scenario would light a tab it does not
    // belong to, and drop whoever was mid-table out of their place.
    expect(
      pathsOfBranch(qbNavTabs.length),
      containsAll(<String>['/scenarios', '/profil', '/regles']),
    );
  });

  testWidgets('the drawer offers Scénarios and goes there', (tester) async {
    String? visited;

    final router = GoRouter(
      initialLocation: '/perso',
      routes: [
        GoRoute(
          path: '/perso',
          builder: (context, state) => Scaffold(
            drawer: const AppDrawer(),
            body: Builder(
              builder: (context) => TextButton(
                onPressed: Scaffold.of(context).openDrawer,
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/scenarios',
          builder: (context, state) {
            visited = state.matchedLocation;
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Scénarios'), findsOneWidget);

    await tester.tap(find.text('Scénarios'));
    await tester.pumpAndSettle();

    expect(visited, '/scenarios');
  });
}
