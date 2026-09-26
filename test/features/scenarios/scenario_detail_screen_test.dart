import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/design_system/components/qb_card.dart';
import 'package:questbook/design_system/components/qb_dialog.dart';
import 'package:questbook/features/scenarios/providers/scenario_providers.dart';
import 'package:questbook/features/scenarios/scenario_detail_screen.dart';

const _phare = RemoteScenarioDetail(
  id: 'sc-1',
  title: 'Le Phare de Kerloc\'h',
  description: 'Un gardien disparaît sur la côte.',
  minRecommendedPlayers: 2,
  maxRecommendedPlayers: 5,
  averageDurationMinutes: 180,
  context: 'Kerloc\'h, 1924.',
  rundownMarkdown: '## Mise en place\n\nDonner le télégramme.\n\n'
      '## 1. Le village\n\nLes rumeurs se contredisent.\n\n'
      '## 3. Le phare\n\nLa porte est close, pas forcée.',
  npcs: [
    RemoteScenarioNpc(
      id: 'np-1',
      sortOrder: 0,
      name: 'Mariette Le Goff',
      description: 'La femme du gardien. Ment sur les dates.',
    ),
  ],
  clues: [
    RemoteScenarioClue(
      id: 'cl-1',
      sortOrder: 0,
      title: 'Carnet de la crique',
      contentMarkdown: '> 12 mars — La lumière n’est plus à moi.',
    ),
  ],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Un écran assez haut pour tout poser par défaut : ce qu'on vérifie alors
  /// est le contenu, pas le défilement. Le test de navigation, lui, demande
  /// un écran de téléphone, sans quoi il n'y a rien à faire défiler.
  Future<void> pumpScreen(WidgetTester tester, {double height = 1800}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(411, height);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadedScenarioProvider('sc-1').overrideWith((ref) async => _phare),
        ],
        child: const MaterialApp(
          home: ScenarioDetailScreen(scenarioId: 'sc-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Une aventure en compte une douzaine : les lire toutes pour retrouver le
  /// bon revient à relire le scénario.
  testWidgets('personnages et indices sont des lignes, pas de la prose',
      (tester) async {
    await pumpScreen(tester);

    expect(find.widgetWithText(QBCard, 'Mariette Le Goff'), findsOneWidget);
    expect(find.widgetWithText(QBCard, 'Carnet de la crique'), findsOneWidget);

    // Le titre d'un indice se suffit, et l'annoncer ici le déflorerait.
    expect(find.textContaining('12 mars'), findsNothing);
  });

  testWidgets('le contenu s’ouvre au toucher', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Carnet de la crique'));
    await tester.pumpAndSettle();

    expect(find.byType(QBDialog), findsOneWidget);
    expect(find.textContaining('12 mars'), findsOneWidget);
  });

  /// Les titres viennent du markdown de l'auteur : une aventure ajoutée au
  /// catalogue a son sommaire sans que personne n'y pense.
  testWidgets('le sommaire se construit sur les titres du déroulé',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Sommaire'), findsOneWidget);
    expect(find.bySemanticsLabel('Aller à Contexte'), findsOneWidget);
    expect(find.bySemanticsLabel('Aller à Mise en place'), findsOneWidget);
    expect(find.bySemanticsLabel('Aller à 3. Le phare'), findsOneWidget);
    expect(find.bySemanticsLabel('Aller à Indices'), findsOneWidget);
  });

  testWidgets('toucher une entrée amène à sa section', (tester) async {
    await pumpScreen(tester, height: 700);

    final before = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!
        .offset;

    await tester.tap(find.bySemanticsLabel('Aller à Indices'));
    await tester.pumpAndSettle();

    final after = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;

    expect(before, 0);
    expect(after.offset, greaterThan(0));

    // Et le retour en haut n'apparaît qu'une fois le sommaire hors de vue.
    expect(find.bySemanticsLabel('Revenir au sommaire'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Revenir au sommaire'));
    await tester.pumpAndSettle();

    expect(after.offset, 0);
    expect(find.bySemanticsLabel('Revenir au sommaire'), findsNothing);
  });
}
