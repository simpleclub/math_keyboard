import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/src/foundation/math2tex.dart';
import 'package:math_keyboard/src/foundation/tex2math.dart';

// todo: refactor the conversion to enable sensible tests.
void main() {
  group('constants', () {
    test('pi', () {
      final node = convertMathExpressionToTeXNode(Parser().parse('$pi'));
      expect(node.children[0].expression, r'{\pi}');
    });

    test('e', () {
      final node = convertMathExpressionToTeXNode(Parser().parse('$e'));
      expect(node.children[0].expression, r'{e}');
    });

    test('pi2', () {
      const tex = r'23+{\pi}+{x}';
      const exp = '23+$pi+x';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('e2', () {
      const tex = '{x}+{e}^2';
      const exp = 'x+$e^2';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('multiplication', () {
    test('cdot', () {
      const tex = r'23\cdot{x}';
      const exp = '23*x';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('times', () {
      const tex = r'23\times({var})';
      const exp = '23*var';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('implicit', () {
      const tex = '23{c}';
      const exp = '23*c';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('frac', () {
    test('basicFrac', () {
      const tex = r'\frac{1}{{x}}';
      const exp = '1/x';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('nestedFrac', () {
      const tex = r'\frac{1}{\frac{{x}}{2}}';
      const exp = '1/(x/2)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('decimal', () {
    test('0.001x', () {
      const tex = r'0.001\times{x}';
      const exp = '0.001*x';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('trigonometry', () {
    test('sin', () {
      const tex = r'2\times\sin({x})';
      const exp = '2*sin(x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('arcSin', () {
      const tex = r'\sin^{-1}({x})';
      const exp = 'arcsin(x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('cos', () {
      const tex = r'\cos({x})';
      const exp = 'cos(x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('arcCos', () {
      const tex = r'\cos^{-1}({x})';
      const exp = 'arccos(x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('tan', () {
      const tex = r'\tan({y})';
      const exp = 'tan(y)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('arcTan', () {
      const tex = r'\tan^{-1}({y})';
      const exp = 'arctan(y)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('roots', () {
    test('squareRoot', () {
      const tex = r'2 \times  \sqrt{{x}}';
      const exp = '2*nrt(2,x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('logarithm', () {
    test('nBase', () {
      const tex = r'\log_{2.0}({x})';
      const exp = 'log(2,x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('natural', () {
      const tex = r'\log_{2.718281828459045}(2{x})';
      const exp = 'ln(2*x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });

  group('nested', () {
    test('nested1', () {
      const tex = r'-(\frac{2 \times  \sqrt{ 16 }}{{x}^2})^2';
      const exp = '(0-((2*nrt(2,16))/(x^2))^2)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });

    test('exponential', () {
      const tex = r'\frac{3}{2}\cdot{e}^{\frac{1}{4}\cdot{x}}';
      const exp = '3/2*e^(1/4*x)';
      expect(
        TeXParser(convertMathExpressionToTeXNode(Parser().parse(exp))
                .buildTeXString(cursorColor: null))
            .parse()
            .toString(),
        TeXParser(tex).parse().toString(),
      );
    });
  });
}
