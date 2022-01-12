// Copyright (c) 2019 DXie123
// Copyright 2021 simpleclub GmbH. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found at https://github.com/DylanXie123/Num-Plus-Plus/blob/71a959ff6c43cc0515348f6eafbe6ea529888833/LICENSE
// and by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';
import 'package:petitparser/petitparser.dart';

/// Parser for converting TeX input strings to math expressions.
///
/// Most of this code is taken from https://github.com/DylanXie123/Num-Plus-Plus.
class TeXParser {
  /// Constructs a [TeXParser].
  TeXParser(this.inputString);

  /// The TeX String to parse.
  final String inputString;

  List<dynamic> _stream = [];
  final _outputStack = <dynamic>[];
  final _operatorStack = <dynamic>[];

  /// Traverses the TeX String and creates classifies symbols.
  ///
  // ignore: code-metrics, long-method
  void tokenize() {
    /// types:
    /// b -> basic
    /// f -> function
    /// l -> left parenthesis
    /// r -> right parenthesis
    /// o+digit+(l) -> operator + precedence + (left-associativity)
    /// u -> other
    final integer = digit().plus().flatten();
    final number = ((integer | char('.').and()) &
            (char('.') & integer).pick(1).optional() &
            (char('E') & pattern('+-').optional() & integer).optional())
        .flatten()
        .map(num.parse);

    final pi = (string('{') & string(r'\pi') & string('}')).map((a) => math.pi);
    final e = (string('{') & string('e') & string('}')).map((a) => math.e);
    final variable =
        (string('{') & letter().plus().flatten() & string('}')).pick(1);

    final basic = (number | pi | e | variable).map((v) => [v, 'b']);

    final sqrt =
        (string(r'\sqrt') & char('{').and()).map((v) => [r'\sqrt', 'f']);
    final nrt = (string(r'\sqrt') & char('[').and()).map((v) => [r'\nrt', 'f']);
    final simpleFunction = ((string(r'\sin^{-1}') |
                string(r'\cos^{-1}') |
                string(r'\tan^{-1}') |
                string(r'\sin') |
                string(r'\cos') |
                string(r'\tan') |
                string(r'\ln')) &
            string('(').and())
        .pick(0)
        .map((v) => [v, 'f']);
    final otherFunction =
        (string(r'\frac') | string(r'\log')).map((v) => [v, 'f']);
    final function = simpleFunction | otherFunction | sqrt | nrt;

    final lp = (string('(') | char('{') | string(r'\left|') | char('['))
        .map((v) => [v, 'l']);

    final rp = (string(')') | char('}') | string(r'\right|') | char(']'))
        .map((v) => [v, 'r']);

    final plus = char('+').map((v) => [
          v,
          ['o', 2, 'l'],
        ]);

    final minus = char('-').map((v) => [
          v,
          ['o', 2, 'l'],
        ]);

    final times = (string(r'\times') | string(r'\cdot')).map((v) => [
          v,
          ['o', 3, 'l'],
        ]);

    final divide = string(r'\div').map((v) => [
          v,
          ['o', 3, 'l'],
        ]);

    final expo = char('^').map((v) => [
          v,
          ['o', 4, 'r'],
        ]);

    final factorial = char('!').map((v) => [
          v,
          ['o', 5, 'l'],
        ]);

    final percent = string(r'\%').map((v) => [
          v,
          ['o', 5, 'l'],
        ]);

    final operator = plus | minus | times | divide | expo | factorial | percent;

    final subNumber = (char('_') & digit().map(int.parse)).pick(1);

    final underline = char('_');

    final other = (subNumber | underline).map((v) => [v, 'u']);

    final tokenize =
        (basic | function | lp | rp | operator | other).star().end();

    final tex = inputString.replaceAll(' ', '');
    _stream = tokenize.parse(tex).value;

    if (_stream[0][0] == '-' && _stream[1][1].contains(RegExp('[bfl]'))) {
      _stream.insert(0, [0, 'b']);
    }
    if (_stream[0][0] == '!') {
      throw 'Unable to parse';
    }

    for (var i = 0; i < _stream.length; i++) {
      /// wrong syntax: fr fo lr lo oo (b/r postfix or wrong)
      /// need times: bb bf bl rb rf rl !f !l
      /// negative number: -(bfl) / l-(bfl)

      // negative number
      if (i > 0 &&
          i < _stream.length - 1 &&
          _stream[i - 1][1] == 'l' &&
          _stream[i][0] == '-' &&
          _stream[i + 1][1].contains(RegExp('[bfl]'))) {
        _stream.insert(i, [0, 'b']);
        i++;
        continue;
      }

      // add ×
      if (i < _stream.length - 1 && _stream[i][1] == 'b') {
        switch (_stream[i + 1][1]) {
          case 'b':
          case 'f':
          case 'l':
            _stream.insert(i + 1, [
              r'\times',
              ['o', 3, 'l'],
            ]);
            i++;
            break;
          default:
            break;
        }
        continue;
      }
      if (i < _stream.length - 1 && _stream[i][1] == 'r') {
        var insertTimes = false;
        switch (_stream[i + 1][1]) {
          case 'b':
          case 'f':
            insertTimes = true;
            break;
          case 'l':
            // In case there is a closing parenthesis directly followed by an
            // opening one, some further checks are necessary.
            if (_stream[i][0] == ')' && _stream[i + 1][0] == '(') {
              insertTimes = true;
            } else if (_stream[i][0] == '}' && _stream[i + 1][0] == '(') {
              // This case is unfavorable. If the '}' closes the second argument
              // of a fraction or marks the end of an exponent, we want to
              // insert 'times'. However, if '}' closes the base argument of a
              // logarithm function, we don't want to insert a times symbol.
              // That's why we have to check what's in front of the matching
              // opening '{'.
              final stack = ['}'];
              var j = i - 1;
              while (j > 0 && stack.isNotEmpty) {
                if (_stream[j][0] == '{') {
                  stack.removeLast();
                } else if (_stream[j][0] == '}') {
                  stack.add('}');
                }
                j--;
              }
              if (j >= 0 && _stream[j][0] != '_') {
                insertTimes = true;
              }
            }
            break;
          default:
            break;
        }
        if (insertTimes) {
          _stream.insert(i + 1, [
            r'\times',
            ['o', 3, 'l'],
          ]);
          i++;
        }
        continue;
      }
      if (i < _stream.length - 1 && _stream[i][0] == '!') {
        switch (_stream[i + 1][1]) {
          case 'l':
          case 'f':
            _stream.insert(i + 1, [
              r'\times',
              ['o', 3, 'l'],
            ]);
            i++;
            break;
          default:
            break;
        }
        continue;
      }

      // check wrong syntax
      if (i > 0 && (_stream[i][1] == 'r' || _stream[i][1] is List)) {
        if (_stream[i - 1][1] is List && _stream[i - 1][1][1] != 5) {
          throw 'Unable to parse';
        }
        switch (_stream[i - 1][1]) {
          case 'l':
          case 'f':
            throw 'Unable to parse';
          default:
            break;
        }
        continue;
      }
    }
  }

