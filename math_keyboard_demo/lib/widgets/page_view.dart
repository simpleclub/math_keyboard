import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';

/// Page view for presenting the features that math_keyboard has to offer.
class DemoPageView extends StatefulWidget {
  /// Creates a [DemoPageView] widget.
  const DemoPageView({Key? key}) : super(key: key);

  @override
  _DemoPageViewState createState() => _DemoPageViewState();
}

class _DemoPageViewState extends State<DemoPageView> {
  late final _controller = PageController();

  int get _page {
    if (!_controller.hasClients) {
      return _controller.initialPage;
    }
    return _controller.page?.round() ?? _controller.initialPage;
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late int previousIndex = _page;

  void _handleScroll() {
    if (previousIndex == _page) return;

    // Unfocus all keyboards when navigating between the pages.
    // Otherwise, the behavior is really weird becauase page views always
    // keep the pages to the left and right alive.
    FocusScope.of(context).unfocus();

    setState(() {
      previousIndex = _page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _Page(child: _PrimaryPage()),
      const _Page(child: _InputDecorationPage()),
      const _Page(child: _ControllerPage()),
      _Page(
        child: _AutofocusPage(
          autofocus: _page == 3,
        ),
      ),
      const _Page(child: _FocusTreePage()),
      const _Page(child: _DecimalSeparatorPage()),
      const _Page(child: _MathExpressionsPage()),
      const _Page(child: _FormFieldPage()),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 5e2,
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                allowImplicitScrolling: true,
                children: pages,
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 8,
                child: MouseRegion(
                  child: GestureDetector(
                    onTap: () {
                      _controller.animateToPage(
                        (_page - 1) % pages.length,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.ease,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const Icon(Icons.chevron_left_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      _controller.animateToPage(
                        (_page + 1) % pages.length,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.ease,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const Icon(Icons.chevron_right_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  _PageIndicator(
                    selected: i == _page,
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.ease,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 56,
      ),
      child: child,
    );
  }
}

/// Widget displaying a dot indicating a page.
///
/// If selected, the dot will be bigger.
class _PageIndicator extends StatelessWidget {
  /// Constructs a [_PageIndicator] widget.
  const _PageIndicator({
    Key? key,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = Size.fromRadius(selected ? 6.5 : 5);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: SizedBox.fromSize(
            size: const Size.fromRadius(6.5),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 214),
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: selected ? 1 : 1 / 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPage extends StatefulWidget {
  const _PrimaryPage({Key? key}) : super(key: key);

  @override
  _PrimaryPageState createState() => _PrimaryPageState();
}

class _PrimaryPageState extends State<_PrimaryPage> {
  late final _expressionController = MathFieldEditingController()
    ..updateValue(
        ShuntingYardParser().parse('4.2 - (cos(x)/(x^3 - sin(x))) + e^(4^2)'));
  late final _numberController = MathFieldEditingController()
    ..updateValue(ShuntingYardParser().parse('42'));

  @override
  void dispose() {
    _expressionController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'Try it now!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'You can tap on the math fields and enter math '
              'expressions using the on-screen keyboard on mobile and/or using '
              'your physical keyboard on desktop 🚀',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: MathField(
            controller: _expressionController,
            decoration: InputDecoration(
              labelText: 'Expression math field',
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
          ),
          child: SizedBox(
            width: 420,
            child: MathField(
              controller: _numberController,
              keyboardType: MathKeyboardType.numberOnly,
              decoration: InputDecoration(
                labelText: 'Number-only math field',
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputDecorationPage extends StatelessWidget {
  const _InputDecorationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'Completely customizable with InputDecoration!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'Math fields are configurable using InputDecoration from the '
              'framework, which means that you can use everything with it '
              'you are used to from TextField e.g. 🔥',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'This is a text field',
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
          ),
          child: SizedBox(
            width: 420,
            child: MathField(
              decoration: InputDecoration(
                hintText: 'And this is a math field',
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: SizedBox(
            width: 6e2,
            child: Row(
              children: [
                Expanded(
                  child: MathField(
                    variables: ['a', 'b', 'd', 'g', 'h_2', 'x', 'y', 'z'],
                    decoration: InputDecoration(
                      helperText: 'Here you can use many variables :)',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: MathField(
                    keyboardType: MathKeyboardType.numberOnly,
                    decoration: InputDecoration(
                      helperText: 'This math field has some icons.',
                      prefixIcon: const Icon(Icons.keyboard_outlined),
                      suffixIcon: const Icon(Icons.format_shapes_sharp),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControllerPage extends StatefulWidget {
  const _ControllerPage({Key? key}) : super(key: key);

  @override
  _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<_ControllerPage> {
  late final _clipboardController = MathFieldEditingController()
    ..updateValue(ShuntingYardParser().parse('log(2, x) - log(5, 2) / 24'));
  late final _clearAllController = MathFieldEditingController();
  late final _magicController = MathFieldEditingController()
    ..updateValue(ShuntingYardParser().parse('42'));

  @override
  void dispose() {
    _clipboardController.dispose();
    _clearAllController.dispose();
    _magicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'Fully controllable using custom controllers!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'You can always provide your own MathFieldEditingController, which'
              'you can use to perform custom actions like clearing the input'
              'field and more ✨',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 3e2,
              child: MathField(
                controller: _clipboardController,
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
              ),
              child: Tooltip(
                message: 'If the on-screen keyboard is opened, the snack bar '
                    'will appear above the keyboard (view insets feature).',
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                      text: _clipboardController.currentEditingValue(),
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('Copied TeX string to clipboard :)')],
                      ),
                    ));
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text('Copy to clipboard'),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 3e2,
                child: MathField(
                  keyboardType: MathKeyboardType.numberOnly,
                  controller: _clearAllController,
                  decoration: InputDecoration(
                    helperText: 'Clear all field',
                    suffix: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _clearAllController.clear,
                        child: const Icon(
                          Icons.highlight_remove_rounded,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                ),
                child: Tooltip(
                  message:
                      'Works from anywhere - thanks to the controller pattern.',
                  child: OutlinedButton(
                    onPressed: _clearAllController.clear,
                    child: Text('Clear all'),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 3e2,
                child: MathField(
                  keyboardType: MathKeyboardType.numberOnly,
                  controller: _magicController,
                  decoration: InputDecoration(
                    labelText: 'Magic field',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                ),
                child: OutlinedButton(
                  onPressed: () {
                    _magicController.addLeaf('+');
                    _magicController.addLeaf('4');
                    _magicController.addLeaf('2');
                  },
                  child: Text('Add 42'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutofocusPage extends StatelessWidget {
  const _AutofocusPage({
    Key? key,
    required this.autofocus,
  }) : super(key: key);

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'With autofocus support!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'The math field on this page will automatically receive focus '
              'when you navigate to this page 👌',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: MathField(
            autofocus: autofocus,
            decoration: InputDecoration(
              hintText: 'Autofocus math field',
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _FocusTreePage extends StatefulWidget {
  const _FocusTreePage({Key? key}) : super(key: key);

  @override
  _FocusTreePageState createState() => _FocusTreePageState();
}

class _FocusTreePageState extends State<_FocusTreePage> {
  final _focusNodeOne = FocusNode(debugLabel: 'one');
  final _focusNodeTwo = FocusNode(debugLabel: 'two');
  final _focusNodeThree = FocusNode(debugLabel: 'three');
  final _focusNodeFour = FocusNode(debugLabel: 'four');

  @override
  void dispose() {
    _focusNodeOne.dispose();
    _focusNodeTwo.dispose();
    _focusNodeThree.dispose();
    _focusNodeFour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'And focus tree integration!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              "Math fields integrate completely with Flutter's tree 💪\n"
              'On desktop, you can try using *tab* on this page after clicking'
              'on a math field :)',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 420,
              child: FocusScope(
                child: Column(
                  children: [
                    MathField(
                      focusNode: _focusNodeOne,
                      variables: ['o', 'n', 'e'],
                      decoration: InputDecoration(
                        labelText: 'One',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                      ),
                      child: MathField(
                        focusNode: _focusNodeTwo,
                        variables: ['t', 'w', 'o'],
                        decoration: InputDecoration(
                          labelText: 'Two',
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                      ),
                      child: MathField(
                        focusNode: _focusNodeThree,
                        variables: ['t', 'h', 'r', 'e'],
                        decoration: InputDecoration(
                          labelText: 'Three',
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                      ),
                      child: MathField(
                        focusNode: _focusNodeFour,
                        variables: ['f', 'o', 'u', 'r'],
                        decoration: InputDecoration(
                          labelText: 'Four',
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: FloatingActionButton(
                onPressed: () {
                  if (_focusNodeOne.hasFocus) {
                    _focusNodeTwo.requestFocus();
                    return;
                  }
                  if (_focusNodeTwo.hasFocus) {
                    _focusNodeThree.requestFocus();
                    return;
                  }
                  if (_focusNodeThree.hasFocus) {
                    _focusNodeFour.requestFocus();
                    return;
                  }
                  if (_focusNodeFour.hasFocus) {
                    _focusNodeFour.unfocus();
                    return;
                  }

                  _focusNodeOne.requestFocus();
                },
                tooltip: 'Rotate focus',
                child: const Icon(Icons.rotate_90_degrees_ccw_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DecimalSeparatorPage extends StatefulWidget {
  const _DecimalSeparatorPage({Key? key}) : super(key: key);

  @override
  _DecimalSeparatorPageState createState() => _DecimalSeparatorPageState();
}

class _DecimalSeparatorPageState extends State<_DecimalSeparatorPage> {
  late final _controller = MathFieldEditingController()
    ..updateValue(ShuntingYardParser().parse('4.2'));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'Adaptive decimal separators!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'The decimal separator on the math keyboard and the ones '
              'displayed in the math field change based on the current '
              'locale!',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: Localizations.override(
            context: context,
            locale: Locale('en', 'US'),
            child: MathField(
              controller: _controller,
              keyboardType: MathKeyboardType.numberOnly,
              decoration: InputDecoration(
                labelText: 'English locale',
                filled: true,
                border: OutlineInputBorder(),
                suffixText: '🇺🇸',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
          ),
          child: SizedBox(
            width: 420,
            child: Localizations.override(
              context: context,
              locale: Locale('de', 'DE'),
              child: MathField(
                controller: _controller,
                keyboardType: MathKeyboardType.numberOnly,
                decoration: InputDecoration(
                  labelText: 'German locale',
                  filled: true,
                  border: OutlineInputBorder(),
                  suffixText: '🇩🇪',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MathExpressionsPage extends StatefulWidget {
  const _MathExpressionsPage({Key? key}) : super(key: key);

  @override
  _MathExpressionsPageState createState() => _MathExpressionsPageState();
}

class _MathExpressionsPageState extends State<_MathExpressionsPage> {
  String? _tex;
  late Expression _expression = ShuntingYardParser().parse('(x^2)/2 + 1');
  double _value = 4;
  double? _result;

  late final _expressionController = MathFieldEditingController()
    ..updateValue(_expression);
  late final _valueController = MathFieldEditingController()
    ..updateValue(ShuntingYardParser().parse('$_value'));

  @override
  void initState() {
    _calculateResult();
    super.initState();
  }

  @override
  void dispose() {
    _expressionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _calculateResult() {
    try {
      setState(() {
        _result = _expression.evaluate(EvaluationType.REAL,
            ContextModel()..bindVariableName('x', Number(_value)));
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Text(
            'Math expression support!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox(
            width: 5e2,
            child: Text(
              'The math_keyboard package is built to work with math '
              'expressions while it displays everything as TeX.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: Localizations.override(
            context: context,
            locale: Locale('en', 'US'),
            child: MathField(
              controller: _expressionController,
              onChanged: (tex) {
                try {
                  _expression = TeXParser(tex).parse();
                  _calculateResult();
                } catch (_) {}

                setState(() {
                  _tex = tex;
                });
              },
              variables: ['x'],
              decoration: InputDecoration(
                labelText: 'Expression field',
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
            left: 32,
            right: 32,
          ),
          child: Text(
            'TeX: ${_tex ?? 'waiting for input'}',
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 32,
            right: 32,
          ),
          child: Text(
            'Math expression: $_expression',
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 32,
            left: 32,
            right: 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 125,
                child: MathField(
                  controller: _valueController,
                  keyboardType: MathKeyboardType.numberOnly,
                  onChanged: (value) {
                    try {
                      _value = TeXParser(value)
                          .parse()
                          .evaluate(EvaluationType.REAL, ContextModel());
                      _calculateResult();
                    } catch (_) {}
                  },
                  decoration: InputDecoration(
                    labelText: 'Value for x',
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.arrow_right_alt_outlined),
              ),
              Text(
                  'Result: ${_result?.toString() ?? 'waiting for valid input'}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormFieldPage extends StatelessWidget {
  const _FormFieldPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (context) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Text(
                  'Last but not least: form fields!',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: 5e2,
                  child: Text(
                    'The math_keyboard package has built-in support for Flutter '
                    'forms and offers a MathFormField widget 🎉',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                width: 420,
                child: MathFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty || value == r'\Box') {
                      return 'Missing expression (:';
                    }

                    try {
                      TeXParser(value)
                          .parse()
                          .evaluate(EvaluationType.REAL, ContextModel());
                      return null;
                    } catch (_) {
                      return 'Invalid expression (:';
                    }
                  },
                  variables: [],
                  decoration: InputDecoration(
                    hintText: 'Enter a valid expression',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    final result = Form.of(context).validate();

                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text('Form is valid :)')],
                        ),
                      ));
                    }
                  },
                  child: Text('Submit form'),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
