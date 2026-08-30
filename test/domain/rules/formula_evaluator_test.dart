import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/domain/rules/formula_evaluator.dart';

void main() {
  group('FormulaEvaluator.evaluate — arithmetic', () {
    test('respects operator precedence and parentheses', () {
      expect(FormulaEvaluator.evaluate('2 + 3 * 4', const {}), 14);
      expect(FormulaEvaluator.evaluate('(2 + 3) * 4', const {}), 20);
    });

    test('resolves variables case-insensitively', () {
      expect(FormulaEvaluator.evaluate('DEX / 2', {'dex': 63}), 31.5);
      expect(FormulaEvaluator.evaluate('dex / 2', {'DEX': 63}), 31.5);
    });

    test('Floor() truncates toward negative infinity', () {
      expect(FormulaEvaluator.evaluate('Floor(31.5)', const {}), 31);
      expect(FormulaEvaluator.evaluate('Floor((444 - 500) / 80)', const {}), -1);
    });

    test('Max() returns the largest of its arguments', () {
      expect(FormulaEvaluator.evaluate('Max(3, 7)', const {}), 7);
      expect(FormulaEvaluator.evaluate('Max(FOR, DEX) * 2', {'FOR': 40, 'DEX': 65}), 130);
      expect(FormulaEvaluator.evaluate('Max(1, 5, 3, 9, 2)', const {}), 9);
    });

    test('throws on unknown identifiers', () {
      expect(
        () => FormulaEvaluator.evaluate('UNKNOWN + 1', const {}),
        throwsFormatException,
      );
    });
  });

  group('FormulaEvaluator.evaluate — dice', () {
    test('NdM rolls N dice of M sides, seeded and reproducible', () {
      final dice = <int>[];
      final total = FormulaEvaluator.evaluate(
        '3D6*5',
        const {},
        random: Random(1),
        diceOut: dice,
      );
      expect(dice, hasLength(3));
      for (final d in dice) {
        expect(d, inInclusiveRange(1, 6));
      }
      expect(total, dice.fold<int>(0, (a, b) => a + b) * 5);
    });

    test('bare dM defaults the count to 1', () {
      final dice = <int>[];
      FormulaEvaluator.evaluate('d6', const {}, random: Random(2), diceOut: dice);
      expect(dice, hasLength(1));
    });

    test('does not confuse a characteristic key with dice notation', () {
      // "DEX" starts with 'D' but isn't followed by a digit, so it must
      // resolve as the variable, not a die roll.
      expect(FormulaEvaluator.evaluate('DEX', {'DEX': 50}), 50);
    });
  });

  group('FormulaEvaluator.evaluateCondition', () {
    test('comparisons and boolean combinators', () {
      expect(
        FormulaEvaluator.evaluateCondition('FOR + TAI <= 64', {'FOR': 30, 'TAI': 30}),
        isTrue,
      );
      expect(
        FormulaEvaluator.evaluateCondition(
          'FOR > TAI && DEX > TAI',
          {'FOR': 80, 'DEX': 80, 'TAI': 30},
        ),
        isTrue,
      );
      expect(
        FormulaEvaluator.evaluateCondition(
          'FOR > TAI && DEX > TAI',
          {'FOR': 80, 'DEX': 20, 'TAI': 30},
        ),
        isFalse,
      );
      expect(FormulaEvaluator.evaluateCondition('true', const {}), isTrue);
    });
  });
}