  /// Creates an AST from the String.
  // ignore: code-metrics
  void shuntingYard() {
    for (var i = 0; i < _stream.length; i++) {
      switch (_stream[i][1]) {
        case 'b':
          _outputStack.add(_stream[i][0]);
          break;
        case 'f':
          _operatorStack.add(_stream[i]);
          break;
        case 'l':
          if (_stream[i][0] == r'\left|') {
            _operatorStack.add([r'\abs', 'f']);
          }
          _operatorStack.add(_stream[i]);
          break;
        case 'r':
          while (_operatorStack.isNotEmpty) {
            if (_operatorStack.last[1] != 'l') {
              _outputStack.add(_operatorStack.last[0]);
              _operatorStack.removeLast();
              continue;
            } else {
              _operatorStack.removeLast();
            }
            break;
          }
          break;
        case 'u':
          if (_stream[i][0] is num) {
            _outputStack.add(_stream[i][0]);
          }
          break;
        default:
          while (_operatorStack.isNotEmpty) {
            if (_operatorStack.last[1] == 'f') {
              _outputStack.add(_operatorStack.last[0]);
              _operatorStack.removeLast();
              continue;
            }
            if (_operatorStack.last[1] is List) {
              if (_operatorStack.last[1][1] > _stream[i][1][1]) {
                _outputStack.add(_operatorStack.last[0]);
                _operatorStack.removeLast();
                continue;
              } else if (_operatorStack.last[1][1] == _stream[i][1][1] &&
                  _operatorStack.last[1][2] == 'l') {
                _outputStack.add(_operatorStack.last[0]);
                _operatorStack.removeLast();
                continue;
              }
            }
            break;
          }
          _operatorStack.add(_stream[i]);
      }
    }
    while (_operatorStack.isNotEmpty) {
      _outputStack.add(_operatorStack.last[0]);
      _operatorStack.removeLast();
    }
  }

