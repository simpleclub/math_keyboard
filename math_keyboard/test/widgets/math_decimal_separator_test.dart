import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Tests for the configurable decimal separator: how it is resolved (argument >
/// [MathKeyboardTheme] > locale), that it reaches the key, the preview, the
/// spoken value and the reported TeX, and that the reported TeX parses back.
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

      expect(find.bySemanticsLabel(','), findsOneWidget);
      expect(find.bySemanticsLabel('.'), findsNothing);
      handle.dispose();
    });
  });

  group('MathField decimal separator', () {
    testWidgets(
      'reaches the preview, the reported value and the spoken value',
      (tester) async {
        pinPortrait(tester);
        final controller = MathFieldEditingController();
        addTearDown(controller.dispose);
        final handle = tester.ensureSemantics();
        String? changed;

        await tester.pumpWidget(
          app(
            child: MathField(
              controller: controller,
              decimalSeparator: DecimalSeparator.comma,
              onChanged: (value) => changed = value,
            ),
          ),
        );
        await typeOnePointFive(tester, controller);

        // Grouped so that it typesets without the list spacing of a bare comma.
        expect(changed, '1{,}5');
        // The preview renders the same number the value describes ...
        expect(
          tester
              .widgetList<RichText>(find.byType(RichText))
              .map((widget) => widget.text.toPlainText()),
          ['1', ',', '5'],
        );
        // ... and the screen reader announces it, rather than a literal dot.
        expect(
          tester.getSemantics(find.bySemanticsLabel('Math field')).value,
          '1 , 5',
        );
        handle.dispose();
      },
    );

    testWidgets('round-trips every separator through TeXParser', (
      tester,
    ) async {
      pinPortrait(tester);
      for (final separator in DecimalSeparator.values) {
        final controller = MathFieldEditingController();
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

        expect(
          TeXParser(
            changed!,
          ).parse().evaluate(EvaluationType.REAL, ContextModel()),
          1.5,
          reason: '$separator produced unparseable TeX: $changed',
        );
        controller.dispose();
      }
    });

    testWidgets('reports the canonical form for a dot locale', (tester) async {
      pinPortrait(tester);
      final controller = MathFieldEditingController();
      addTearDown(controller.dispose);
      String? changed;

      await tester.pumpWidget(
        app(
          child: MathField(
            controller: controller,
            onChanged: (value) => changed = value,
          ),
        ),
      );
      await typeOnePointFive(tester, controller);

      // Unchanged from before the separator became configurable.
      expect(changed, '1.5');
    });
  });

  testWidgets('MathFormField reports its initial value in the displayed '
      'separator', (tester) async {
    pinPortrait(tester);
    final controller = MathFieldEditingController();
    addTearDown(controller.dispose);
    controller
      ..addLeaf('1')
      ..addLeaf('.')
      ..addLeaf('5');

    final validated = <String?>[];
    // Every value a Form observer can read, including intermediate ones.
    final observed = <String?>[];
    final fieldKey = GlobalKey<FormFieldState<String>>();
    await tester.pumpWidget(
      app(
        child: MathKeyboardTheme(
          decimalSeparator: DecimalSeparator.comma,
          child: Form(
            onChanged: () => observed.add(fieldKey.currentState?.value),
            child: MathFormField(
              key: fieldKey,
              controller: controller,
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                validated.add(value);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // A validator must not see the canonical form initially and the localized
    // form after the first edit.
    expect(validated.last, '1{,}5');

    // A change driven through the external controller must not report the
    // canonical form either, not even transiently: the field's own controller
    // listener notifies Form.onChanged before the MathField reports, so an
    // observer would otherwise read the wrong format.
    controller.addLeaf('2');
    await tester.pump();
    expect(validated.last, '1{,}52');
    expect(observed, isNot(contains('1.52')));

    // ... and so does a change of the separator itself, which arrives as a
    // widget update rather than a dependency change.
    await tester.pumpWidget(
      app(
        child: MathKeyboardTheme(
          decimalSeparator: DecimalSeparator.comma,
          child: Form(
            child: MathFormField(
              controller: controller,
              decimalSeparator: DecimalSeparator.dot,
              autovalidateMode: AutovalidateMode.always,
              validator: (value) {
                validated.add(value);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(validated.last, '1.52');
  });
}
