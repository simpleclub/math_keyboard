import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/src/foundation/number_format.dart';

void main() {
  group('applyNumberInput', () {
    /// Helper that asserts both the resulting text and caret position.
    void expectInput(
      String current,
      int cursor,
      String insert, {
      required String text,
      required int caret,
    }) {
      final result = applyNumberInput(current, cursor, insert);
      expect(result.text, text,
          reason: '"$current"@$cursor + "$insert" -> text');
      expect(result.cursor, caret,
          reason: '"$current"@$cursor + "$insert" -> cursor');
    }

    test('inserts a plain digit', () {
      expectInput('', 0, '5', text: '5', caret: 1);
      expectInput('12', 2, '3', text: '123', caret: 3);
    });

    group('single leading minus', () {
      test('allows a leading minus on empty input', () {
        expectInput('', 0, '-', text: '-', caret: 1);
      });

      test('prepends a minus before existing digits', () {
        expectInput('123', 0, '-', text: '-123', caret: 1);
      });

      test('rejects a second minus', () {
        expectInput('-5', 2, '-', text: '-5', caret: 2);
        expectInput('-', 1, '-', text: '-', caret: 1);
      });

      test('rejects a minus that is not leading', () {
        expectInput('5', 1, '-', text: '5', caret: 1);
        expectInput('12', 1, '-', text: '12', caret: 1);
      });
    });

    group('single decimal point', () {
      test('allows one decimal point', () {
        expectInput('12', 2, '.', text: '12.', caret: 3);
        expectInput('12.', 3, '5', text: '12.5', caret: 4);
      });

      test('rejects a second decimal point', () {
        expectInput('5.5', 3, '.', text: '5.5', caret: 3);
        expectInput('5.', 2, '.', text: '5.', caret: 2);
      });
    });

    group('leading zero for decimals', () {
      test('bare decimal gains a leading zero', () {
        expectInput('', 0, '.', text: '0.', caret: 2);
      });

      test('decimal after a sign gains a leading zero', () {
        expectInput('-', 1, '.', text: '-0.', caret: 3);
      });

      test('keeps the zero before the point while typing the fraction', () {
        expectInput('0.', 2, '5', text: '0.5', caret: 3);
      });
    });

    group('strip redundant leading zeros', () {
      test('replaces a lone zero when typing a non-zero digit', () {
        expectInput('0', 1, '5', text: '5', caret: 1);
      });

      test('collapses a second zero', () {
        expectInput('0', 1, '0', text: '0', caret: 1);
      });

      test('keeps a single zero on its own', () {
        expectInput('', 0, '0', text: '0', caret: 1);
      });

      test('strips leading zeros after a sign', () {
        expectInput('-0', 2, '5', text: '-5', caret: 2);
      });

      test('does not strip zeros in the fraction', () {
        expectInput('0.0', 3, '5', text: '0.05', caret: 4);
      });
    });

    group('mid-cursor insertion', () {
      test('inserts a decimal point in the middle', () {
        expectInput('12', 1, '.', text: '1.2', caret: 2);
      });
    });
  });

  group('normalizeNumber', () {
    void expectNormalize(
      String current,
      int cursor, {
      required String text,
      required int caret,
    }) {
      final result = normalizeNumber(current, cursor);
      expect(result.text, text, reason: '"$current"@$cursor -> text');
      expect(result.cursor, caret, reason: '"$current"@$cursor -> cursor');
    }

    test('restores a leading zero after the integer digit is deleted', () {
      // Deleting the `0` from `0.5` leaves `.5`, which normalizes back to `0.5`.
      expectNormalize('.5', 0, text: '0.5', caret: 1);
    });

    test('keeps a bare minus after its digit is deleted', () {
      expectNormalize('-', 1, text: '-', caret: 1);
    });

    test('leaves an already well-formed number untouched', () {
      expectNormalize('12.5', 2, text: '12.5', caret: 2);
    });
  });
}
