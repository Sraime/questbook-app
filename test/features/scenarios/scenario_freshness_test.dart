import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/features/scenarios/providers/scenario_providers.dart';

RemoteScenarioSummary _summary({DateTime? updatedAt}) => RemoteScenarioSummary(
      id: 'sc-1',
      title: 'Le Phare de Kerloc\'h',
      description: 'Brume.',
      minRecommendedPlayers: 2,
      maxRecommendedPlayers: 5,
      averageDurationMinutes: 180,
      updatedAt: updatedAt,
    );

final _hier = DateTime.utc(2026, 9, 25, 12);
final _aujourdhui = DateTime.utc(2026, 9, 26, 12);

void main() {
  test('sees that the catalogue moved since the copy was taken', () {
    final overview = ScenariosOverview(
      scenarios: [_summary(updatedAt: _aujourdhui)],
      downloadedIds: const {'sc-1'},
      downloadedVersions: {'sc-1': _hier},
    );

    expect(overview.isOutdated(overview.scenarios.first), isTrue);
  });

  test('says nothing when the copy carries the same date', () {
    final overview = ScenariosOverview(
      scenarios: [_summary(updatedAt: _aujourdhui)],
      downloadedIds: const {'sc-1'},
      downloadedVersions: {'sc-1': _aujourdhui},
    );

    expect(overview.isOutdated(overview.scenarios.first), isFalse);
  });

  test('has nothing to update about an adventure that was never downloaded', () {
    final overview = ScenariosOverview(
      scenarios: [_summary(updatedAt: _aujourdhui)],
      downloadedIds: const {},
    );

    expect(overview.isOutdated(overview.scenarios.first), isFalse);
  });

  // Hors ligne, la liste elle-meme est une copie : elle ne peut pas savoir ce
  // que le serveur a fait depuis, et promettre une mise a jour qui echouera
  // serait pire que se taire.
  test('stays quiet while the list itself comes from the cache', () {
    final overview = ScenariosOverview(
      scenarios: [_summary(updatedAt: _aujourdhui)],
      downloadedIds: const {'sc-1'},
      downloadedVersions: {'sc-1': _hier},
      cachedAt: _hier,
    );

    expect(overview.isOutdated(overview.scenarios.first), isFalse);
  });

  // Telechargee avant que le mecanisme existe : son age est inconnu, et rien
  // ne prouve qu'elle soit a jour. On propose une fois, apres quoi la copie
  // portera sa date.
  test('offers the update once for a copy that predates the dates', () {
    final overview = ScenariosOverview(
      scenarios: [_summary(updatedAt: _aujourdhui)],
      downloadedIds: const {'sc-1'},
      downloadedVersions: const {'sc-1': null},
    );

    expect(overview.isOutdated(overview.scenarios.first), isTrue);
  });

  // L'inverse : un serveur trop ancien pour dater ses aventures. Aucune
  // comparaison n'est possible, et harceler serait gratuit.
  test('stays quiet when the server itself gives no date', () {
    final overview = ScenariosOverview(
      scenarios: [_summary()],
      downloadedIds: const {'sc-1'},
      downloadedVersions: const {'sc-1': null},
    );

    expect(overview.isOutdated(overview.scenarios.first), isFalse);
  });
}
