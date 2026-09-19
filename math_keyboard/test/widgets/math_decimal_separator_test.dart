import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Tests for the configurable decimal separator: how it is resolved (argument >
/// [MathKeyboardTheme] > locale), that it reaches the key, the preview and the
/// spoken value, and that the reported TeX stays canonical.
void main() {
  /// Pins a portrait window so the paged (non-landscape) layout is exercised.
  void pinPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app({
    required Widget child,
    Locale locale = const Locale('en', 'US'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('de'),
      ],
      home: Scaffold(body: child),
    );
  }

  /// The label of the decimal key, i.e. the only key showing a separator.
  String decimalKeyLabel(WidgetTester tester) {
    final symbols = {
      for (final separator in DecimalSeparator.values) separator.symbol,
    };
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .firstWhere(symbols.contains, orElse: () => 'NOT FOUND');
  }

  /// Types `1.5` into [controller] and settles.
  Future<void> typeOnePointFive(
    WidgetTester tester,
    MathFieldEditingController controller,
  ) async {
    controller
      ..addLeaf('1')
      ..addLeaf('.')
      ..addLeaf('5');
    await tester.pump();
  }

  group('DecimalSeparator.of', () {
    /// Resolves the separator for [locale]. Uses a delegate that accepts any
    /// locale, so the framework does not warn about unsupported localizations.
    Future<DecimalSeparator> separatorFor(
      WidgetTester tester,
      Locale locale,
    ) async {
      late DecimalSeparator separator;
      await tester.pumpWidget(
        Localizations(
          locale: locale,
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              separator = DecimalSeparator.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return separator;
    }

    testWidgets('resolves the locale separator', (tester) async {
      expect(
        await separatorFor(tester, const Locale('de', 'DE')),
        DecimalSeparator.comma,
      );
      // Without a country code, intl falls back to the language.
      expect(
        await separatorFor(tester, const Locale('de')),
        DecimalSeparator.comma,
      );
    });

    testWidgets('falls back to a dot for a locale using neither marker', (
      tester,
    ) async {
      // ar_EG, fa and ps use the Arabic decimal separator, which the package
      // deliberately does not display.
      expect(
        await separatorFor(tester, const Locale('ar', 'EG')),
        DecimalSeparator.dot,
      );
    });

    testWidgets('falls back to a dot for a locale intl does not know', (
      tester,
    ) async {
      // Intl throws for an unknown locale unless the lookup opts out, which
      // would make this fallback unreachable.
      expect(
        await separatorFor(tester, const Locale('zz', 'ZZ')),
        DecimalSeparator.dot,
      );
    });
  });

  group('DecimalSeparator.fromLocale', () {
    test('maps a locale without a context', () {
      expect(
        DecimalSeparator.fromLocale(const Locale('de', 'DE')),
        DecimalSeparator.comma,
      );
      expect(
        DecimalSeparator.fromLocale(const Locale('en', 'US')),
        DecimalSeparator.dot,
      );
      expect(
        DecimalSeparator.fromLocale(const Locale('zz', 'ZZ')),
        DecimalSeparator.dot,
      );
    });
  });

  group('MathKeyboard decimal separator', () {
    testWidgets('falls back to the locale', (tester) async {
      pinPortrait(tester);
      await tester.pumpWidget(
        app(
          locale: const Locale('de', 'DE'),
          child: MathKeyboard(controller: MathFieldEditingController()),
        ),
      );

      expect(decimalKeyLabel(tester), ',');
    });

    testWidgets('prefers the theme over the locale, and the argument over '
        'the theme', (tester) async {
      pinPortrait(tester);
      await tester.pumpWidget(
        app(
          locale: const Locale('de', 'DE'),
          child: MathKeyboardTheme(
            decimalSeparator: DecimalSeparator.comma,
            child: MathKeyboard(controller: MathFieldEditingController()),
          ),
        ),
      );
      expect(decimalKeyLabel(tester), ',');

      await tester.pumpWidget(
        app(
          locale: const Locale('de', 'DE'),
          child: MathKeyboardTheme(
            decimalSeparator: DecimalSeparator.comma,
            child: MathKeyboard(
              controller: MathFieldEditingController(),
              decimalSeparator: DecimalSeparator.dot,
            ),
          ),
        ),
      );
      expect(decimalKeyLabel(tester), '.');
    });

    testWidgets('is spoken by the screen reader', (tester) async {
      pinPortrait(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          child: MathKeyboardTheme(
            decimalSeparator: DecimalSeparator.comma,
            child: MathKeyboard(controller: MathFieldEditingController()),
          ),
        ),
      );

      // The glyph itself, so that the screen reader names it in the user's own
      // language rather than in whatever language a label would hard-code.
      expect(find.bySemanticsLabel(','), findsOneWidget);
      expect(find.bySemanticsLabel('.'), findsNothing);
      handle.dispose();
    });
  });

  group('MathField decimal separator', () {
    testWidgets('reaches the preview and the spoken value', (tester) async {
      pinPortrait(tester);
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        app(
          child: MathField(
            controller: controller,
            decimalSeparator: DecimalSeparator.comma,
          ),
        ),
      );
      await typeOnePointFive(tester, controller);

      // The preview renders the number with the configured separator ...
      expect(
        tester
            .widgetList<RichText>(find.byType(RichText))
            .map((widget) => widget.text.toPlainText()),
        ['1', ',', '5'],
      );
      // ... and the screen reader announces it as one number, rather than
      // as a literal dot or as space separated digits.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Math field')).value,
        '1,5',
      );
      handle.dispose();
    });

    testWidgets('does not reach the reported value', (tester) async {
      pinPortrait(tester);
      for (final separator in DecimalSeparator.values) {
        final controller = MathFieldEditingController();
        addTearDown(controller.dispose);
        String? changed;
        await tester.pumpWidget(
          app(
            child: MathField(
              key: ValueKey(separator),
              controller: controller,
              decimalSeparator: separator,
              onChanged: (value) => changed = value,
            ),
          ),
        );
        await typeOnePointFive(tester, controller);

        // The reported TeX stays canonical so that it can be stored and parsed
        // independently of the locale.
        expect(changed, '1.5', reason: '$separator changed the reported TeX');
      }
    });
  });

  testWidgets('MathFormField displays the configured separator and keeps its '
      'value canonical', (tester) async {
    pinPortrait(tester);
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);
    controller
      ..addLeaf('1')
      ..addLeaf('.')
      ..addLeaf('5');

    final validated = <String?>[];
    await tester.pumpWidget(
      app(
        child: Form(
          child: MathFormField(
            controller: controller,
            decimalSeparator: DecimalSeparator.comma,
            autovalidateMode: AutovalidateMode.always,
            validator: (value) {
              validated.add(value);
              return null;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widgetList<RichText>(find.byType(RichText))
          .map((widget) => widget.text.toPlainText()),
      ['1', ',', '5'],
    );
    expect(validated.last, '1.5');
  });

  group('spoken numbers', () {
    /// The spoken value of the whole expression in [controller].
    String spoken(
      MathFieldEditingController controller,
      DecimalSeparator separator,
    ) => controller.readableExpression(
      MathKeyboardSemantics.fallback,
      decimalSeparator: separator,
    );

    /// Types the [tokens] as leaves into a fresh controller.
    MathFieldEditingController typed(List<String> tokens) {
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      for (final token in tokens) {
        controller.addLeaf(token);
      }
      return controller;
    }

    test('reads a decimal as one number, not as separate digits', () {
      // Space separated digits are spelled out one by one and a lone separator
      // is dropped entirely, so "1 , 5" is announced as "one five".
      final controller = typed(['1', '.', '5']);

      expect(spoken(controller, DecimalSeparator.comma), '1,5');
      expect(spoken(controller, DecimalSeparator.dot), '1.5');
    });

    test('joins the digits of a multi digit number', () {
      expect(spoken(typed(['2', '3']), DecimalSeparator.dot), '23');
    });

    test('keeps operators and functions separated from the numbers', () {
      final controller = typed(['1', '.', '5', '+', '2', '3', r'\cdot', '4']);

      expect(spoken(controller, DecimalSeparator.comma), '1,5 plus 23 times 4');
    });

    test('is not broken up by the cursor sitting inside a number', () {
      final controller = typed(['1', '.', '5'])..goBack();

      expect(spoken(controller, DecimalSeparator.comma), '1,5');
    });

    test('speaks the separator as a word next to the cursor', () {
      // The cursor announcement embeds a single token in a sentence, where a
      // bare `.` is dropped as punctuation, so it comes from `tokenMappings`
      // as a word instead.
      final controller = typed(['1', '.', '5'])
        ..goBack()
        ..goBack();

      expect(
        controller.describeCursorContext(MathKeyboardSemantics.fallback),
        'before point',
      );
      expect(
        controller.describeCursorContext(
          MathKeyboardSemantics.fallback.copyWith(
            tokenMappings: {
              ...MathKeyboardSemantics.fallback.tokenMappings,
              '.': 'Komma',
            },
          ),
        ),
        'before Komma',
        reason: 'the separator is localized through the existing seam',
      );
    });
  });
}
