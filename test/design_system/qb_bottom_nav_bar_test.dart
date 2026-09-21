import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/design_system/components/qb_bottom_nav_bar.dart';

/// « Perso » faisait cinq lettres, « Investigateurs » en fait quatorze pour
/// le même tiers d'écran. Ces tests veillent à ce qu'il y tienne, y compris
/// sur les téléphones les plus étroits.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpBar(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: QBBottomNavBar(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('les trois onglets sont nommés', (tester) async {
    await pumpBar(tester, 412);

    for (final label in ['Investigateurs', 'Tables', 'Boutique']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('le plus long tient dans son tiers, même à 320 points',
      (tester) async {
    await pumpBar(tester, 320);

    final label = tester.getRect(find.text('Investigateurs'));
    expect(
      label.width,
      lessThanOrEqualTo(320 / 3),
      reason: 'un libellé plus large que son onglet déborde sur ses voisins',
    );
    expect(tester.takeException(), isNull);
  });
}
