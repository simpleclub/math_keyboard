import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:large_content_viewer/large_content_viewer.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/custom_key_icons/custom_key_icons.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';

/// Tests for the accessibility and styling additions of the redesigned
/// [MathKeyboard]: keyboard activation, text scaling, semantics, and the
/// [MathKeyboardTheme] override.
void main() {
  String value(MathFieldEditingController controller) =>
      controller.currentEditingValue(placeholderWhenEmpty: false);

  Future<void> pumpKeyboard(
    WidgetTester tester, {
    required MathFieldEditingController controller,
    TextScaler textScaler = TextScaler.noScaling,
    MathKeyboardStyle? style,
    MathKeyboardStyle? themeStyle,
    List<String> variables = const [],
    // Default to a portrait window so the paged layout is exercised; landscape
    // tests pass a wide size to trigger the side-by-side layout.
    Size viewSize = const Size(400, 800),
  }) async {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget keyboard = MathKeyboard(
      controller: controller,
      style: style,
      variables: variables,
    );
    if (themeStyle != null) {
      keyboard = MathKeyboardTheme(style: themeStyle, child: keyboard);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              // Preserve the real viewport metrics; only override the scaler.
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: keyboard,
            ),
          ),
        ),
      ),
    );
  }

  group('keyboard activation', () {
    testWidgets('a focused key activates with the Enter key', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      // Move focus to the first key in reading order, then activate it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(value(controller), '7');
    });

    testWidgets('a focused key activates with the Space key', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(value(controller), '7');
    });
  });

  group('text scaling', () {
    double labelFontSize(WidgetTester tester, String label) {
      return tester.widget<Text>(find.text(label)).style!.fontSize!;
    }

    // Resize is opt-in (maxTextScaleFactor > 1); the default keyboard is fixed
    // and relies on the large-content-viewer instead.
    final growthStyle =
        MathKeyboardStyle.fallback.copyWith(maxTextScaleFactor: 2);

    testWidgets('labels scale with the ambient text scaler when opted in',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller: controller, style: growthStyle);
      final baseSize = labelFontSize(tester, '7');

      await pumpKeyboard(
        tester,
        controller: controller,
        style: growthStyle,
        textScaler: const TextScaler.linear(2),
      );
      final scaledSize = labelFontSize(tester, '7');

      expect(scaledSize, greaterThan(baseSize));
      expect(scaledSize, baseSize * 2);
    });

    testWidgets('keys grow with the clamped text scale when opted in',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller: controller, style: growthStyle);
      final baseHeight =
          tester.getSize(find.widgetWithText(KeyboardButton, '7')).height;

      await pumpKeyboard(
        tester,
        controller: controller,
        style: growthStyle,
        textScaler: const TextScaler.linear(2),
      );
      final scaledHeight =
          tester.getSize(find.widgetWithText(KeyboardButton, '7')).height;

      // The key is its nominal height at 1x and grows with the scale, bounded
      // by maxTextScaleFactor.
      expect(baseHeight, growthStyle.keyHeight);
      expect(
          scaledHeight, growthStyle.keyHeight * growthStyle.maxTextScaleFactor);
    });

    testWidgets('key height is strictly fixed by default', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      const style = MathKeyboardStyle.fallback;

      await pumpKeyboard(
        tester,
        controller: controller,
        style: style,
        textScaler: const TextScaler.linear(2),
      );

      expect(
        tester.getSize(find.widgetWithText(KeyboardButton, '7')).height,
        style.keyHeight,
      );
    });

    testWidgets('scaling is clamped to the style maxTextScaleFactor',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(
        tester,
        controller: controller,
        style: growthStyle,
        // Far beyond the clamp.
        textScaler: const TextScaler.linear(5),
      );

      final size = labelFontSize(tester, '7');
      expect(size, growthStyle.baseFontSize * growthStyle.maxTextScaleFactor);
    });
  });

  group('semantics', () {
    testWidgets('keys expose button semantics with labels', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await pumpKeyboard(tester, controller: controller);

      expect(
        tester.getSemantics(find.byIcon(Icons.keyboard_return)),
        containsSemantics(isButton: true, label: 'Submit'),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.backspace)),
        containsSemantics(isButton: true, label: 'Delete'),
      );

      handle.dispose();
    });

    testWidgets('a digit key is a single button node, not read twice',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await pumpKeyboard(tester, controller: controller);

      // Exactly one semantics node carries the digit label (the inner Text is
      // excluded), so the screen reader announces it once.
      expect(find.bySemanticsLabel('7'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('7')),
        containsSemantics(isButton: true, label: '7'),
      );

      handle.dispose();
    });

    testWidgets('a variable key exposes a labelled button', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await pumpKeyboard(tester, controller: controller, variables: ['x']);

      expect(find.bySemanticsLabel('Variable x'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a typeset function key reads a spoken label', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await pumpKeyboard(tester, controller: controller);

      await tester.tap(find.byIcon(CustomKeyIcons.key_symbols));
      await tester.pump();

      expect(find.bySemanticsLabel('sine'), findsOneWidget);
      expect(find.bySemanticsLabel('square root'), findsOneWidget);

      handle.dispose();
    });
  });

  group('math field semantics', () {
    testWidgets('the math field is a text field exposing its value',
        (tester) async {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('+')
        ..addLeaf('8');
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathField(controller: controller, opensKeyboard: false),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Math field')),
        containsSemantics(isTextField: true, value: '7 plus 8'),
      );

      handle.dispose();
    });
  });

  group('navigation key values', () {
    testWidgets('cursor navigation keys expose the cursor context as value',
        (tester) async {
      final controller = MathFieldEditingController()..addLeaf('7');
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await pumpKeyboard(tester, controller: controller);

      expect(
        tester.getSemantics(find.byIcon(Icons.chevron_left_rounded)),
        containsSemantics(
          isButton: true,
          label: 'Move cursor left',
          value: 'end of expression',
        ),
      );

      handle.dispose();
    });
  });

  group('MathKeyboardSemantics override', () {
    testWidgets('localizes key labels through the theme', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();

      const german = MathKeyboardSemantics.fallback;
      final localized = german.copyWith(
        deleteLabel: 'Löschen',
        submitLabel: 'Bestätigen',
        variableLabel: (name) => 'Variable $name',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MathKeyboardTheme(
              style: MathKeyboardStyle.fallback,
              semantics: localized,
              child: MathKeyboard(controller: controller),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byIcon(Icons.backspace)),
        containsSemantics(isButton: true, label: 'Löschen'),
      );
      expect(
        tester.getSemantics(find.byIcon(Icons.keyboard_return)),
        containsSemantics(isButton: true, label: 'Bestätigen'),
      );

      handle.dispose();
    });

    testWidgets('localizes the cursor context announcement', (tester) async {
      final controller = MathFieldEditingController()
        ..addLeaf('7')
        ..addLeaf('8')
        ..goBack();

      final localized = MathKeyboardSemantics.fallback
          .copyWith(beforeToken: (token) => 'vor $token');

      expect(controller.describeCursorContext(localized), 'vor 8');
    });
  });

  group('large content viewer', () {
    testWidgets('content keys are wrapped for long-press magnification',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      await pumpKeyboard(tester, controller: controller);

      // A digit key can be magnified on long-press.
      expect(
        find.descendant(
          of: find.widgetWithText(KeyboardButton, '7'),
          matching: find.byType(LargeContentViewer),
        ),
        findsOneWidget,
      );

      // The submit (icon) key is not wrapped.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.keyboard_return),
          matching: find.byType(LargeContentViewer),
        ),
        findsNothing,
      );
    });

    testWidgets('can be disabled through the style', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final style =
          MathKeyboardStyle.fallback.copyWith(largeContentViewerEnabled: false);

      await pumpKeyboard(tester, controller: controller, style: style);

      expect(find.byType(LargeContentViewer), findsNothing);
    });
  });

  group('landscape layout', () {
    const landscapeSize = Size(800, 400);

    testWidgets('shows functions and numbers together with no page toggle',
        (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();

      await pumpKeyboard(
        tester,
        controller: controller,
        viewSize: landscapeSize,
      );

      // No page toggle: both pages are visible at once.
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsNothing);
      // A dedicated full-height submit key is shown.
      expect(find.byIcon(Icons.keyboard_return), findsOneWidget);
      // A number key and a function key are visible simultaneously.
      expect(find.widgetWithText(KeyboardButton, '7'), findsOneWidget);
      expect(find.bySemanticsLabel('sine'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('typing a digit works in landscape', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(
        tester,
        controller: controller,
        viewSize: landscapeSize,
      );

      await tester.tap(find.widgetWithText(KeyboardButton, '7'));
      await tester.pump();

      expect(value(controller), '7');
    });
  });

  group('MathKeyboardTheme', () {
    testWidgets('overrides the key background color', (tester) async {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      // Digits use the function/secondary tier.
      const customFunction = MathKeyboardKeyStyle(
        color: Color(0xFF123456),
        hoverColor: Color(0xFF123456),
        pressedColor: Color(0xFF123456),
      );
      final themeStyle =
          MathKeyboardStyle.fallback.copyWith(functionKey: customFunction);

      await pumpKeyboard(
        tester,
        controller: controller,
        themeStyle: themeStyle,
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.widgetWithText(KeyboardButton, '7'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF123456));
    });
  });

  group('MathKeyboardStyle value semantics', () {
    test('copyWith replaces only the given fields', () {
      const style = MathKeyboardStyle.fallback;
      final copy = style.copyWith(rowSpacing: 12);

      expect(copy.rowSpacing, 12);
      expect(copy.backgroundColor, style.backgroundColor);
      expect(copy, isNot(style));
      expect(style.copyWith(), style);
    });
  });
}
