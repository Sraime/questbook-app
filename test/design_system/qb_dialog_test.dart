import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/design_system/components/qb_dialog.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpDialog(
    WidgetTester tester, {
    required double screenWidth,
    required double width,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(screenWidth, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: QBDialog(
          title: 'Titre',
          width: width,
          child: const Text('Contenu'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double shellWidth(WidgetTester tester) => tester
      .widget<Container>(
        find.descendant(
          of: find.byType(QBDialog),
          matching: find.byType(Container),
        ),
      )
      .constraints!
      .maxWidth;

  testWidgets('une fenêtre plus large que l’écran est ramenée à sa largeur',
      (tester) async {
    await pumpDialog(tester, screenWidth: 400, width: 560);

    // Une marge de chaque côté, pour qu'on voie qu'il y a un arrière-plan.
    expect(shellWidth(tester), lessThan(400));
  });

  testWidgets('sur un écran large, elle garde la largeur demandée',
      (tester) async {
    await pumpDialog(tester, screenWidth: 1200, width: 560);

    expect(shellWidth(tester), 560);
  });
}
