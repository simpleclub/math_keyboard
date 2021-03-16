import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/src/foundation/node.dart';

/// Converts the input [mathExpression] to a [TeXNode].
TeXNode convertMathExpressionToTeXNode(Expression mathExpression) {
  // The AST is not properly built (as in it is not well designed) because
  // nodes do not have a common super type. If they had, it would be easy to
  // convert the expression tree to a TeX tree. Like this we need two different
  // functions for handling "nodes" and bare "TeX".
  // todo: refactor AST.
  final node = TeXNode(null);
  node.children.addAll(_convertToTeX(mathExpression, node));
  return node;
}

List<TeX> _convertToTeX(Expression mathExpression, TeXNode parent) {
  if (mathExpression is UnaryOperator) {
    return [
      if (mathExpression is UnaryMinus)
        const TeXLeaf('-')
      else
        throw UnimplementedError(),
      ..._convertToTeX(mathExpression.exp, parent),
    ];
  }
  if (mathExpression is BinaryOperator) {
    if (mathExpression is Divide) {
      return [
        TeXFunction(
          r'\frac',
          parent,
          const [TeXArg.braces, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(mathExpression.first),
            convertMathExpressionToTeXNode(mathExpression.second),
          ],
        ),
      ];
    }
    if (mathExpression is Plus) {
      return [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf('+'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    }
    if (mathExpression is Minus) {
      return [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf('-'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    }
    if (mathExpression is Times) {
      return [
        ..._convertToTeX(mathExpression.first, parent),
        const TeXLeaf(r'\cdot'),
        ..._convertToTeX(mathExpression.second, parent),
      ];
    }
    if (mathExpression is Power) {
      return [
        ..._convertToTeX(mathExpression.first, parent),
        TeXFunction(
          '^',
          parent,
          const [TeXArg.braces],
          [convertMathExpressionToTeXNode(mathExpression.second)],
        ),
      ];
    }
    // Note that modulo is unsupported.
    throw UnimplementedError();
  }
  if (mathExpression is Literal) {
    if (mathExpression is Number) {
      return [
        for (final symbol in mathExpression.value.toString().split(''))
          TeXLeaf(symbol),
      ];
    }
    if (mathExpression is Variable) {
      if (mathExpression is BoundVariable) {
        return [
          ..._convertToTeX(mathExpression.value, parent),
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
          [convertMathExpressionToTeXNode(mathExpression.exp)],
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
            convertMathExpressionToTeXNode(mathExpression.base),
            convertMathExpressionToTeXNode(mathExpression.arg),
          ],
        ),
      ];
    }
    if (mathExpression is Ln) {
      return [
        const TeXLeaf(r'\ln('),
        ..._convertToTeX(mathExpression.arg, parent),
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
            [convertMathExpressionToTeXNode(mathExpression.arg)],
          ),
        ];
      }
      return [
        TeXFunction(
          r'\sqrt',
          parent,
          const [TeXArg.brackets, TeXArg.braces],
          [
            convertMathExpressionToTeXNode(Number(mathExpression.n)),
            convertMathExpressionToTeXNode(mathExpression.arg),
          ],
        ),
      ];
    }
    if (mathExpression is Abs) {
      return [
        const TeXLeaf(r'\abs('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Sin) {
      return [
        const TeXLeaf(r'\sin('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Cos) {
      return [
        const TeXLeaf(r'\cos('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Tan) {
      return [
        const TeXLeaf(r'\tan('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Asin) {
      return [
        const TeXLeaf(r'\sin^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Acos) {
      return [
        const TeXLeaf(r'\cos^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }
    if (mathExpression is Atan) {
      return [
        const TeXLeaf(r'\tan^{-1}('),
        ..._convertToTeX(mathExpression.arg, parent),
        const TeXLeaf(')'),
      ];
    }

    throw UnimplementedError();
  }

  throw UnimplementedError();
}
