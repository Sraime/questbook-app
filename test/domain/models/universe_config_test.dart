import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/domain/models/universe_config.dart';

/// Smoke-tests the shipped `assets/universes/universe_call_of_cthulhu.json`
/// — the universe-level metadata/constants shared by every Call of Cthulhu
/// creation mode (see `creation_mode_config_test.dart` and
/// `call_of_cthulhu_simplifie_test.dart` for the modes themselves).
void main() {
  late UniverseConfig universe;

  setUpAll(() {
    final raw =
        File('assets/universes/universe_call_of_cthulhu.json').readAsStringSync();
    universe = UniverseConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('parses name/description/rulebook url', () {
    expect(universe.id, 'call_of_cthulhu');
    expect(universe.name, 'Call of Cthulhu');
    expect(universe.description, isNotEmpty);
    expect(universe.rulebookPdfUrl, startsWith('https://'));
  });

  test('has the standard 05/96 crit/fumble thresholds', () {
    expect(universe.criticalSuccessMax, 5);
    expect(universe.criticalFailureMin, 96);
  });

  test('indexes both creation modes with their override file', () {
    expect(universe.creationModes, hasLength(2));
    final ids = universe.creationModes.map((c) => c.id);
    expect(ids, containsAll(['call_of_cthulhu_classique', 'call_of_cthulhu_simplifie']));
    for (final mode in universe.creationModes) {
      expect(mode.name, isNotEmpty);
      expect(mode.configurationFile, endsWith('.json'));
      expect(
        File('assets/universes/${mode.configurationFile}').existsSync(),
        isTrue,
        reason: '${mode.configurationFile} referenced by "${mode.id}" is missing',
      );
    }
  });

  test('general_configuration holds the shared characteristics/skills/occupations catalogue', () {
    final general = universe.generalConfigurationJson;
    expect(general['characteristics'], isNotEmpty);
    expect(general['skills'], isNotEmpty);
    expect(general['occupations'], isNotEmpty);
    expect(general['resources'], isNotEmpty);
    expect(general['global_attributes'], isNotEmpty);
  });
}
