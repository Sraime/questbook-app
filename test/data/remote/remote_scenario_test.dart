import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/data/remote/scenario_api.dart';

void main() {
  test('parses a catalogue list without the heavy fields', () {
    final scenarios = ScenarioApi.parseList({
      'scenarios': [
        {
          'id': 'sc-1',
          'title': 'Le Phare de Kerloc\'h',
          'description': 'Un gardien disparaît.',
          'minRecommendedPlayers': 2,
          'maxRecommendedPlayers': 5,
          'averageDurationMinutes': 180,
        },
      ],
    });

    expect(scenarios, hasLength(1));
    expect(scenarios.single.title, 'Le Phare de Kerloc\'h');
    expect(scenarios.single.playersLabel, '2–5 joueurs');
    expect(scenarios.single.durationLabel, '3 h');
  });

  test('round-trips a downloaded document through JSON', () {
    final original = RemoteScenarioDetail.fromJson({
      'id': 'sc-1',
      'title': 'Le Phare',
      'description': 'Brume.',
      'minRecommendedPlayers': 2,
      'maxRecommendedPlayers': 4,
      'averageDurationMinutes': 90,
      'context': 'Kerloc\'h, 1924.',
      'rundownMarkdown': '## Mise en place\n\nDonner le télégramme.',
      'npcs': [
        {
          'id': 'np-1',
          'sortOrder': 0,
          'name': 'Mariette Le Goff',
          'description': 'Ment sur les dates.',
        },
      ],
      'clues': [
        {
          'id': 'cl-1',
          'sortOrder': 0,
          'title': 'Télégramme',
          'contentMarkdown': 'STOP',
        },
      ],
    });

    final again = RemoteScenarioDetail.fromJson(original.toJson());

    expect(again.context, original.context);
    expect(again.clues.single.title, 'Télégramme');
    expect(again.npcs.single.name, 'Mariette Le Goff');
    expect(again.durationLabel, '1 h 30');
  });

  /// Un scénario téléchargé avant que les annexes ne deviennent des indices
  /// dort dans la base locale sous l'ancienne clé, et il se lit hors ligne :
  /// le refuser coûterait sa soirée à quelqu'un.
  test('reads a document downloaded back when clues were called annexes', () {
    final stored = RemoteScenarioDetail.fromJson({
      'id': 'sc-1',
      'title': 'Le Phare',
      'description': 'Brume.',
      'minRecommendedPlayers': 2,
      'maxRecommendedPlayers': 4,
      'averageDurationMinutes': 90,
      'context': 'Kerloc\'h, 1924.',
      'rundownMarkdown': '## Mise en place',
      'annexes': [
        {
          'id': 'ax-1',
          'sortOrder': 0,
          'title': 'Carnet de la crique',
          'kind': 'clue',
          'contentMarkdown': '> 12 mars',
        },
      ],
    });

    expect(stored.clues.single.title, 'Carnet de la crique');
    expect(stored.npcs, isEmpty);
  });
}
