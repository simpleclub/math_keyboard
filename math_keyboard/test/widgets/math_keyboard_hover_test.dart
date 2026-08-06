import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';

/// Verifies pointer hover changes a key's background.
///
/// Regression guard: hover was driven by
/// `FocusableActionDetector.onShowHoverHighlight`, which is gated by the focus
/// highlight mode and never fired in touch mode (e.g. on web). It is now driven
/// by a plain [MouseRegion].
void main() {
  testWidgets('moving the mouse onto a key changes its background',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MathKeyboard(controller: controller)),
      ),
    );
    await tester.pump();

    final keyFinder = find.ancestor(
      of: find.text('7'),
      matching: find.byType(KeyboardButton),
    );
    final boxFinder = find
        .descendant(of: keyFinder, matching: find.byType(DecoratedBox))
        .first;
    Color? backgroundColor() =>
        (tester.widget<DecoratedBox>(boxFinder).decoration as BoxDecoration)
            .color;

    final idle = backgroundColor();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(keyFinder));
    await tester.pump();

    expect(backgroundColor(), isNot(idle),
        reason: 'the key background changes while hovered');

    // Moving away restores the idle background.
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    expect(backgroundColor(), idle);
  });
}
