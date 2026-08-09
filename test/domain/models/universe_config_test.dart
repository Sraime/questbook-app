import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/domain/models/universe_config.dart';

/// Smoke-tests the shipped `assets/universes/cthulhu-v7.json` itself (read
/// straight off disk — `flutter test`'s working directory is the project
/// root), so a malformed edit to that file fails fast instead of only
/// surfacing at runtime.
void main() {
  late UniverseConfig config;

  setUpAll(() {
    final raw = File('assets/universes/cthulhu-v7.json').readAsStringSync();
    config = UniverseConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('parses top-level metadata', () {
    expect(config.id, 'cthulhu-v7');
    expect(config.name, isNotEmpty);
    expect(config.rulebookPdfUrl, startsWith('https://'));
  });

  test('has the 8 rollable primary characteristics plus Chance', () {
    final rollableKeys = config.characterSheet.rollableCharacteristics.map((c) => c.key);
    expect(
      rollableKeys,
      containsAll(['FOR', 'DEX', 'CON', 'POU', 'APP', 'EDU', 'INT', 'TAI', 'CHA']),
    );
  });

  test('has the 4 derived characteristics', () {
    final derivedKeys = config.characterSheet.derivedCharacteristics.map((c) => c.key);
    expect(derivedKeys, containsAll(['ESQ', 'MVT', 'COR', 'IMP']));
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

  test('every occupation has a name and at least one bonus', () {
    expect(config.characterSheet.occupations, isNotEmpty);
    for (final occupation in config.characterSheet.occupations) {
      expect(occupation.name, isNotEmpty);
      expect(
        occupation.characteristicsBonus.isNotEmpty || occupation.skillsBonus.isNotEmpty,
        isTrue,
        reason: '${occupation.key} grants no bonus at all',
      );
    }
  });

  test('occupationByName finds an occupation by its display name', () {
    final medecin = config.characterSheet.occupationByName('Médecin');
    expect(medecin, isNotNull);
    expect(medecin!.skillBonusFor('medecine'), greaterThan(0));
  });

  test('has the 3 tracked resources (PV/SAN/PM)', () {
    final keys = config.characterSheet.resources.map((r) => r.key);
    expect(keys, containsAll(['PV', 'SAN', 'PM']));
  });

  test('skill_points_formula references EDU and INT', () {
    expect(config.characterSheet.skillPointsFormula, contains('EDU'));
    expect(config.characterSheet.skillPointsFormula, contains('INT'));
  });
}
