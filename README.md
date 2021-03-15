# [![math_keyboard logo][logo]][demo]

[![math_keyboard on Pub][pub shield]][pub]
[![math_keyboard Flutter web demo][demo shield]][demo]

`math_keyboard` is a Flutter package that allows editing math expressions using a typeset text field
(so-called "math field") and a custom-made fully integrated math keyboard in _Flutter only_ - no
plugins, no web views.

## About math_keyboard

The `math_keyboard` package provides a widget that behaves like a Flutter `TextField` with the same
_full integration_, i.e. **focus tree** support, **input decoration** support, and both an _on-screen
software keyboard_ as well as **physical keyboard input** support. On top of that, the math field
typesetting uses TeX and the package supports converting to math expressions (that e.g. can be used for
calculation).

`math_keyboard` is an open source project with the aim of providing a way to edit math expression
providing the best user experience in terms of input and UI as well as allowing accurate evaluation of
the mathematical expressions entered by the user. This is used by the [simpleclub app][simpleclub],
hence, the association. It is also maintained by [simpleclub][] (see the [`LICENSE`][license] file).

## Usage

See the [package README][package readme] for usage information.

## Contributing

Our mission with open source repositories like `math_keyboard` in particular is creating an ecosystem
of science and education related packages for Flutter, allowing users on all platforms to use the
optimal tools for learning.

This is also why we want to share and collaborate on this software as a way to give back to the
community. Any contributions are more than welcome!

See our [contributing guide][contributing] for more information.

[logo]: https://i.imgur.com/bWCrGG8.png
[simpleclub]: https://github.com/simpleclub
[demo]: https://simpleclub.github.io/math_keyboard
[demo shield]: https://img.shields.io/badge/math_keyboard-demo-FFC107
[pub shield]: https://img.shields.io/pub/v/math_keyboard.svg
[pub]: https://pub.dev/packages/math_keyboard
[example]: https://github.com/simpleclub/math_keyboard/tree/master/math_keyboard/example
[contributing]: https://github.com/simpleclub/math_keyboard/blob/master/CONTRIBUTING.md
[issues]: https://github.com/simpleclub/math_keyboard/issues
[license]: https://github.com/simpleclub/math_keyboard/blob/master/LICENSE
[package readme]: https://github.com/simpleclub/math_keyboard/tree/master/math_keyboard
