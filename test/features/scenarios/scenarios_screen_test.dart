import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/scenarios/providers/scenario_providers.dart';
import 'package:questbook/features/scenarios/scenarios_screen.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const phare = RemoteScenarioSummary(
    id: 'sc-1',
    title: 'Le Phare de Kerloc\'h',
    description: 'Un gardien disparaît sur la côte.',
    minRecommendedPlayers: 2,
    maxRecommendedPlayers: 5,
    averageDurationMinutes: 180,
  );

  testWidgets('lists owned scenarios with a download button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSignedInProvider.overrideWithValue(true),
          scenariosOverviewProvider.overrideWith((ref) async {
            return const ScenariosOverview(
              scenarios: [phare],
              downloadedIds: {},
            );
          }),
        ],
        child: const MaterialApp(home: ScenariosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scénarios'), findsOneWidget);
    expect(find.text('Le Phare de Kerloc\'h'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Télécharger'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Ouvrir'), findsNothing);
  });

  testWidgets('offers Ouvrir once the scenario is on the device', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSignedInProvider.overrideWithValue(true),
          scenariosOverviewProvider.overrideWith((ref) async {
            return const ScenariosOverview(
              scenarios: [phare],
              downloadedIds: {'sc-1'},
            );
          }),
        ],
        child: const MaterialApp(home: ScenariosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(QBButton, 'Ouvrir'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Télécharger'), findsNothing);
    expect(find.widgetWithText(QBButton, 'Mettre à jour'), findsNothing);
  });

  testWidgets('offers the update next to Ouvrir when the catalogue moved',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSignedInProvider.overrideWithValue(true),
          scenariosOverviewProvider.overrideWith((ref) async {
            return ScenariosOverview(
              scenarios: [
                RemoteScenarioSummary(
                  id: 'sc-1',
                  title: phare.title,
                  description: phare.description,
                  minRecommendedPlayers: 2,
                  maxRecommendedPlayers: 5,
                  averageDurationMinutes: 180,
                  updatedAt: DateTime.utc(2026, 9, 26),
                ),
              ],
              downloadedIds: const {'sc-1'},
              downloadedVersions: {'sc-1': DateTime.utc(2026, 9, 20)},
            );
          }),
        ],
        child: const MaterialApp(home: ScenariosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Lire reste le geste principal : la mise a jour vient a cote, pas a la
    // place.
    expect(find.widgetWithText(QBButton, 'Ouvrir'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Mettre à jour'), findsOneWidget);
    expect(find.text('Une version plus récente existe.'), findsOneWidget);
  });
}
