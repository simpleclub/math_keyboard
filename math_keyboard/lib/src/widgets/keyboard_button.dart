import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:holding_gesture/holding_gesture.dart';

/// Widget for keyboard buttons of the math keyboard.
///
/// These buttons have a tap response that is defined in the following way:
///
/// * Brighten up the background using white with `1 / 3` opacity.
/// * With an ease in out curve.
/// * For a duration of 50ms in and 200ms out.
/// * And a rounded rectangle shape with a border radius of 8px and padding
///   of 4px.
class KeyboardButton extends StatefulWidget {
  /// Constructs a [KeyboardButton] widget.
  const KeyboardButton({
    Key? key,
    this.onTap,
    this.onHold,
    this.color,
    required this.child,
  }) : super(key: key);

  /// Called when the keyboard button is tapped.
  final VoidCallback? onTap;

  /// Called periodically when the keyboard button is held down.
  final VoidCallback? onHold;

  /// The button base color.
  final Color? color;

  /// The child widget that the keyboard button interaction is wrapped about.
  final Widget child;

  @override
  _KeyboardButtonState createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    duration: const Duration(milliseconds: 50),
    reverseDuration: const Duration(milliseconds: 200),
    vsync: this,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool entered) {
    _animationController.value = entered ? 0.5 : 0;
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp([TapUpDetails? details]) async {
    await _animationController.reverse(from: 1);
  }

  void _handleHold() {
    _animationController.value = 1;
    widget.onHold?.call();
  }

  void _handleTapCancel() {
    _animationController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    Widget result = MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          _AlwaysWinningGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              _AlwaysWinningGestureRecognizer>(
            () => _AlwaysWinningGestureRecognizer(),
            (_AlwaysWinningGestureRecognizer instance) {
              instance
                ..onTap = widget.onTap
                ..onTapUp = _handleTapUp
                ..onTapDown = _handleTapDown
                ..onTapCancel = _handleTapCancel;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: widget.color,
            ),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(
                      Curves.easeInOut.transform(_animationController.value) /
                          3,
                    ),
                  ),
                  child: Center(
                    child: child,
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onHold != null) {
      result = HoldDetector(
        onHold: _handleHold,
        onCancel: _handleTapUp,
        holdTimeout: const Duration(milliseconds: 100),
        child: result,
      );
    }

    return MouseRegion(
      cursor: MaterialStateMouseCursor.clickable,
      child: result,
    );
  }
}

/// A gesture recognizer that wins in every arena.
///
/// This prevents buttons with sqrt's from not responding.
class _AlwaysWinningGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
