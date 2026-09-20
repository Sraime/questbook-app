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

  test('the tab bar holds the places one works in', () {
    expect(
      qbNavTabs.map((tab) => tab.label),
      ['Perso', 'Tables', 'Boutique'],
    );
  });

  test('every tab has its branch, and the tab-less one comes last', () {
    final branches = shellRoute().branches;

    expect(branches, hasLength(qbNavTabs.length + 1));
    expect(pathsOfBranch(0), ['/perso']);
    expect(pathsOfBranch(1), ['/tables']);
    expect(pathsOfBranch(2), ['/boutique']);
  });

  test('scenarios are filed with what the chrome opens', () {
    // Filed anywhere else, reading a scenario would light a tab it does not
    // belong to, and drop whoever was mid-table out of their place.
    expect(
      pathsOfBranch(qbNavTabs.length),
      containsAll(<String>['/scenarios', '/assets', '/profil', '/regles']),
    );
  });

  /// Ouvre le volet sur un routeur qui n'a que les chemins visés, pour
  /// n'exercer que la navigation — les écrans réels demandent une base et un
  /// compte connecté, qui ne diraient rien de plus ici.
  Future<String?> tapInDrawer(
    WidgetTester tester, {
    required String label,
    required List<String> destinations,
  }) async {
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
        for (final path in destinations)
          GoRoute(
            path: path,
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

    expect(find.text(label), findsOneWidget);

    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    return visited;
  }

  testWidgets('the drawer offers Scénarios and goes there', (tester) async {
    expect(
      await tapInDrawer(
        tester,
        label: 'Scénarios',
        destinations: ['/scenarios'],
      ),
      '/scenarios',
    );
  });

  testWidgets('the drawer offers Assets and goes there', (tester) async {
    expect(
      await tapInDrawer(
        tester,
        label: 'Assets',
        destinations: ['/assets'],
      ),
      '/assets',
    );
  });
}
