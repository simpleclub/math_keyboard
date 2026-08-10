import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/custom_key_icons/custom_key_icons.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';

/// Characterization tests that lock down the interactive behavior of the
/// [MathKeyboard] (button -> controller action mapping, page toggling, keyboard
/// type differences, variables, and submit) so that a visual/accessibility
/// refactor can be verified as behavior-preserving.
void main() {
  /// Returns the current expression without the empty-value placeholder.
  String value(MathFieldEditingController controller) =>
      controller.currentEditingValue(placeholderWhenEmpty: false);

  Future<void> pumpKeyboard(
    WidgetTester tester, {
    required MathFieldEditingController controller,
    MathKeyboardType type = MathKeyboardType.expression,
    List<String> variables = const [],
    VoidCallback? onSubmit,
  }) async {
    // Pin a portrait window so the paged layout is exercised (the default test
    // window is landscape, which would switch to the side-by-side layout).
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboard(
            controller: controller,
            type: type,
            variables: variables,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  group('MathKeyboard button mapping', () {
    testWidgets('tapping a digit adds it to the expression', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.widgetWithText(KeyboardButton, '7'));
      await tester.pump();

      expect(value(controller), '7');
    });

    testWidgets('tapping the subtract key adds a minus', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.widgetWithText(KeyboardButton, '−'));
      await tester.pump();

      expect(value(controller), '-');
    });

    testWidgets('tapping the decimal key adds a decimal point', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.widgetWithText(KeyboardButton, '.'));
      await tester.pump();

      expect(value(controller), '.');
    });

    testWidgets('tapping delete removes the last input', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      controller.addLeaf('7');
      await pumpKeyboard(tester, controller: controller);
      expect(value(controller), '7');

      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pump();

      expect(value(controller), '');
    });

    testWidgets('tapping submit invokes the onSubmit callback', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      var submitted = false;
      await pumpKeyboard(
        tester,
        controller: controller,
        onSubmit: () => submitted = true,
      );

      await tester.tap(find.byIcon(Icons.keyboard_return));
      await tester.pump();

      expect(submitted, isTrue);
    });

    testWidgets('cursor navigation keys move without deleting', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      controller
        ..addLeaf('7')
        ..addLeaf('8');
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();

      expect(value(controller), '78');
    });
  });

  group('MathKeyboard pages and types', () {
    testWidgets('page toggle switches to the function page and back', (
      tester,
    ) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      expect(find.byIcon(CustomKeyIcons.key_symbols), findsOneWidget);
      expect(find.text('123'), findsNothing);

      await tester.tap(find.byIcon(CustomKeyIcons.key_symbols));
      await tester.pump();

      // The function page used to overflow its wider TeX labels (log, the
      // inverse trig functions), see
      // https://github.com/simpleclub/math_keyboard/issues/32. The keys now
      // scale their labels down to fit, so rendering the page must not throw.
      expect(tester.takeException(), isNull);

      expect(controller.secondPage, isTrue);
      expect(find.text('123'), findsOneWidget);
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsNothing);

      await tester.tap(find.widgetWithText(KeyboardButton, '123'));
      await tester.pump();

      expect(controller.secondPage, isFalse);
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsOneWidget);
    });

    testWidgets('numberOnly keyboard omits the page toggle but types digits', (
      tester,
    ) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(
        tester,
        controller: controller,
        type: MathKeyboardType.numberOnly,
      );

      expect(find.byIcon(CustomKeyIcons.key_symbols), findsNothing);

      await tester.tap(find.widgetWithText(KeyboardButton, '9'));
      await tester.pump();

      expect(value(controller), '9');
    });

    testWidgets('numberOnly keyboard survives a togglePage to the missing '
        'second page', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(
        tester,
        controller: controller,
        type: MathKeyboardType.numberOnly,
      );

      // A number-only keyboard has no second page; toggling it (a public API)
      // must not crash on a null `page2`.
      controller.togglePage();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(KeyboardButton, '9'), findsOneWidget);
    });

    testWidgets('expression keyboard renders the navigation icons', (
      tester,
    ) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      expect(find.byIcon(Icons.backspace), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_return), findsOneWidget);
    });
  });

  group('MathKeyboard variables', () {
    testWidgets('tapping a variable inserts it into the expression', (
      tester,
    ) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller, variables: ['y']);

      // The variables row is built before the button rows, so the first
      // keyboard button is the variable.
      await tester.tap(find.byType(KeyboardButton).first);
      await tester.pump();

      expect(value(controller), contains('y'));
    });
  });

  group('MathField integration', () {
    testWidgets('opens the math keyboard overlay when focused', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      String? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathField(
              autofocus: true,
              controller: controller,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );

      // Advance past the keyboard slide-in animation.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MathKeyboard), findsOneWidget);

      await tester.tap(find.widgetWithText(KeyboardButton, '5'));
      await tester.pump();

      expect(changed, '5');

      // Remove the field so its repeating cursor-blink ticker is disposed.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
