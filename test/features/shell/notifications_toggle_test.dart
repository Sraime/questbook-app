import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/design_system/components/qb_bottom_nav_bar.dart';
import 'package:questbook/features/shell/app_shell.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

/// L'écran des notifications n'a plus de bouton retour : c'est la cloche qui
/// l'a ouvert qui le referme, et elle ramène à l'onglet quitté plutôt qu'à un
/// écran décidé d'avance.
///
/// Un routeur réduit aux chemins visés : les vrais écrans demandent une base
/// et un compte connecté, qui ne diraient rien de plus ici.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpShell(WidgetTester tester, {required String from}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    Widget page(String label) => Scaffold(body: Center(child: Text(label)));

    final router = GoRouter(
      initialLocation: from,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            for (final path in ['/perso', '/tables', '/boutique'])
              StatefulShellBranch(routes: [
                GoRoute(path: path, builder: (_, _) => page(path)),
              ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, _) => page('/notifications'),
              ),
            ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Le compteur interroge le serveur ; ce test ne parle que de
          // navigation.
          unreadNotificationCountProvider.overrideWithValue(0),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder bell() => find.bySemanticsLabel('Notifications');

  testWidgets('la cloche ouvre les notifications', (tester) async {
    await pumpShell(tester, from: '/tables');

    await tester.tap(bell());
    await tester.pumpAndSettle();

    expect(find.text('/notifications'), findsOneWidget);
  });

  testWidgets('une seconde touche referme et rend l’onglet quitté',
      (tester) async {
    await pumpShell(tester, from: '/tables');

    await tester.tap(bell());
    await tester.pumpAndSettle();
    await tester.tap(bell());
    await tester.pumpAndSettle();

    expect(find.text('/tables'), findsOneWidget);
    expect(find.text('/notifications'), findsNothing);
  });

  testWidgets('elle rend l’onglet quitté, pas un écran décidé d’avance',
      (tester) async {
    await pumpShell(tester, from: '/tables');

    // Passer sur Boutique avant d'ouvrir la cloche : c'est là qu'il faut
    // revenir, et nulle part ailleurs.
    await tester.tap(find.text('Boutique'));
    await tester.pumpAndSettle();
    await tester.tap(bell());
    await tester.pumpAndSettle();
    await tester.tap(bell());
    await tester.pumpAndSettle();

    expect(find.text('/boutique'), findsOneWidget);
  });

  testWidgets('la barre du bas reste l’autre sortie', (tester) async {
    await pumpShell(tester, from: '/tables');

    await tester.tap(bell());
    await tester.pumpAndSettle();

    expect(
      find.byType(QBBottomNavBar),
      findsOneWidget,
      reason: 'retirer la flèche ne doit pas enfermer le lecteur',
    );
  });
}
