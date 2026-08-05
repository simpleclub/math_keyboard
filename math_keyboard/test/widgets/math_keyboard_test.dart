import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/custom_key_icons/custom_key_icons.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(children: [child]),
    ),
  );
}

void main() {
  group('MathKeyboard allowedTools', () {
    testWidgets('shows the page toggle when function tools are allowed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(MathKeyboard(controller: MathFieldEditingController())),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CustomKeyIcons.keySymbols), findsOneWidget);
    });

    testWidgets('hides the page toggle when no function tool is allowed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MathKeyboard(
            controller: MathFieldEditingController(),
            // Only basic arithmetic on page 1 – nothing on page 2.
            allowedTools: const {
              MathKeyboardTool.add,
              MathKeyboardTool.subtract,
              MathKeyboardTool.multiply,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CustomKeyIcons.keySymbols), findsNothing);
    });

    testWidgets('keeps the page toggle when at least one page-2 tool is allowed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MathKeyboard(
            controller: MathFieldEditingController(),
            allowedTools: const {MathKeyboardTool.sin},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(CustomKeyIcons.keySymbols), findsOneWidget);
    });

    testWidgets('builds with an empty allowlist (digits + structural only)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MathKeyboard(
            controller: MathFieldEditingController(),
            allowedTools: const {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Digits are always present.
      expect(find.text('7'), findsOneWidget);
      // No page toggle since page 2 has no allowed tools.
      expect(find.byIcon(CustomKeyIcons.keySymbols), findsNothing);
    });
  });

  group('numberOnly validation & formatting', () {
    MathFieldEditingController numberController() =>
        MathFieldEditingController()..numberOnly = true;

    String type(MathFieldEditingController controller, String keys) {
      for (final key in keys.split('')) {
        controller.addLeaf(key);
      }
      return controller.currentEditingValue(placeholderWhenEmpty: false);
    }

    test('adds a leading zero for a bare decimal', () {
      expect(type(numberController(), '.5'), '0.5');
    });

    test('blocks a second decimal point', () {
      expect(type(numberController(), '5..5'), '5.5');
    });

    test('blocks a second minus', () {
      expect(type(numberController(), '--5'), '-5');
    });

    test('strips redundant leading zeros', () {
      expect(type(numberController(), '007'), '7');
    });

    test('re-formats to well-formed after a deletion', () {
      final controller = numberController();
      type(controller, '0.5'); // cursor at end: 0.5|
      controller.goBack(); // 0.|5
      controller.goBack(); // 0|.5  (cursor right after the leading zero)
      controller.goBack(deleteMode: true); // delete the `0` -> `.5` -> `0.5`
      expect(
        controller.currentEditingValue(placeholderWhenEmpty: false),
        '0.5',
      );
    });
  });
}
