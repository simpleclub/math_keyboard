import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';

/// Focus-behavior tests for [MathField] and its on-screen keyboard.
///
/// These lock down the focus handoff between the field and the keys: the
/// keyboard must not close while a key holds focus (its visibility tracks focus
/// in *either* place), tab enters the keys, and escape returns to the field so
/// physical typing resumes.
void main() {
  String value(MathFieldEditingController controller) =>
      controller.currentEditingValue(placeholderWhenEmpty: false);

  bool aKeyIsFocused() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<KeyboardButton>() !=
      null;

  Future<void> pumpFocusedField(
    WidgetTester tester,
    MathFieldEditingController controller,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathField(autofocus: true, controller: controller),
        ),
      ),
    );
    // Advance past the keyboard slide-in animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MathKeyboard), findsOneWidget);
  }

  testWidgets('tab moves focus from the field into the keys, keyboard stays '
      'open', (tester) async {
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await pumpFocusedField(tester, controller);
    expect(aKeyIsFocused(), isFalse, reason: 'field owns focus initially');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    // Let the deferred close-check run; it must keep the keyboard open because
    // a key now holds focus.
    await tester.pump();
    await tester.pump();

    expect(aKeyIsFocused(), isTrue, reason: 'tab hands focus to a key');
    expect(
      find.byType(MathKeyboard),
      findsOneWidget,
      reason: 'keyboard stays open while a key is focused',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('escape returns focus to the field and typing resumes', (
    tester,
  ) async {
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await pumpFocusedField(tester, controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();
    expect(aKeyIsFocused(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();

    expect(aKeyIsFocused(), isFalse, reason: 'escape returns focus to field');

    // Physical typing works again now that the field owns focus (the keyboard
    // is dismissed, but the field still accepts hardware input).
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(value(controller), '7');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('escape dismisses the keyboard while the field holds focus', (
    tester,
  ) async {
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await pumpFocusedField(tester, controller);
    // The field (not a key) holds focus here — escape must still dismiss.
    expect(aKeyIsFocused(), isFalse, reason: 'field owns focus');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(MathKeyboard),
      findsNothing,
      reason: 'escape from the field dismisses the keyboard',
    );

    // The field keeps focus (nothing swallowed the suppression flag), so
    // physical input still works.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(value(controller), '7');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'tab traverses the keys as buttons and exits at the end (no trap)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = MathFieldEditingController();
      final trailingFocus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(trailingFocus.dispose);

      // A control after the field, so tabbing out of the keyboard has somewhere
      // to land (proving focus is not trapped, WCAG 2.1.2).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MathField(autofocus: true, controller: controller),
                Focus(focusNode: trailingFocus, child: const Text('after')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      String? focusedLabel() => FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<KeyboardButton>()
          ?.semanticsLabel;

      // Tab from the field moves onto the first key.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump();
      final first = focusedLabel();
      expect(first, isNotNull, reason: 'tab enters the keyboard');

      // Another tab moves to a different key (traversal, not exit).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        focusedLabel(),
        isNotNull,
        reason: 'tab moves key to key, still inside the keyboard',
      );
      expect(focusedLabel(), isNot(first), reason: 'it moved to another key');

      // Arrow keys also move between keys.
      final beforeArrow = focusedLabel();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        focusedLabel(),
        isNot(beforeArrow),
        reason: 'arrow keys move between keys',
      );

      // Tabbing to the end eventually leaves the keyboard for the next control —
      // it must not wrap back into the keys.
      for (var i = 0; i < 40 && !trailingFocus.hasFocus; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        trailingFocus.hasFocus,
        isTrue,
        reason: 'tab past the last key exits to the next control, not trapped',
      );

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('escape closes the keyboard', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathField(autofocus: true, controller: controller),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MathKeyboard), findsOneWidget);

    // Move onto the keys, then press escape.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(MathKeyboard),
      findsNothing,
      reason: 'escape dismisses the keyboard',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tab traverses out normally when the keyboard is not open', (
    tester,
  ) async {
    final controller = MathFieldEditingController();
    final after = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(after.dispose);

    // opensKeyboard:false keeps the keyboard closed while the field is focused —
    // the state where Tab used to be swallowed and crash on the unmounted scope.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MathField(
                autofocus: true,
                controller: controller,
                opensKeyboard: false,
              ),
              Focus(focusNode: after, child: const Text('after')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(tester.takeException(), isNull, reason: 'Tab must not crash');
    expect(
      after.hasFocus,
      isTrue,
      reason: 'Tab moves to the next control instead of being swallowed',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
