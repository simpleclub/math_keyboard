import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/src/foundation/node.dart';

/// Converts the input [mathExpression] to a [TeXNode].
TeXNode convertMathExpressionToTeXNode({
  required Expression mathExpression,
  required bool showBracket,
}) {
  // The AST is not properly built (as in it is not well designed) because
  // nodes do not have a common super type. If they had, it would be easy to
  // convert the expression tree to a TeX tree. Like this we need two different
  // functions for handling "nodes" and bare "TeX".
  // todo: refactor AST.
  final node = TeXNode(null);
  node.children.addAll(_convertToTeX(
      mathExpression: mathExpression, parent: node, showBracket: showBracket));
  return node;
}

List<TeX> _convertToTeX({
  required Expression mathExpression,
  required TeXNode parent,
  required bool showBracket,
}) {
  if (mathExpression is UnaryOperator) {
    return [
      if (mathExpression is UnaryMinus)
        const TeXLeaf('-')
      else
        throw UnimplementedError(),
      ..._convertToTeX(
          mathExpression: mathExpression.exp,
          parent: parent,
          showBracket: showBracket),
    ];
  }
  if (mathExpression is BinaryOperator) {
    List<TeX>? result;
    if (mathExpression is Divide) {
      result = [
        TeXFunction(
          r'\frac',
          parent,
          const [TeXArg.braces, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.first,
              showBracket: showBracket,
            ),
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.second,
              showBracket: showBracket,
            ),
          ],
        ),
      ];
    } else if (mathExpression is Plus) {
      result = [
        ..._convertToTeX(
          mathExpression: mathExpression.first,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf('+'),
        ..._convertToTeX(
          mathExpression: mathExpression.second,
          parent: parent,
          showBracket: showBracket,
        ),
      ];
    } else if (mathExpression is Minus) {
      result = [
        ..._convertToTeX(
          mathExpression: mathExpression.first,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf('-'),
        ..._convertToTeX(
          mathExpression: mathExpression.second,
          parent: parent,
          showBracket: showBracket,
        ),
      ];
    } else if (mathExpression is Times) {
      result = [
        ..._convertToTeX(
          mathExpression: mathExpression.first,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(r'\cdot'),
        ..._convertToTeX(
          mathExpression: mathExpression.second,
          parent: parent,
          showBracket: showBracket,
        ),
      ];
    } else if (mathExpression is Power) {
      result = [
        ..._convertToTeX(
          mathExpression: mathExpression.first,
          parent: parent,
          showBracket: showBracket,
        ),
        TeXFunction(
          '^',
          parent,
          const [TeXArg.braces],
          [
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.second,
              showBracket: showBracket,
            ),
          ],
        ),
      ];
    }
    if (result == null) {
      // Note that modulo is unsupported.
      throw UnimplementedError();
    }
    // Wrap with parentheses to keep precedence.
    return showBracket
        ? [
            TeXLeaf('('),
            ...result,
            TeXLeaf(')'),
          ]
        : result;
  }
  if (mathExpression is Literal) {
    if (mathExpression is Number) {
      final number = mathExpression.value as double;
      if (number == math.pi) {
        return [TeXLeaf(r'{\pi}')];
      }
      if (number == math.e) {
        return [TeXLeaf('{e}')];
      }
      final adjusted = number.toInt() == number ? number.toInt() : number;
      return [
        for (final symbol in adjusted.toString().split('')) TeXLeaf(symbol),
      ];
    }
    if (mathExpression is Variable) {
      if (mathExpression is BoundVariable) {
        return [
          ..._convertToTeX(
            mathExpression: mathExpression.value,
            parent: parent,
            showBracket: showBracket,
          ),
        ];
      }

      return [
        TeXLeaf('{${mathExpression.name}}'),
      ];
    }

    throw UnimplementedError();
  }
  if (mathExpression is DefaultFunction) {
    if (mathExpression is Exponential) {
      return [
        const TeXLeaf('{e}'),
        TeXFunction(
          '^',
          parent,
          const [TeXArg.braces],
          [
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.exp,
              showBracket: showBracket,
            ),
          ],
        ),
      ];
    }
    if (mathExpression is Log) {
      return [
        TeXFunction(
          r'\log_',
          parent,
          const [TeXArg.braces, TeXArg.parentheses],
          [
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.base,
              showBracket: showBracket,
            ),
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.arg,
              showBracket: showBracket,
            ),
          ],
        ),
      ];
    }
    if (mathExpression is Ln) {
      return [
        const TeXLeaf(r'\ln('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Root) {
      if (mathExpression.n == 2) {
        return [
          TeXFunction(
            r'\sqrt',
            parent,
            const [TeXArg.braces],
            [
              convertMathExpressionToTeXNode(
                mathExpression: mathExpression.arg,
                showBracket: showBracket,
              ),
            ],
          ),
        ];
      }
      return [
        TeXFunction(
          r'\sqrt',
          parent,
          const [TeXArg.brackets, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(
              mathExpression: Number(mathExpression.n),
              showBracket: showBracket,
            ),
            convertMathExpressionToTeXNode(
              mathExpression: mathExpression.arg,
              showBracket: showBracket,
            ),
          ],
        ),
      ];
    }
    if (mathExpression is Abs) {
      return [
        const TeXLeaf(r'\abs('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Sin) {
      return [
        const TeXLeaf(r'\sin('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Cos) {
      return [
        const TeXLeaf(r'\cos('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Tan) {
      return [
        const TeXLeaf(r'\tan('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Asin) {
      return [
        const TeXLeaf(r'\sin^{-1}('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Acos) {
      return [
        const TeXLeaf(r'\cos^{-1}('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Atan) {
      return [
        const TeXLeaf(r'\tan^{-1}('),
        ..._convertToTeX(
          mathExpression: mathExpression.arg,
          parent: parent,
          showBracket: showBracket,
        ),
        const TeXLeaf(')'),
      ];
    }

    throw UnimplementedError();
  }

  throw UnimplementedError();
}
