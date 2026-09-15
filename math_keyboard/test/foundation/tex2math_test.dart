import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';

// todo: these tests are only useful to a limited degree because we neither
// todo| directly test nodes nor properly compare the math expressions.
// todo| Note that the latter is because Expression does not override equality.
// ignore: long-method
void main() {
  _decimalSeparatorTests();
  group('constants', () {
    test('pi', () {
      const tex = r'23+{\pi}+{x}';
      const exp = '23+$pi+x';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('e', () {
      const tex = '{x}+{e}^2';
      const exp = 'x+$e^2';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('multiplication', () {
    test('cdot', () {
      const tex = r'23\cdot{x}';
      const exp = '23*x';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('times', () {
      const tex = r'23\times({var})';
      const exp = '23*var';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('implicit', () {
      const tex = '23{c}';
      const exp = '23*c';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('implicit2', () {
      const tex = '(23)({c})';
      const exp = '23*c';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('implicit3', () {
      const tex = '23^{2}({c})';
      const exp = '23^2*c';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('frac', () {
    test('basicFrac', () {
      const tex = r'\frac{1}{{x}}';
      const exp = '1/x';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('nestedFrac', () {
      const tex = r'\frac{1}{\frac{{x}}{2}}';
      const exp = '1/(x/2)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('decimal', () {
    test('0.001x', () {
      const tex = r'0.001\times{x}';
      const exp = '0.001*x';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('trigonometry', () {
    test('sin', () {
      const tex = r'2\times\sin({x})';
      const exp = '2*sin(x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('arcSin', () {
      const tex = r'\sin^{-1}({x})';
      const exp = 'arcsin(x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('cos', () {
      const tex = r'\cos({x})';
      const exp = 'cos(x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('arcCos', () {
      const tex = r'\cos^{-1}({x})';
      const exp = 'arccos(x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('tan', () {
      const tex = r'\tan({y})';
      const exp = 'tan(y)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('arcTan', () {
      const tex = r'\tan^{-1}({y})';
      const exp = 'arctan(y)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('roots', () {
    test('squareRoot', () {
      const tex = r'2 \times  \sqrt{{x}}';
      const exp = '2*nrt(2,x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('nRoot', () {
      const tex = r'2 \times  \sqrt[3]{{x}}';
      const exp = '(2.0 * (x^(1.0 / 3.0)))';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('logarithm', () {
    test('nBase', () {
      const tex = r'\log_{2.0}({x})';
      const exp = 'log(2,x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });

    test('natural', () {
      const tex = r'\ln(2{x})';
      const exp = 'ln(2*x)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });

  group('nested', () {
    test('nested1', () {
      const tex = r'-(\frac{2 \times  \sqrt{ 16 }}{{x}^2})^2';
      const exp = '(0-((2*nrt(2,16))/(x^2))^2)';
      expect(
        TeXParser(tex).parse().toString(),
        ShuntingYardParser().parse(exp).toString(),
      );
    });
  });
}

void _decimalSeparatorTests() {
  group('decimal separators', () {
    /// Parses [tex] and evaluates it to a double.
    double evaluate(String tex) =>
        TeXParser(tex).parse().evaluate(EvaluationType.REAL, ContextModel())
            as double;

    test('parses the canonical dot form', () {
      expect(evaluate('1.5'), 1.5);
      expect(evaluate('.5'), 0.5);
    });

    test('parses a bare comma', () {
      expect(evaluate('1,5'), 1.5);
      expect(evaluate(',5'), 0.5);
    });

    test('parses the grouped separator the field displays', () {
      expect(evaluate('1{,}5'), 1.5);
      expect(evaluate('1{.}5'), 1.5);
      expect(evaluate('{,}5'), 0.5);
    });

    test('parses a comma inside a larger expression', () {
      expect(evaluate(r'1{,}5+2{,}5'), 4.0);
      expect(evaluate(r'\frac{1{,}5}{0{,}5}'), 3.0);
    });

    test('keeps exponents working with either separator', () {
      expect(evaluate('1.5E2'), 150.0);
      expect(evaluate('1{,}5E2'), 150.0);
    });

    test('does not mistake a variable group for a number', () {
      final expression = TeXParser('{x}+1{,}5').parse();
      final context = ContextModel()..bindVariableName('x', Number(1));
      expect(expression.evaluate(EvaluationType.REAL, context), 2.5);
    });
  });
}
