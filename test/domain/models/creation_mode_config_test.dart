import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/universe/universe_assets_loader.dart';
import 'package:questbook/domain/models/creation_mode_config.dart';
import 'package:questbook/domain/models/universe_config.dart';

/// Smoke-tests the shipped Call of Cthulhu "Classique" creation mode as
/// actually resolved at runtime: `universe_call_of_cthulhu.json`'s
/// `general_configuration` merged with `call_of_cthulhu_classique.json`'s
/// overrides (see `buildCreationModeConfig`) — so a malformed edit to
/// either file fails fast instead of only surfacing at runtime.
void main() {
  late CreationModeConfig config;

  setUpAll(() {
    final universeRaw =
        File('assets/universes/universe_call_of_cthulhu.json').readAsStringSync();
    final universe = UniverseConfig.fromJson(jsonDecode(universeRaw) as Map<String, dynamic>);
    final entry = universe.creationModes.firstWhere((c) => c.id == 'call_of_cthulhu_classique');
    final modeRaw =
        File('assets/universes/${entry.configurationFile}').readAsStringSync();
    config = buildCreationModeConfig(
      universe,
      entry,
      jsonDecode(modeRaw) as Map<String, dynamic>,
    );
  });

  test('parses top-level metadata', () {
    expect(config.id, 'call_of_cthulhu_classique');
    expect(config.universeName, 'Call of Cthulhu');
    expect(config.creationModeName, 'Classique');
  });

  test('has the 8 rollable primary characteristics plus Chance', () {
    final rollableKeys = config.characterSheet.rollableCharacteristics.map((c) => c.key);
    expect(
      rollableKeys,
      containsAll(['FOR', 'DEX', 'CON', 'POU', 'APP', 'EDU', 'INT', 'TAI', 'CHA']),
    );
  });

  test('rollable characteristics inherit their name/description from general_configuration', () {
    final force = config.characterSheet.characteristicByKey('FOR');
    expect(force.name, 'Force');
    expect(force.description, isNotEmpty);
    expect(force.calculationFormula, '3D6*5');
  });

  test('has the 4 derived characteristics', () {
    final derivedKeys = config.characterSheet.derivedCharacteristics.map((c) => c.key);
    expect(derivedKeys, containsAll(['ESQ', 'MVT', 'COR', 'IMP']));
  });

  test('Fortune is a global attribute with 6 text options, not a characteristic', () {
    final attributes = config.characterSheet.globalAttributes;
    expect(attributes.map((a) => a.key), contains('fortune'));
    final fortune = attributes.firstWhere((a) => a.key == 'fortune');
    expect(fortune.type, GlobalAttributeType.choice);
    expect(
      fortune.choices,
      ['Indigent', 'Pauvre', 'Moyen', 'Aisé', 'Riche', 'Richissime'],
    );
    expect(config.characterSheet.characteristics.map((c) => c.key), isNot(contains('FTN')));
  });

  test('age is an integer global attribute with a 5–100 range', () {
    final attributes = config.characterSheet.globalAttributes;
    expect(attributes.map((a) => a.key), contains('age'));
    final age = attributes.firstWhere((a) => a.key == 'age');
    expect(age.type, GlobalAttributeType.integer);
    expect(age.min, 5);
    expect(age.max, 100);
  });

  test('occupations are offered alphabetically, accents folded', () {
    final names = config.characterSheet.occupationsAlphabetical.map((o) => o.name).toList();
    expect(names.first, 'Agent fédéral');
    expect(names, containsAll(['Antiquaire', 'Détective privé', 'Écrivain', 'Fermier']));
    // "Écrivain" folds to "ecrivain" and sits with the Es, not after Z.
    expect(names.indexOf('Diplomate'), lessThan(names.indexOf('Écrivain')));
    expect(names.indexOf('Écrivain'), lessThan(names.indexOf('Fermier')));
  });

  test('every skill exposes a max total of 100', () {
    expect(config.characterSheet.skills, isNotEmpty);
    for (final skill in config.characterSheet.skills) {
      expect(skill.max, 100, reason: '${skill.key} is missing max: 100');
    }
  });

  test('a mode file that restates every characteristic keeps its own order', () {
    final merged = CharacterSheetConfig.merge(
      general: {
        'personal_skill_points': '0',
        'characteristics': [
          {'key': 'A', 'name': 'A', 'calculation_method': 'roll'},
          {'key': 'B', 'name': 'B', 'calculation_method': 'roll'},
          {'key': 'C', 'name': 'C', 'calculation_method': 'roll'},
        ],
        'skills': <Map<String, dynamic>>[],
        'occupations': <Map<String, dynamic>>[],
        'resources': <Map<String, dynamic>>[],
      },
      overrides: {
        'characteristics': [
          {'key': 'C', 'calculation_method': 'choice', 'choices': ['1'], 'default': 1},
          {'key': 'A', 'calculation_method': 'choice', 'choices': ['1']},
          {'key': 'B', 'calculation_method': 'choice', 'choices': ['1']},
        ],
      },
    );
    expect(merged.characteristics.map((c) => c.key), ['C', 'A', 'B']);
    expect(merged.characteristicByKey('C').defaultValue, 1);
    expect(merged.characteristicByKey('A').defaultValue, isNull);
  });

  test('no skill is named "Crédit" anymore', () {
    expect(config.characterSheet.skills.any((s) => s.key == 'credit'), isFalse);
  });

  test('Classique overrides Baratin\'s base value and adds Mythe de Cthulhu', () {
    final skills = config.characterSheet.skills;
    final baratin = skills.firstWhere((s) => s.key == 'baratin');
    expect(baratin.baseValue, 10, reason: 'general_configuration has 5; Classique overrides to 10');
    expect(skills.map((s) => s.key), contains('mythe_de_cthulhu'));
  });

  test('every skill has either a base_value or a base_formula', () {
    for (final skill in config.characterSheet.skills) {
      expect(
        skill.baseValue != null || skill.baseFormula != null,
        isTrue,
        reason: '${skill.key} has neither base_value nor base_formula',
      );
    }
    expect(config.characterSheet.skills, isNotEmpty);
  });

  test('every occupation has a name', () {
    expect(config.characterSheet.occupations, isNotEmpty);
    for (final occupation in config.characterSheet.occupations) {
      expect(occupation.name, isNotEmpty);
    }
  });

  test('occupationByName finds an occupation by its display name', () {
    final medecin = config.characterSheet.occupationByName('Médecin');
    expect(medecin, isNotNull);
    expect(medecin!.occupationSkills, contains('medecine'));
  });

  test('no occupation grants an automatic flat skills_bonus anymore', () {
    for (final occupation in config.characterSheet.occupations) {
      expect(
        occupation.skillsBonus,
        isEmpty,
        reason: '${occupation.key} still has a skills_bonus; CoC7 now spends '
            'occupation skill points instead',
      );
    }
  });

  test('has the 3 tracked resources (PV/SAN/PM)', () {
    final keys = config.characterSheet.resources.map((r) => r.key);
    expect(keys, containsAll(['PV', 'SAN', 'PM']));
  });

  test('resources inherit their tone from general_configuration and formula from the override', () {
    final pv = config.characterSheet.resources.firstWhere((r) => r.key == 'PV');
    expect(pv.tone, 'danger');
    expect(pv.formula, '(CON + TAI) / 10');
  });

  test('personal_skill_points references INT', () {
    expect(config.characterSheet.personalSkillPointsFormula, contains('INT'));
  });

  test('every occupation defines occupation skill points on real skills', () {
    final skillKeys = config.characterSheet.skills.map((s) => s.key).toSet();
    for (final occupation in config.characterSheet.occupations) {
      expect(
        occupation.hasOccupationSkillPoints,
        isTrue,
        reason: '${occupation.key} is missing occupation skill points',
      );
      expect(
        occupation.occupationSkills,
        isNotEmpty,
        reason: '${occupation.key} has no occupation skills',
      );
      for (final key in occupation.occupationSkills) {
        expect(
          skillKeys.contains(key),
          isTrue,
          reason: '${occupation.key} references unknown skill "$key"',
        );
      }
      expect(occupation.occupationSkillChoices, greaterThanOrEqualTo(0));
    }
  });
}
