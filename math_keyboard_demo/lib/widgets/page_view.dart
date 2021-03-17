import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: PageView(
        controller: _controller,
        allowImplicitScrolling: true,
        children: const [
          _PrimaryPage(),
          _PrimaryPage(),
        ],
      ),
    );
  }
}

class _PrimaryPage extends StatelessWidget {
  const _PrimaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('blablabla'),
          SizedBox(
            width: 420,
            child: MathField(
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
