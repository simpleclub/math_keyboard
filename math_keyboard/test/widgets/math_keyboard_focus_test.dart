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

  testWidgets(
      'tab moves focus from the field into the keys, keyboard stays '
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
    expect(find.byType(MathKeyboard), findsOneWidget,
        reason: 'keyboard stays open while a key is focused');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('escape returns focus to the field and typing resumes',
      (tester) async {
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
    expect(find.byType(MathKeyboard), findsOneWidget,
        reason: 'keyboard stays open after returning to the field');

    // Physical typing works again now that the field owns focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(value(controller), '7');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'landscape traversal walks the number panel before the function '
      'panel', (tester) async {
    // The default test window (800x600) is landscape, which shows the
    // side-by-side layout; make it explicit and wide.
    tester.view.physicalSize = const Size(800, 400);
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

    String? focusedLabel() => FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<KeyboardButton>()
        ?.semanticsLabel;

    const digits = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};

    // Enter the keyboard, then tab across it, recording the order of keys until
    // the square-root function key is reached.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump();

    final beforeFirstFunction = <String>[];
    for (var i = 0; i < 25; i++) {
      final label = focusedLabel();
      if (label == 'square root') break;
      if (label != null) beforeFirstFunction.add(label);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }

    // Focus enters the number panel first, so every digit is reached before the
    // first function key, proving the two panels are not interleaved row by row.
    expect(beforeFirstFunction.where(digits.contains).toSet(), digits,
        reason: 'the whole number pad is traversed before the functions');

    await tester.pumpWidget(const SizedBox());
  });
}
