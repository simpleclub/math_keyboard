import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Verifies the keyboard survives focus loss while a screen reader is active.
///
/// The keys live in a separate overlay at the end of the semantics tree, so a
/// screen-reader user's cursor leaves the field before it reaches a key. If the
/// keyboard closed on that blur, the keys would vanish before they can be
/// reached, so under [MediaQueryData.accessibleNavigation] the keyboard stays
/// open and is dismissed explicitly instead.
void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    required MathFieldEditingController controller,
    required bool accessibleNavigation,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(accessibleNavigation: accessibleNavigation),
              child: MathField(autofocus: true, controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MathKeyboard), findsOneWidget);
  }

  testWidgets('a screen-reader activation of the field opens the keyboard',
      (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MathField(controller: controller)),
      ),
    );
    await tester.pump();
    expect(find.byType(MathKeyboard), findsNothing);

    // Simulate a screen reader activating the field (e.g. VoiceOver double-tap)
    // by performing the tap semantics action on the field node.
    final node = tester.getSemantics(find.bySemanticsLabel('Math field'));
    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!
        .performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MathKeyboard), findsOneWidget,
        reason: 'activating the field via the screen reader opens the keyboard');

    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stays open when the field blurs under a screen reader',
      (tester) async {
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester, controller: controller, accessibleNavigation: true);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MathKeyboard), findsOneWidget,
        reason: 'the keyboard must remain reachable for the screen reader');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closes when the field blurs without a screen reader',
      (tester) async {
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);

    await pumpField(tester,
        controller: controller, accessibleNavigation: false);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(); // Deliver the focus change and schedule the close.
    await tester.pump(); // Run the deferred close, starting the slide-out.
    await tester.pump(const Duration(milliseconds: 400)); // Finish the slide.

    expect(find.byType(MathKeyboard), findsNothing,
        reason: 'pointer users still get tap-away-to-close');

    await tester.pumpWidget(const SizedBox());
  });
}
