import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Verifies the keyboard exposes its sections as labelled screen-reader groups.
void main() {
  testWidgets('landscape exposes variables, functions, and numbers groups',
      (tester) async {
    final handle = tester.ensureSemantics();

    // A wide window uses the landscape layout, where all three sections are
    // visible at once.
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboard(controller: controller, variables: const ['x']),
        ),
      ),
    );
    await tester.pump();

    // The whole keyboard is one group wrapping the sections.
    expect(find.bySemanticsLabel('Math keyboard'), findsOneWidget);
    expect(find.bySemanticsLabel('Variables'), findsOneWidget);
    expect(find.bySemanticsLabel('Formula'), findsOneWidget);
    expect(find.bySemanticsLabel('Numbers'), findsOneWidget);

    // Each section is a landmark region, so a screen reader can jump to it.
    expect(tester.getSemantics(find.bySemanticsLabel('Numbers')).role,
        SemanticsRole.region);
    expect(tester.getSemantics(find.bySemanticsLabel('Formula')).role,
        SemanticsRole.region);
    // Submit is a single key, so it announces once (just the button) — no
    // redundant "Submit" region wrapping it.
    expect(find.bySemanticsLabel('Submit'), findsOneWidget);

    // Regression: the sections must be siblings. Previously the ungrouped
    // submit button node became their parent, nesting every group inside a
    // single "Submit" button.
    var node = tester.getSemantics(find.bySemanticsLabel('Numbers')).parent;
    while (node != null) {
      expect(node.flagsCollection.isButton, isFalse,
          reason: 'a section group must not be nested inside a button');
      node = node.parent;
    }

    handle.dispose();
  });

  testWidgets('portrait groups the variables and the visible page',
      (tester) async {
    final handle = tester.ensureSemantics();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathKeyboard(controller: controller, variables: const ['x']),
        ),
      ),
    );
    await tester.pump();

    // The numbers page shows first, alongside the variables.
    expect(find.bySemanticsLabel('Variables'), findsOneWidget);
    expect(find.bySemanticsLabel('Numbers'), findsOneWidget);
    expect(find.bySemanticsLabel('Formula'), findsNothing);

    // Switching to the functions page renames the page group.
    controller.togglePage();
    await tester.pump();
    expect(find.bySemanticsLabel('Formula'), findsOneWidget);
    expect(find.bySemanticsLabel('Numbers'), findsNothing);

    handle.dispose();
  });
}
