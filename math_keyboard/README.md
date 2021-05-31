# [![math_keyboard logo][logo]][demo]

[![math keyboard GitHub repo][repo shield]][repo]
[![math_keyboard Flutter web demo][demo shield]][demo]
[![math_keyboard on Pub][pub shield]][pub]

`math_keyboard` is a Flutter package that allows editing math expressions using a typeset input
field (so-called "math field") and a custom-made fully integrated math keyboard in _Flutter only_ -
no plugins, no web views.

## Features

[![](https://i.imgur.com/FYl1TqF.png)][demo]

* Editing math expressions using a custom on-screen software keyboard
* Editing via physical keyboard input (with shortcuts for functions and constants)
* Support for both number and expression mode
* Advanced operators and trigonometric functions (e.g. `sqrt`, `ln`, `sin`, etc.)
* View insets support (on-screen keyboard overlay pushes up e.g. the `body` in `Scaffold`)
* Full focus tree integration: works with regular text fields, manual `FocusNode`s, tabbing, etc.
* Autofocus support
* Form field support
* Decimal separator based on locale
* Converting TeX from and to math expressions

You can view all features **in action** in the [demo app][demo].

## Usage

To use this plugin, follow the [installing guide].

### Implementation

The most basic way of integrating the math keyboard is by just adding a [`MathField`][MathField]
somewhere in your app. This works exactly like Flutter `TextField`s do - even with the same
[`InputDecoration`][InputDecoration] decoration functionality!

```dart
@override
Widget build(BuildContext context) {
  return MathField(
    // No parameters are required.
    keyboardType: MathKeyboardType.expression, // Specify the keyboard type (expression or number only).
    variables: const ['x', 'y', 'z'], // Specify the variables the user can use (only in expression mode).
    decoration: const InputDecoration(), // Decorate the input field using the familiar InputDecoration.
    onChanged: (String value) {}, // Respond to changes in the input field.
    onSubmitted: (String value) {}, // Respond to the user submitting their input.
    autofocus: true, // Enable or disable autofocus of the input field.
  );
}
```

Now, tapping inside of the math field (or focusing it via the focus tree) will automatically open
up the math keyboard and start accepting physical keyboard input on desktop.

*Note* that physical keyboard input on mobile causes weird behavior due to a [Flutter issue](https://github.com/flutter/flutter/issues/44681).

### View insets

A very useful feature of the math keyboard is the fact that it tries to mirror the regular software
keyboard *as closely as possible*. Part of that is reporting its size to the `MediaQuery` in the
form of [view insets]. This will seamlessly integrate with widgets like `Scaffold` and the existing
view insets reporting of software keyboards.

All you have to do to use this feature is making sure that your `Scaffold` (that your `MathField`s
live in) are wrapped in [`MathKeyboardViewInsets`][MathKeyboardViewInsets]:

```dart
@override
Widget build(BuildContext context) {
  return MathKeyboardViewInsets(
    child: Scaffold(
      // ...
    ),
  );
}
```

Please [see the documentation][MathKeyboardViewInsets] for more advanced use cases - this part of
the docs is quite detailed :)

Furthermore, the package provides some convenience functions for detecting whether a keyboard
is showing:

* [`MathKeyboardViewInsetsQuery.mathKeyboardShowingIn(context)`][mathKeyboardShowingIn],
  which reports whether there is a math keyboard open in the current `context`.
* [`MathKeyboardViewInsetsQuery.keyboardShowingIn(context)`][keyboardShowingIn],
  which reports whether there is **any** keyboard open in the current `context`. Note that this
  function actually also provides advanced functionality for regular software keyboards :)

### Form support

In order to use a `MathField` in a Flutter [`Form`][Form], you can simply use a
[`MathFormField`][MathFormField] in place of a regular `MathField`. This mirrors the regular field
with extended functionality and behaves exactly like [`TextFormField`][TextFormField] from the
framework. See the latter for advanced documentation.

```dart
@override
Widget build(BuildContext context) {
  return MathFormField(
    // ...
  );
}
```

### Custom controller

You can always specify a custom [`MathFieldEditingController`][MathFieldEditingController]. This
allows you to clear all input for example. Make sure to dispose the controller.

```dart
class FooState extends State<FooStatefulWidget> {
  late final _controller = MathFieldEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapClear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MathField(
      controller: _controller,
      decoration: InputDecoration(
        suffix: MouseRegion(
          cursor: MaterialStateMouseCursor.clickable,
          child: GestureDetector(
            onTap: _onTapClear,
            child: const Icon(
              Icons.highlight_remove_rounded,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
```

### Custom focus node

You can always specify your own [`FocusNode`][FocusNode] if you wish to manage focus yourself. This
works like any other focus-based widget (like `TextField`). Note that `autofocus` still works when
supplying a custom focus node.

```dart
class FooState extends State<FooStatefulWidget> {
  late final _focusNode = FocusNode(debugLabel: 'Foo');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MathField(
      focusNode: _focusNode,
    );
  }
}
```

### Decimal separators

Note that not all countries use a dot `.` as decimal separator (see [reference][decimal separators]).
If the locale obtained via [`Localizations.localeOf`][localeOf] uses a comma `,` as decimal
separator, both the separator in the math field as well as the symbol on the keyboard are adjusted.
Otherwise, a dot `.` is used. You can override the locale using the
[`Localizations.override`][Localizations override] widget (wrap your `MathField`s with it).

Note that physical keyboard input always accepts both `.` and `,`.

### Math expressions

To convert the TeX strings returned by the math keyboard into math expressions, you can make use
of the provided [`TeXParser`][TeXParser]:

```dart
final mathExpression = TeXParser(texString).parse();
```

For the opposite operation, i.e. converting a math `Expression` to TeX, you can make use
of the provided [`convertMathExpressionToTeXNode`][convertMathExpressionToTeXNode]:

```dart
final texNode = convertMathExpressionToTeXNode(expression);
```

Note that this returns an internal `TeXNode` format, which you can convert to a TeX string:

```dart
final texString = texNode.buildTexString();
```

[logo]: https://user-images.githubusercontent.com/19204050/120233149-ab27a980-c244-11eb-8a7e-0bc6cd3fd607.png
[repo]: https://github.com/simpleclub/math_keyboard
[repo shield]: https://img.shields.io/github/stars/simpleclub/math_keyboard?style=social
[demo]: https://simpleclub.github.io/math_keyboard
[demo shield]: https://img.shields.io/badge/math_keyboard-demo-FFC107
[pub shield]: https://img.shields.io/pub/v/math_keyboard.svg
[pub]: https://pub.dev/packages/math_keyboard
[installing guide]: https://pub.dev/packages/math_keyboard/install
[InputDecoration]: https://api.flutter.dev/flutter/material/InputDecoration-class.html
[MathField]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathField-class.html
[MathFieldEditingController]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathFieldEditingController-class.html
[MathKeyboardViewInsets]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathKeyboardViewInsets-class.html
[mathKeyboardShowingIn]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathKeyboardViewInsetsQuery/mathKeyboardShowingIn.html
[keyboardShowingIn]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathKeyboardViewInsetsQuery/keyboardShowingIn.html
[view insets]: https://api.flutter.dev/flutter/widgets/MediaQueryData/viewInsets.html
[Form]: https://api.flutter.dev/flutter/widgets/Form-class.html
[TextFormField]: https://api.flutter.dev/flutter/material/TextFormField-class.html
[MathFormField]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/MathFormField-class.html
[FocusNode]: https://api.flutter.dev/flutter/widgets/FocusNode-class.html
[decimal separators]: https://en.wikipedia.org/wiki/Decimal_separator#Countries_using_decimal_comma
[localeOf]: https://api.flutter.dev/flutter/widgets/Localizations/localeOf.html
[Localizations override]: https://api.flutter.dev/flutter/widgets/Localizations/Localizations.override.html
[TeXParser]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/TeXParser-class.html
[convertMathExpressionToTeXNode]: https://pub.dev/documentation/math_keyboard/latest/math_keyboard/convertMathExpressionToTeXNode.html
