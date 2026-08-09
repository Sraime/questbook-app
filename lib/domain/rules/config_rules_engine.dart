import 'dart:math';

import '../models/universe_config.dart';
import 'formula_evaluator.dart';
import 'rules_engine.dart';

/// [RulesEngine] implementation that interprets a [UniverseConfig] instead
/// of hardcoding one system's math. Any game system describable by the
/// `assets/universes/*.json` shape — dice-rolled characteristics, and
/// derived stats via arithmetic or a `condition_table` — works through this
/// single class; only a genuinely novel mechanic would need a bespoke
/// [RulesEngine] implementation.
///
/// Division results are always rounded *down* (`.floor()`), matching Call
/// of Cthulhu 7e's own rules for stats like Hit Points/Magic Points/Esquive.
class ConfigRulesEngine implements RulesEngine {
  const ConfigRulesEngine(this.config);

  final UniverseConfig config;

  @override
  String get systemId => config.id;

  @override
  CharacteristicRoll rollCharacteristic(
    String characteristicKey, {
    int bonus = 0,
    Random? random,
  }) {
    final def = config.characterSheet.characteristicByKey(characteristicKey);
    final formula = def.calculationFormula;
    if (formula == null) {
      throw StateError(
        'Characteristic "$characteristicKey" has no calculation_formula to roll',
      );
    }
    final dice = <int>[];
    final rolled = FormulaEvaluator.evaluate(
      formula,
      const {},
      random: random,
      diceOut: dice,
    );
    return CharacteristicRoll(dice: dice, bonus: bonus, total: rolled.floor() + bonus);
  }

  @override
  Map<String, int> computeDerivedCharacteristics(Map<String, int> primary) {
    final vars = Map<String, num>.from(primary);
    final result = <String, int>{};
    for (final def in config.characterSheet.derivedCharacteristics) {
      final value = _computeDerived(def, vars);
      result[def.key] = value;
      // Later derived characteristics may reference earlier ones.
      vars[def.key] = value;
    }
    return result;
  }

  int _computeDerived(CharacteristicConfig def, Map<String, num> vars) {
    final conditionTable = def.conditionTable;
    if (conditionTable != null) {
      for (final entry in conditionTable) {
        if (FormulaEvaluator.evaluateCondition(entry.condition, vars)) {
          return _resolveValue(entry.value, vars);
        }
      }
      return 0;
    }
    final formula = def.calculationFormula;
    if (formula != null) {
      return FormulaEvaluator.evaluate(formula, vars).floor();
    }
    return 0;
  }

  int _resolveValue(Object value, Map<String, num> vars) {
    if (value is num) return value.floor();
    if (value is String) {
      final literal = num.tryParse(value);
      if (literal != null) return literal.floor();
      return FormulaEvaluator.evaluate(value, vars).floor();
    }
    return 0;
  }

  @override
  SkillCheckResult rollSkillCheck(int targetValue, {Random? random}) {
    final rng = random ?? Random();
    final roll = 1 + rng.nextInt(100);
    final CheckOutcome outcome;
    if (roll <= config.characterSheet.criticalSuccessMax) {
      outcome = CheckOutcome.criticalSuccess;
    } else if (roll >= config.characterSheet.criticalFailureMin) {
      outcome = CheckOutcome.criticalFailure;
    } else if (roll <= targetValue) {
      outcome = CheckOutcome.success;
    } else {
      outcome = CheckOutcome.failure;
    }
    return SkillCheckResult(roll: roll, outcome: outcome);
  }
}
