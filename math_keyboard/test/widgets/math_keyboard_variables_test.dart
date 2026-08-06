import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Tests for the variable bar's overflow affordance and focus auto-scroll.
///
/// Figma a11y: with more than five symbols the keys shrink so a partial symbol
/// bleeds off the right edge (signalling the row scrolls), and the row must
/// auto-scroll to keep the focused item visible under keyboard/switch access.
void main() {
  Future<ScrollableState> pumpVariables(
    WidgetTester tester,
    List<String> variables,
  ) async {
    // Pin a portrait window so the paged layout (with the variable row on top)
    // is used instead of the landscape side-by-side layout.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboard(controller: controller, variables: variables),
        ),
      ),
    );
    await tester.pump();
    return tester.state<ScrollableState>(find.byType(Scrollable).first);
  }

  testWidgets('five or fewer variables do not scroll (no bleed)',
      (tester) async {
    final scrollable = await pumpVariables(tester, ['a', 'b', 'c', 'd', 'e']);
    expect(scrollable.position.maxScrollExtent, 0,
        reason: 'with five keys the row fits without a scroll affordance');
  });

  testWidgets('more than five variables overflow so a key bleeds off the edge',
      (tester) async {
    final scrollable = await pumpVariables(
      tester,
      ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0),
        reason: 'more than five keys overflow, bleeding a partial key');
  });

  testWidgets('the row auto-scrolls to keep the focused variable visible',
      (tester) async {
    final scrollable = await pumpVariables(
      tester,
      ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'],
    );
    expect(scrollable.position.pixels, 0);

    // Walk focus across the variable keys; a key past the visible window must
    // be scrolled into view by the onFocusChange handler.
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      if (scrollable.position.pixels > 0) break;
    }

    expect(scrollable.position.pixels, greaterThan(0),
        reason: 'focusing an off-screen variable scrolls it into view');
  });
}
