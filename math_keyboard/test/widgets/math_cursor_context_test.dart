import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/foundation/node.dart';

/// Tests for [MathFieldEditingController.describeCursorContext], which produces
/// the screen-reader announcement describing where the cursor is after a
/// navigation.
void main() {
  group('describeCursorContext', () {
    test('reports the end of the expression at the trailing boundary', () {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('8');

      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'end of expression');
    });

    test('reports the start of the expression at the leading boundary', () {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('8')
        ..goBack()
        ..goBack();

      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'start of expression');
    });

    test('reports the token after the cursor once it moves left', () {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('8')
        ..goBack();

      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'before 8');
    });

    test('speaks operators as words', () {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('+')
        ..goBack();

      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'before plus');
    });

    test('describes an empty function argument structurally', () {
      final controller = MathFieldEditingController()
        ..addFunction(r'\sqrt', [TeXArg.braces]);

      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'under the square root, empty');
    });

    test('describes the numerator of a fraction', () {
      final controller = MathFieldEditingController()
        ..addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);

      // A fresh fraction places the cursor in the (empty) numerator.
      expect(controller.describeCursorContext(MathKeyboardSemantics.fallback),
          'numerator, empty');
    });
  });
}
