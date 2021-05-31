# [![math_keyboard logo][logo]][demo]

[![math_keyboard Flutter web demo][demo shield]][demo]
[![math_keyboard on Pub][pub shield]][pub]

`math_keyboard` is a Flutter package that allows editing math expressions using a typeset input
field (so-called "math field") and a custom-made fully integrated math keyboard in _Flutter only_ -
no plugins, no web views.

## About math_keyboard

The `math_keyboard` package provides a widget that behaves like a Flutter `TextField` with the same
_full integration_, i.e. **focus tree** support, **input decoration** support, and both an
_on-screen software keyboard_ as well as **physical keyboard input** support. On top of that, the
math field typesetting uses TeX and the package supports converting to math expressions (that e.g.
can be used for calculation).

[![](https://i.imgur.com/FYl1TqF.png)][demo]

`math_keyboard` is an open source project with the aim of providing a way to edit math expression
providing the best user experience in terms of input and UI as well as allowing accurate evaluation
of the mathematical expressions entered by the user. This is used by the
[simpleclub app][simpleclub], hence, the association. It is also maintained by [simpleclub]
(see the [`LICENSE`][license] file).

## Features & usage

See the [package README][package readme] for features and usage information.

You can also try the **demo app** or view the package on Pub →
[![math_keyboard Flutter web demo][demo shield]][demo]
[![math_keyboard on Pub][pub shield]][pub]

## Implementation

In the following, some high-level information regarding the implementation of the package is
described. This is useful in case you are curious or intend to contribute.

For information on *implementing `math_keyboard` into your own app*, please see the
[package README][pub].

### Math expressions

Notice how the `math_keyboard` package includes a major feature that allows working with the input
expressions in a mathematical matter, i.e. by converting them into "math expressions" (this is how
we refer to the format in the context of this project).

We achieve this by essentially working with two formats:

* The typeset display format, powered by TeX (see below).
* A data format, i.e. math expressions.

This "data format" depends on the [`math_expressions` package][math_expressions]. Handling the
expressions in this format allows you to e.g. evaluate the expressions.

### TeX typesetting

Both the math field content, i.e. the expressions typed by the user, as well as some symbols on the
keyboard itself are typeset using TeX. For TeX typesetting in Flutter, we created our own proof of
concept renderer in early 2020, called [CaTeX][catex]. This project is on-hold for now and in the
meantime, we collaborated on the [flutter_math] package that aims to achieve something similar.  
Due to lack of maintenance on that repo, we are currently using our forked version,
[flutter_math_fork]. Note that our ultimate goal is fully integrating the `math_keyboard` package
with the `catex` package, which would give us maximum control over the rendering of the typeset math.

## Contributing

Our mission with open source repositories like `math_keyboard` in particular is creating an
ecosystem of science and education related packages for Flutter, allowing users on all platforms to
use the optimal tools for learning.

This is also why we want to share and collaborate on this software as a way to give back to the
community. Any contributions are more than welcome!

See our [contributing guide][contributing] for more information.

### Missing features

You might notice that some features that you would expect from the `math_keyboard` package are
missing or something is not working as expected. In that case, please [file an issue][issues].

In general, we can of course never fully solve every use case, however, especially in this case we
are aware of a few shortcomings. For example the customization options of the keyboard are currently
limited because this has simply not yet been a requirement in our internal usage. In that case,
please consider **contributing** pull requests to this repo in order to allow as many use cases
to be covered as possible :) Please refer to the [contributing guide][contributing] for that.

### Repo structure

The `math_keyboard` repository is divided into multiple packages. These packages are the following:

| Package                                                                                           | Content                     |
| --------------------------------------------------------------------------------------------------| --------------------------- |
| [`math_keyboard`](https://github.com/simpleclub/math_keyboard/tree/main/math_keyboard)            | Main package implementation |
| [`math_keyboard_demo`](https://github.com/simpleclub/math_keyboard/tree/main/math_keyboard_demo)  | Demo app                    |

## Num++ inspiration

During the research phase of this project, we came across the [Num++ app][numpp], which served as
an inspiration for the math expression parsing part of the package.  
The main difference between that app and this package (apart from one being a calculator app and the
other being a generalized usable package) is the fact that Num++ uses a web view and MathQuill for
editing the expression while we built the input field and editing ourselves.

[logo]: https://user-images.githubusercontent.com/19204050/120233118-9cd98d80-c244-11eb-8e7e-05ede431c60f.png
[simpleclub]: https://github.com/simpleclub
[demo]: https://simpleclub.github.io/math_keyboard
[demo shield]: https://img.shields.io/badge/math_keyboard-demo-FFC107
[pub shield]: https://img.shields.io/pub/v/math_keyboard.svg
[pub]: https://pub.dev/packages/math_keyboard
[example]: https://github.com/simpleclub/math_keyboard/tree/main/math_keyboard/example
[contributing]: https://github.com/simpleclub/math_keyboard/blob/main/CONTRIBUTING.md
[issues]: https://github.com/simpleclub/math_keyboard/issues
[license]: https://github.com/simpleclub/math_keyboard/blob/main/LICENSE
[package readme]: https://github.com/simpleclub/math_keyboard/tree/main/math_keyboard
[catex]: https://github.com/simpleclub/CaTeX
[flutter_math]: https://github.com/znjameswu/flutter_math
[flutter_math_fork]: https://github.com/simpleclub-extended/flutter_math_fork
[math_expressions]: https://pub.dev/packages/math_expressions
[numpp]: https://github.com/DylanXie123/Num-Plus-Plus