  /// Parses TeX to math_expression.
  // ignore: code-metrics, long-method
  Expression parse() {
    tokenize();
    shuntingYard();
    final result = <Expression>[];
    Expression left;
    Expression right;
    for (var i = 0; i < _outputStack.length; i++) {
      switch (_outputStack[i]) {
        case '+':
          right = result.removeLast();
          left = result.removeLast();
          result.add(left + right);
          break;
        case '-':
          right = result.removeLast();
          left = result.removeLast();
          if (left.toString() == '0') {
            result.add(-right);
          } else {
            result.add(left - right);
          }
          break;
        case r'\times':
        case r'\cdot':
          right = result.removeLast();
          left = result.removeLast();
          result.add(left * right);
          break;
        case r'\div':
          right = result.removeLast();
          left = result.removeLast();
          result.add(left / right);
          break;
        case r'\frac':
          right = result.removeLast();
          left = result.removeLast();
          result.add(left / right);
          break;
        case '^':
          right = result.removeLast();
          left = result.removeLast();
          result.add(left ^ right);
          break;
        case r'\sin':
          result.add(Sin(result.removeLast()));
          break;
        case r'\cos':
          result.add(Cos(result.removeLast()));
          break;
        case r'\tan':
          result.add(Tan(result.removeLast()));
          break;
        case r'\sin^{-1}':
          result.add(Asin(result.removeLast()));
          break;
        case r'\cos^{-1}':
          result.add(Acos(result.removeLast()));
          break;
        case r'\tan^{-1}':
          result.add(Atan(result.removeLast()));
          break;
        case r'\ln':
          result.add(Ln(result.removeLast()));
          break;
        case r'\log':
          right = result.removeLast();
          left = result.removeLast();
          result.add(Log(left, right));
          break;
        case r'\sqrt':
          result.add(Root.sqrt(result.removeLast()));
          break;
        case r'\nrt':
          left = result.removeLast();
          right = result.removeLast();
          result.add(left ^ (Number(1.0) / right));
          break;
        case r'\abs':
          result.add(Abs(result.removeLast()));
          break;
        case '!':
          try {
            addFactorial(result);
            // ignore: empty_catches
          } catch (e) {}
          break;
        default:
          if (_outputStack[i] is String) {
            result.add(Variable(_outputStack[i]));
          } else {
            result.add(Number(_outputStack[i]));
          }
      }
    }
    // ignore: code-metrics
    if (result.length == 1) {
      return result[0];
    } else {
      throw 'Parse Error';
    }
  }

  /// Checks whether factorial can be calculated.
  void addFactorial(List<Expression> result) {
    final t = result.removeLast().evaluate(EvaluationType.REAL, ContextModel());
    if (t.ceil() == t.floor() && t >= 0 && t < 20) {
      var a = t.toInt();
      var y = 1;
      while (a > 0) {
        y = y * a ~/ 1;
        a--;
      }
      result.add(Number(y));
    } else {
      throw 'Unable to do factorial';
    }
  }
}
