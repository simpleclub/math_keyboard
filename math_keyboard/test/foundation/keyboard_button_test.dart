import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/src/foundation/keyboard_button.dart';

/// Collects the [MathKeyboardTool]s that are present in the given [layout].
Set<MathKeyboardTool> _toolsIn(List<List<KeyboardButtonConfig>> layout) {
  return {
    for (final row in layout)
      for (final config in row)
        if (config is BasicKeyboardButtonConfig && config.tool != null)
          config.tool!,
  };
}

/// Whether the [layout] contains any [PageButtonConfig].
bool _hasPageButton(List<List<KeyboardButtonConfig>> layout) {
  return layout.any((row) => row.any((config) => config is PageButtonConfig));
}

void main() {
  group('isKeyboardButtonAllowed', () {
    const sinButton = BasicKeyboardButtonConfig(
      label: r'\sin',
      value: r'\sin(',
      tool: MathKeyboardTool.sin,
    );
    const digitButton = BasicKeyboardButtonConfig(label: '7', value: '7');
    final deleteButton = DeleteButtonConfig();

    test('null allowedTools allows every button', () {
      expect(isKeyboardButtonAllowed(sinButton, null), isTrue);
      expect(isKeyboardButtonAllowed(digitButton, null), isTrue);
      expect(isKeyboardButtonAllowed(deleteButton, null), isTrue);
    });

    test('tagged button obeys the allowlist', () {
      expect(
        isKeyboardButtonAllowed(sinButton, {MathKeyboardTool.sin}),
        isTrue,
      );
      expect(
        isKeyboardButtonAllowed(sinButton, {MathKeyboardTool.cos}),
        isFalse,
      );
      expect(isKeyboardButtonAllowed(sinButton, const {}), isFalse);
    });

    test('digits are always allowed even for an empty allowlist', () {
      expect(isKeyboardButtonAllowed(digitButton, const {}), isTrue);
      expect(
        isKeyboardButtonAllowed(digitButton, {MathKeyboardTool.sin}),
        isTrue,
      );
    });

    test('structural buttons are always allowed', () {
      expect(isKeyboardButtonAllowed(deleteButton, const {}), isTrue);
      expect(isKeyboardButtonAllowed(PageButtonConfig(), const {}), isTrue);
    });
  });

  group('layoutHasAllowedTool', () {
    test('true when a tool is allowed (null = all)', () {
      expect(layoutHasAllowedTool(functionKeyboard, null), isTrue);
    });

    test('true when at least one contained tool is in the set', () {
      expect(
        layoutHasAllowedTool(functionKeyboard, {MathKeyboardTool.sin}),
        isTrue,
      );
    });

    test('false when no contained tool is allowed', () {
      // The standard keyboard only holds digits (untagged) plus these tools.
      expect(layoutHasAllowedTool(numberKeyboard, const {}), isFalse);
    });
  });

  group('filterKeyboardLayout', () {
    test('null allowedTools keeps every tool', () {
      final filtered = filterKeyboardLayout(functionKeyboard, null);
      expect(_toolsIn(filtered), _toolsIn(functionKeyboard));
    });

    test('keeps only the allowed tools', () {
      final filtered = filterKeyboardLayout(
        functionKeyboard,
        {MathKeyboardTool.sin, MathKeyboardTool.cos},
      );
      expect(
        _toolsIn(filtered),
        {MathKeyboardTool.sin, MathKeyboardTool.cos},
      );
    });

    test('collapses rows that become empty', () {
      // Only sin/cos live in the first two function rows; the log/ln/tan row
      // should disappear entirely.
      final filtered = filterKeyboardLayout(
        functionKeyboard,
        {MathKeyboardTool.sin, MathKeyboardTool.cos},
      );
      // No row may be empty.
      expect(filtered.every((row) => row.isNotEmpty), isTrue);
      // The row holding only log/ln/tan/atan is gone.
      expect(
        filtered.any((row) => _toolsIn([row]).contains(MathKeyboardTool.ln)),
        isFalse,
      );
    });

    test('always keeps digits in the standard keyboard', () {
      final filtered = filterKeyboardLayout(standardKeyboard, const {});
      final digits = [
        for (final row in filtered)
          for (final config in row)
            if (config is BasicKeyboardButtonConfig && config.tool == null)
              config.value,
      ];
      expect(digits, containsAll(['0', '1', '5', '9']));
    });

    test('removePageButton strips the page toggle', () {
      expect(_hasPageButton(standardKeyboard), isTrue);
      final filtered = filterKeyboardLayout(
        standardKeyboard,
        const {},
        removePageButton: true,
      );
      expect(_hasPageButton(filtered), isFalse);
    });

    test('keeps the page toggle when removePageButton is false', () {
      final filtered = filterKeyboardLayout(standardKeyboard, const {});
      expect(_hasPageButton(filtered), isTrue);
    });
  });
}
