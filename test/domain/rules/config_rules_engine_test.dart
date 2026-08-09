import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/domain/models/universe_config.dart';
import 'package:questbook/domain/rules/config_rules_engine.dart';
import 'package:questbook/domain/rules/rules_engine.dart';

/// Minimal hand-built config mirroring the shipped Cthulhu v7 shape, kept
/// small/deterministic on purpose — the real file is smoke-tested
/// separately in `test/domain/models/universe_config_test.dart`.
UniverseConfig _buildConfig() {
  const characteristics = [
    CharacteristicConfig(
      key: 'FOR',
      name: 'Force',
      description: '',
      calculationMethod: CalculationMethod.roll,
      calculationFormula: '3D6*5',
    ),
    CharacteristicConfig(
      key: 'DEX',
      name: 'Dextérité',
      description: '',
      calculationMethod: CalculationMethod.roll,
      calculationFormula: '3D6*5',
    ),
    CharacteristicConfig(
      key: 'TAI',
      name: 'Taille',
      description: '',
      calculationMethod: CalculationMethod.roll,
      calculationFormula: '(2D6+6)*5',
    ),
    CharacteristicConfig(
      key: 'ESQ',
      name: 'Esquive',
      description: '',
      calculationMethod: CalculationMethod.derived,
      calculationFormula: 'DEX / 2',
    ),
    CharacteristicConfig(
      key: 'MVT',
      name: 'Mouvement',
      description: '',
      calculationMethod: CalculationMethod.derived,
      conditionTable: [
        ConditionTableEntry(condition: 'FOR > TAI && DEX > TAI', value: 9),
        ConditionTableEntry(condition: 'FOR < TAI && DEX < TAI', value: 7),
        ConditionTableEntry(condition: 'true', value: 8),
      ],
    ),
    CharacteristicConfig(
      key: 'COR',
      name: 'Corpulence',
      description: '',
      calculationMethod: CalculationMethod.derived,
      conditionTable: [
        ConditionTableEntry(condition: 'FOR + TAI <= 64', value: -2),
        ConditionTableEntry(condition: 'FOR + TAI <= 124', value: 0),
        ConditionTableEntry(condition: 'true', value: '5 + Floor((FOR + TAI - 444) / 80)'),
      ],
    ),
  ];

  return const UniverseConfig(
    id: 'test-system',
    name: 'Test system',
    description: '',
    version: '',
    rulebookPdfUrl: '',
    characterSheet: CharacterSheetConfig(
      characteristics: characteristics,
      skills: [],
      occupations: [],
      resources: [],
      skillPointsFormula: 'EDU * 4',
      criticalSuccessMax: 5,
      criticalFailureMin: 96,
    ),
  );
}

void main() {
  final engine = ConfigRulesEngine(_buildConfig());

  group('rollCharacteristic', () {
    test('uses the characteristic\'s own formula, plus a flat bonus', () {
      final roll = engine.rollCharacteristic('FOR', bonus: 5, random: Random(1));
      expect(roll.dice, hasLength(3));
      expect(roll.total, roll.diceSum * 5 + 5);
    });

    test('TAI rolls (2d6+6)*5, so its dice list only has the 2 rolled d6', () {
      final roll = engine.rollCharacteristic('TAI', random: Random(7));
      expect(roll.dice, hasLength(2));
      expect(roll.total, (roll.diceSum + 6) * 5);
    });

    test('throws for a characteristic with only a condition_table (no formula)', () {
      expect(() => engine.rollCharacteristic('MVT'), throwsStateError);
    });
  });

  group('computeDerivedCharacteristics', () {
    test('ESQ is DEX/2, rounded down', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 50, 'DEX': 63, 'TAI': 50});
      expect(derived['ESQ'], 31);
    });

    test('MVT is 8 for average characteristics', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 50, 'DEX': 50, 'TAI': 50});
      expect(derived['MVT'], 8);
    });

    test('MVT is 9 when DEX and FOR both exceed TAI', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 80, 'DEX': 80, 'TAI': 30});
      expect(derived['MVT'], 9);
    });

    test('MVT is 7 when DEX and FOR are both below TAI', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 30, 'DEX': 30, 'TAI': 80});
      expect(derived['MVT'], 7);
    });

    test('COR uses the first matching condition_table tier', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 20, 'DEX': 50, 'TAI': 20});
      expect(derived['COR'], -2);
    });

    test('COR falls back to the formula-valued tier beyond the table', () {
      final derived = engine.computeDerivedCharacteristics({'FOR': 300, 'DEX': 50, 'TAI': 300});
      // FOR+TAI=600 -> 5 + Floor((600-444)/80) = 5 + 1 = 6.
      expect(derived['COR'], 6);
    });
  });

  group('rollSkillCheck', () {
    test('01-05 is always a critical success regardless of target', () {
      final random = Random(3);
      SkillCheckResult? critical;
      for (var i = 0; i < 2000 && critical == null; i++) {
        final result = engine.rollSkillCheck(1, random: random);
        if (result.roll <= 5) critical = result;
      }
      expect(critical, isNotNull);
      expect(critical!.outcome, CheckOutcome.criticalSuccess);
    });

    test('96-100 is always a critical failure regardless of target', () {
      final random = Random(4);
      SkillCheckResult? critical;
      for (var i = 0; i < 2000 && critical == null; i++) {
        final result = engine.rollSkillCheck(99, random: random);
        if (result.roll >= 96) critical = result;
      }
      expect(critical, isNotNull);
      expect(critical!.outcome, CheckOutcome.criticalFailure);
    });

    test('roll <= target (outside crit ranges) is a success', () {
      final result = engine.rollSkillCheck(50, random: Random(999));
      if (result.roll > 5 && result.roll < 96) {
        expect(
          result.outcome,
          result.roll <= 50 ? CheckOutcome.success : CheckOutcome.failure,
        );
      }
    });
  });
}
