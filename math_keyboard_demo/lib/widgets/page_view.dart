import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:math_expressions/math_expressions.dart';

/// Page view for presenting the features that math_keyboard has to offer.
class DemoPageView extends StatefulWidget {
  /// Creates a [DemoPageView] widget.
  const DemoPageView({Key? key}) : super(key: key);

  @override
  _DemoPageViewState createState() => _DemoPageViewState();
}

class _DemoPageViewState extends State<DemoPageView> {
  late final _controller = PageController();

  int get _page => _controller.page?.round() ?? _controller.initialPage;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _Page(child: _PrimaryPage()),
      _Page(child: _NumberModePage()),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 325,
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
                left: 0,
                child: MouseRegion(
                  cursor: MaterialStateMouseCursor.clickable,
                  child: GestureDetector(
                    onTap: () {
                      _controller.animateToPage(
                        (_page - 1) % pages.length,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.ease,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.chevron_left_outlined),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: MouseRegion(
                  cursor: MaterialStateMouseCursor.clickable,
                  child: GestureDetector(
                    onTap: () {
                      _controller.animateToPage(
                        (_page + 1) % pages.length,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.ease,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
        horizontal: 40,
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
      cursor: MaterialStateMouseCursor.clickable,
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
                      .withOpacity(selected ? 1 : 1 / 2),
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
    ..updateValue(Parser().parse('sqrt(4.2) - (cos(x)/(x^3 - sin(x))) + e^(4^2)'));
  late final _numberController = MathFieldEditingController()
    ..updateValue(Parser().parse('42'));

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
          padding: const EdgeInsets.all(16),
          child: Text(
            'Try it now!\nYou can tap on the math field and enter math '
            'expressions using the on-screen keyboard on mobile and using '
            'your physical keyboard on desktop - or a combination of both :)',
            textAlign: TextAlign.center,
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

class _NumberModePage extends StatelessWidget {
  const _NumberModePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('And look! We have number-only mode this math field:'),
          ),
          SizedBox(
            width: 420,
            child: MathField(
              decoration: InputDecoration(
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('And expression mode in this one:'),
          ),
          SizedBox(
            width: 420,
            child: MathField(
              keyboardType: MathKeyboardType.numberOnly,
              decoration: InputDecoration(
                filled: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
