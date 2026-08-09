import 'dart:math';

/// Tiny arithmetic/boolean/dice expression evaluator for the formula and
/// condition strings found in a universe config (`calculation_formula`,
/// `condition_table[].condition`/`value`, `skill_points_formula`,
/// `resources[].formula`, skills' `base_formula`…).
///
/// Grammar (booleans are represented as 1/0, so a "condition" is just an
/// expression whose result is compared to zero):
/// ```
/// or      := and ('||' and)*
/// and     := cmp ('&&' cmp)*
/// cmp     := add (('>='|'<='|'=='|'!='|'>'|'<') add)?
/// add     := mul (('+'|'-') mul)*
/// mul     := unary (('*'|'/') unary)*
/// unary   := '-' unary | primary
/// primary := number | dice | 'Floor(' or ')' | identifier | '(' or ')'
/// ```
/// Dice tokens look like `3D6`/`3d6`/`d6` (count defaults to 1). Each one
/// rolls immediately against the supplied [Random] and is appended to
/// `diceOut`, so callers can show the individual pips that made up a total
/// (see `CharacteristicRoll.dice`).
///
/// Identifiers are resolved from `variables` case-insensitively (matching
/// characteristic short keys like `DEX`); the bare literals `true`/`false`
/// are also recognised.
class FormulaEvaluator {
  FormulaEvaluator._(this._expr, this._vars, this._random, this._diceOut);

  /// Evaluates [expression], rolling any dice tokens against [random] (a
  /// fresh [Random] if omitted) and recording each individual die rolled
  /// into [diceOut] in encounter order.
  static num evaluate(
    String expression,
    Map<String, num> variables, {
    Random? random,
    List<int>? diceOut,
  }) {
    final upperVars = <String, num>{
      for (final entry in variables.entries) entry.key.toUpperCase(): entry.value,
    };
    final evaluator = FormulaEvaluator._(
      expression,
      upperVars,
      random ?? Random(),
      diceOut,
    );
    final result = evaluator._parseOr();
    evaluator._skipWhitespace();
    if (evaluator._pos != evaluator._expr.length) {
      throw FormatException(
        'Unexpected trailing input at position ${evaluator._pos} in "$expression"',
      );
    }
    return result;
  }

  /// Convenience for condition strings: non-zero is `true`. Never rolls
  /// dice — conditions in this codebase only compare already-known stats.
  static bool evaluateCondition(String condition, Map<String, num> variables) {
    return evaluate(condition, variables) != 0;
  }

  final String _expr;
  final Map<String, num> _vars;
  final Random _random;
  final List<int>? _diceOut;
  int _pos = 0;

  // No leading `^` here: matchAsPrefix(string, start) already constrains
  // the match to begin exactly at `start` — a literal `^` would instead
  // (and wrongly) require `start` to be 0, since Dart's `^` anchors to the
  // beginning of the whole string, not to matchAsPrefix's start index.
  static final _diceRegExp = RegExp(r'(\d*)[dD](\d+)');
  static final _numberRegExp = RegExp(r'\d+(\.\d+)?');
  static final _identifierRegExp = RegExp(r'[A-Za-zÀ-ÿ_][A-Za-zÀ-ÿ0-9_]*');

  void _skipWhitespace() {
    while (_pos < _expr.length && _expr[_pos].trim().isEmpty) {
      _pos++;
    }
  }

  bool _consume(String token) {
    _skipWhitespace();
    if (_expr.startsWith(token, _pos)) {
      _pos += token.length;
      return true;
    }
    return false;
  }

  num _parseOr() {
    var left = _parseAnd();
    while (_consume('||')) {
      final right = _parseAnd();
      left = (left != 0 || right != 0) ? 1 : 0;
    }
    return left;
  }

  num _parseAnd() {
    var left = _parseComparison();
    while (_consume('&&')) {
      final right = _parseComparison();
      left = (left != 0 && right != 0) ? 1 : 0;
    }
    return left;
  }

  static const _comparisonOps = ['>=', '<=', '==', '!=', '>', '<'];

  num _parseComparison() {
    final left = _parseAdd();
    for (final op in _comparisonOps) {
      final savedPos = _pos;
      if (_consume(op)) {
        final right = _parseAdd();
        final result = switch (op) {
          '>=' => left >= right,
          '<=' => left <= right,
          '==' => left == right,
          '!=' => left != right,
          '>' => left > right,
          '<' => left < right,
          _ => false,
        };
        return result ? 1 : 0;
      }
      _pos = savedPos;
    }
    return left;
  }

  num _parseAdd() {
    var left = _parseMul();
    while (true) {
      if (_consume('+')) {
        left += _parseMul();
      } else if (_consume('-')) {
        left -= _parseMul();
      } else {
        break;
      }
    }
    return left;
  }

  num _parseMul() {
    var left = _parseUnary();
    while (true) {
      if (_consume('*')) {
        left *= _parseUnary();
      } else if (_consume('/')) {
        left /= _parseUnary();
      } else {
        break;
      }
    }
    return left;
  }

  num _parseUnary() {
    if (_consume('-')) {
      return -_parseUnary();
    }
    return _parsePrimary();
  }

  num _parsePrimary() {
    _skipWhitespace();

    if (_consume('(')) {
      final value = _parseOr();
      if (!_consume(')')) {
        throw FormatException('Expected ")" at position $_pos in "$_expr"');
      }
      return value;
    }

    if (_expr.startsWith('Floor', _pos) || _expr.startsWith('floor', _pos)) {
      final savedPos = _pos;
      _pos += 5;
      if (_consume('(')) {
        final value = _parseOr();
        if (!_consume(')')) {
          throw FormatException('Expected ")" after Floor(...) in "$_expr"');
        }
        return value.floor();
      }
      _pos = savedPos;
    }

    final diceMatch = _diceRegExp.matchAsPrefix(_expr, _pos);
    if (diceMatch != null) {
      _pos = diceMatch.end;
      final count = diceMatch.group(1)!.isEmpty ? 1 : int.parse(diceMatch.group(1)!);
      final sides = int.parse(diceMatch.group(2)!);
      var sum = 0;
      for (var i = 0; i < count; i++) {
        final roll = 1 + _random.nextInt(sides);
        sum += roll;
        _diceOut?.add(roll);
      }
      return sum;
    }

    final numberMatch = _numberRegExp.matchAsPrefix(_expr, _pos);
    if (numberMatch != null) {
      _pos = numberMatch.end;
      return num.parse(numberMatch.group(0)!);
    }

    final identifierMatch = _identifierRegExp.matchAsPrefix(_expr, _pos);
    if (identifierMatch != null) {
      _pos = identifierMatch.end;
      final name = identifierMatch.group(0)!;
      final upper = name.toUpperCase();
      if (upper == 'TRUE') return 1;
      if (upper == 'FALSE') return 0;
      final value = _vars[upper];
      if (value == null) {
        throw FormatException('Unknown identifier "$name" in "$_expr"');
      }
      return value;
    }

    throw FormatException('Unexpected character at position $_pos in "$_expr"');
  }
}
