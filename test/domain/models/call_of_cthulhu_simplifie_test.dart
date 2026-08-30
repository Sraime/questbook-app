import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/universe/universe_assets_loader.dart';
import 'package:questbook/domain/models/creation_mode_config.dart';
import 'package:questbook/domain/models/universe_config.dart';

/// Smoke-tests the shipped "Simplifié" / point-buy creation mode as
/// actually resolved at runtime — `universe_call_of_cthulhu.json`'s
/// `general_configuration` merged with `call_of_cthulhu_simplifie.json`'s
/// overrides (see `buildCreationModeConfig`): its 8 primary characteristics
/// are picked from a numeric list instead of rolled, unlike the
/// "Classique" mode covered in `creation_mode_config_test.dart` — even
/// though both inherit the exact same characteristics/skills/occupations
/// catalogue from the shared `general_configuration`.
void main() {
  late CreationModeConfig config;

  setUpAll(() {
    final universeRaw =
        File('assets/universes/universe_call_of_cthulhu.json').readAsStringSync();
    final universe = UniverseConfig.fromJson(jsonDecode(universeRaw) as Map<String, dynamic>);
    final entry = universe.creationModes.firstWhere((c) => c.id == 'call_of_cthulhu_simplifie');
    final modeRaw =
        File('assets/universes/${entry.configurationFile}').readAsStringSync();
    config = buildCreationModeConfig(
      universe,
      entry,
      jsonDecode(modeRaw) as Map<String, dynamic>,
    );
  });

  test('has its own id, distinct from the Classique mode', () {
    expect(config.id, 'call_of_cthulhu_simplifie');
    expect(config.universeName, 'Call of Cthulhu');
    expect(config.creationModeName, 'Simplifié');
  });

  test('exposes a creation mode description', () {
    expect(config.creationModeDescription, isNotNull);
    expect(config.creationModeDescription, isNotEmpty);
  });

  test('FOR/DEX/CON/POU/APP/EDU/INT/TAI are numeric choices, not rolled', () {
    final numericKeys =
        config.characterSheet.numericChoiceCharacteristics.map((c) => c.key).toSet();
    expect(
      numericKeys,
      {'FOR', 'DEX', 'CON', 'POU', 'APP', 'EDU', 'INT', 'TAI'},
    );
    final rollableKeys = config.characterSheet.rollableCharacteristics.map((c) => c.key);
    expect(rollableKeys, isNot(containsAll(numericKeys)));
  });

  test('a numeric choice characteristic still inherits its name from general_configuration', () {
    final force = config.characterSheet.characteristicByKey('FOR');
    expect(force.name, 'Force');
    expect(force.choices, ['40', '50', '60', '70', '80']);
    expect(force.isNumericChoice, isTrue);
    expect(force.choiceValueAt(2), 60);
  });

  test('Chance is still rolled, and Fortune is still a global attribute', () {
    expect(config.characterSheet.rollableCharacteristics.map((c) => c.key), contains('CHA'));
    expect(
      config.characterSheet.globalAttributes.map((a) => a.key),
      contains('fortune'),
    );
  });

  test('inherits the same skill/occupation catalogue as Classique, unmodified', () {
    expect(config.characterSheet.skills, isNotEmpty);
    expect(config.characterSheet.occupations, isNotEmpty);
    // Simplifié's own override file adds no skill/occupation of its own —
    // unlike Classique's "mythe_de_cthulhu" — so nothing here should be
    // Classique-specific.
    expect(config.characterSheet.skills.map((s) => s.key), isNot(contains('mythe_de_cthulhu')));
  });
}
