import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_keyboard/src/custom_key_icons/custom_key_icons.dart';

class TestWrapper extends StatelessWidget {
  const TestWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: child,
    );
  }
}

void main() {
  testWidgets(
    'Control test to ensure the default keyboard is shown on the page',
    (tester) async {
      final controller = MathFieldEditingController();

      await tester.pumpWidget(TestWrapper(
        child: MathKeyboard(
          controller: controller,
        ),
      ));
      expect(find.byType(MathKeyboard), findsOneWidget);

      controller.dispose();
    },
  );

  testWidgets(
    'Test that updating the keyboard page using controller works correctly',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          // The default width of a the test widget view is too small to
          // render the expressions keyboard without overflow.
          // We'll decrease the font size of the keyboard text in order to test
          // without getting overflow errors.
          fontSize: 16,
        ),
      );

      await tester.pumpWidget(tree);

      // Check that the toggle page button shows the symbol for the next page
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('123'), findsNothing);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check again that keyboard shows the correct symbol for the next page
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsNothing);
      expect(find.text('5'), findsNothing);
      expect(find.text('123'), findsOneWidget);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check that we've returned again to the first page
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('123'), findsNothing);
    },
  );

  testWidgets(
    'Test that updating the keyboard page using the button works correctly',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          // The default width of a the test widget view is too small to
          // render the expressions keyboard without overflow.
          // We'll decrease the font size of the keyboard text in order to test
          // without getting overflow errors.
          fontSize: 16,
        ),
      );

      await tester.pumpWidget(tree);

      // Check that we are on the first page
      expect(controller.page, equals(0));
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.byIcon(CustomKeyIcons.key_symbols));
      await tester.pumpWidget(tree);

      // Check that we've moved to the second page
      expect(controller.page, equals(1));
      expect(find.text('5'), findsNothing);

      await tester.tap(find.text('123'));
      await tester.pumpWidget(tree);

      // Check that we've moved back to the first page (and that pages have looped correctly)
      expect(controller.page, equals(2));
      expect(find.byIcon(CustomKeyIcons.key_symbols), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('123'), findsNothing);
    },
  );

  testWidgets(
    'Test that updating the keyboard page on a numbers-only keyboard has no effect',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          type: MathKeyboardType.numberOnly,
        ),
      );

      await tester.pumpWidget(tree);

      // Check that we are on the first page
      expect(controller.page, equals(0));
      expect(find.text('5'), findsOneWidget);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check that we've incremented our page, but that we're actually still
      // on the number-only page.
      expect(controller.page, equals(1));
      expect(find.text('5'), findsOneWidget);
    },
  );

  testWidgets(
    'Test that displaying a custom keyboard page is possible',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          type: MathKeyboardType.custom,
          customPages: [
            CustomButtonPage(buttonLayout: [
              [
                BasicKeyboardButtonConfig(
                  label: 'TEST',
                  value: '',
                ),
              ]
            ]),
          ],
        ),
      );

      await tester.pumpWidget(tree);

      // Check that the custom button is visible
      expect(find.text('TEST'), findsOneWidget);
    },
  );

  testWidgets(
    'Test that we can toggle between multiple custom keyboard pages',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          type: MathKeyboardType.custom,
          customPages: [
            CustomButtonPage(buttonLayout: [
              [
                BasicKeyboardButtonConfig(
                  label: 'TEST 0',
                  value: '',
                ),
              ]
            ]),
            CustomButtonPage(buttonLayout: [
              [
                BasicKeyboardButtonConfig(
                  label: 'TEST 1',
                  value: '',
                ),
              ]
            ]),
            CustomButtonPage(buttonLayout: [
              [
                BasicKeyboardButtonConfig(
                  label: 'TEST 2',
                  value: '',
                ),
              ]
            ]),
          ],
        ),
      );

      await tester.pumpWidget(tree);

      // Check that the first custom page is visible
      expect(find.text('TEST 0'), findsOneWidget);
      // Check that no other pages are visible
      expect(find.text('TEST 1'), findsNothing);
      expect(find.text('TEST 2'), findsNothing);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check that the second custom page is visible
      expect(find.text('TEST 1'), findsOneWidget);
      // Check that the first page is no longer visible
      expect(find.text('TEST 0'), findsNothing);
      // Check that the last page is still not visible
      expect(find.text('TEST 2'), findsNothing);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check that the last custom page is visible
      expect(find.text('TEST 2'), findsOneWidget);
      // Check that the first page is still not visible
      expect(find.text('TEST 0'), findsNothing);
      // Check that the middle page is no longer visible
      expect(find.text('TEST 1'), findsNothing);

      controller.togglePage();
      await tester.pumpWidget(tree);

      // Check that we've wrapped around and the first custom page is visible
      expect(find.text('TEST 0'), findsOneWidget);
      // Check that the middle page is still not visible
      expect(find.text('TEST 1'), findsNothing);
      // Check that the last page is no longer visible
      expect(find.text('TEST 2'), findsNothing);
    },
  );

  testWidgets(
    'Test that we can toggle multiple custom keyboard pages using a button',
    (tester) async {
      final controller = MathFieldEditingController();
      final tree = TestWrapper(
        child: MathKeyboard(
          controller: controller,
          type: MathKeyboardType.custom,
          customPages: [
            CustomButtonPage(
              label: 'Page 0',
              buttonLayout: [
                [
                  BasicKeyboardButtonConfig(
                    label: 'TEST 0',
                    value: '',
                  ),
                  PageButtonConfig(),
                ]
              ],
            ),
            CustomButtonPage(
              label: 'Page 1',
              buttonLayout: [
                [
                  BasicKeyboardButtonConfig(
                    label: 'TEST 1',
                    value: '',
                  ),
                  PageButtonConfig(),
                ]
              ],
            ),
            CustomButtonPage(
              label: 'Page 2',
              buttonLayout: [
                [
                  BasicKeyboardButtonConfig(
                    label: 'TEST 2',
                    value: '',
                  ),
                  PageButtonConfig(),
                ]
              ],
            ),
          ],
        ),
      );

      await tester.pumpWidget(tree);

      // Check that the first custom page is visible
      expect(find.text('TEST 0'), findsOneWidget);
      // Check that no other pages are visible
      expect(find.text('TEST 1'), findsNothing);
      expect(find.text('TEST 2'), findsNothing);
      // Check that the correct label for the next page is visible
      expect(find.text('Page 0'), findsNothing);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);

      await tester.tap(find.text('Page 1'));
      await tester.pumpWidget(tree);

      // Check that the second custom page is visible
      expect(find.text('TEST 1'), findsOneWidget);
      // Check that the first page is no longer visible
      expect(find.text('TEST 0'), findsNothing);
      // Check that the last page is still not visible
      expect(find.text('TEST 2'), findsNothing);
      // Check that the correct label for the next page is visible
      expect(find.text('Page 0'), findsNothing);
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), findsOneWidget);

      await tester.tap(find.text('Page 2'));
      await tester.pumpWidget(tree);

      // Check that the last custom page is visible
      expect(find.text('TEST 2'), findsOneWidget);
      // Check that the first page is still not visible
      expect(find.text('TEST 0'), findsNothing);
      // Check that the middle page is no longer visible
      expect(find.text('TEST 1'), findsNothing);
      // Check that the correct label for the next page is visible
      expect(find.text('Page 0'), findsOneWidget);
      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), findsNothing);

      await tester.tap(find.text('Page 0'));
      await tester.pumpWidget(tree);

      // Check that we've wrapped around and the first custom page is visible
      expect(find.text('TEST 0'), findsOneWidget);
      // Check that the middle page is still not visible
      expect(find.text('TEST 1'), findsNothing);
      // Check that the last page is no longer visible
      expect(find.text('TEST 2'), findsNothing);
      // Check that the correct label for the next page is visible
      expect(find.text('Page 0'), findsNothing);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);
    },
  );
}
