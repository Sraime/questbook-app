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
      'annexes': [
        {
          'id': 'ax-1',
          'sortOrder': 0,
          'title': 'Télégramme',
          'kind': 'handout',
          'contentMarkdown': 'STOP',
        },
      ],
    });

    final again = RemoteScenarioDetail.fromJson(original.toJson());

    expect(again.context, original.context);
    expect(again.annexes.single.title, 'Télégramme');
    expect(again.durationLabel, '1 h 30');
  });
}
