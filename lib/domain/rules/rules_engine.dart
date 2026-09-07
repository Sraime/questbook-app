import 'dart:math';

/// Outcome of a 1d100 skill/characteristic check.
enum CheckOutcome { criticalSuccess, success, failure, criticalFailure }

/// Result of rolling one characteristic during character creation: the
/// individual dice (for showing pips), the flat bonus applied, and the total.
class CharacteristicRoll {
  const CharacteristicRoll({
    required this.dice,
    required this.bonus,
    required this.total,
  });

  final List<int> dice;
  final int bonus;
  final int total;

  int get diceSum => dice.fold(0, (a, b) => a + b);
}

class SkillCheckResult {
  const SkillCheckResult({required this.roll, required this.outcome});

  final int roll;
  final CheckOutcome outcome;
}

/// Encapsulates one ruleset's dice mechanics and derived-stat formulas,
/// behind a system-agnostic interface. The character/stat schema stays the
/// same for every system (see domain/models); only the math plugs in here.
/// Register additional rulesets (D&D5e, Vampire…) as new implementations —
/// no schema change required.
abstract interface class RulesEngine {
  String get systemId;

  /// Rolls the characteristic identified by [characteristicKey] (its short
  /// code, e.g. `FOR`/`DEX`) using that stat's own dice formula, plus any
  /// flat [bonus].
  CharacteristicRoll rollCharacteristic(
    String characteristicKey, {
    int bonus = 0,
    Random? random,
  });

  /// Given the rolled characteristics keyed by their short code (FOR, DEX…),
  /// returns any characteristics this system derives automatically.
  Map<String, int> computeDerivedCharacteristics(Map<String, int> primary);

  SkillCheckResult rollSkillCheck(int targetValue, {Random? random});
}
