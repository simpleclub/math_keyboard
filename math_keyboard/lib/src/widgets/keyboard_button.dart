import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:large_content_viewer/large_content_viewer.dart';
import 'package:math_keyboard/src/widgets/math_keyboard_theme.dart';

/// Widget for keyboard buttons of the math keyboard.
///
/// A keyboard button resolves its background color from the [keyStyle] for the
/// current interaction state (idle, hovered, pressed), draws a focus ring when
/// focused, and can be activated with a tap as well as with the Enter or Space
/// key for keyboard and switch-access users.
class KeyboardButton extends StatefulWidget {
  /// Constructs a [KeyboardButton] widget.
  const KeyboardButton({
    Key? key,
    this.onTap,
    this.onHold,
    required this.keyStyle,
    required this.borderRadius,
    required this.padding,
    required this.focusColor,
    required this.focusWidth,
    this.semanticsLabel,
    this.semanticsValue,
    this.autofocus = false,
    this.onFocusChange,
    this.largeContent,
    this.largeContentThreshold = 1.6,
    required this.child,
  }) : super(key: key);

  /// Called when the keyboard button is tapped or activated via the keyboard.
  final VoidCallback? onTap;

  /// Called periodically when the keyboard button is held down.
  final VoidCallback? onHold;

  /// The background colors of the button for its interaction states.
  final MathKeyboardKeyStyle keyStyle;

  /// The corner radius of the button.
  final BorderRadius borderRadius;

  /// The padding around the [child].
  final EdgeInsets padding;

  /// The color of the focus ring drawn when the button is focused.
  final Color focusColor;

  /// The width of the focus ring drawn when the button is focused.
  final double focusWidth;

  /// The semantics label describing the button's action.
  final String? semanticsLabel;

  /// The semantics value describing the button's current state.
  ///
  /// For navigation keys this carries the math field's cursor context, so the
  /// screen reader speaks the new position when the button is activated.
  final String? semanticsValue;

  /// Whether the button should request focus when it is first shown.
  final bool autofocus;

  /// Called when the button gains or loses focus highlight.
  final ValueChanged<bool>? onFocusChange;

  /// The enlarged label shown in the large-content-viewer popup on long-press.
  ///
  /// When non-null, the button is wrapped in a [LargeContentViewer] so that,
  /// at large system text sizes, a long-press magnifies this content instead
  /// of the key having to grow. `null` disables the viewer for this key (used
  /// for icon and hold-to-repeat keys).
  final Widget? largeContent;

  /// The ambient text scale at or above which the [largeContent] magnifier
  /// activates on long-press. Ignored when [largeContent] is `null`.
  final double largeContentThreshold;

  /// The child widget that the keyboard button interaction is wrapped about.
  ///
  /// It is scaled down to fit the button so that wide typeset labels never
  /// overflow their cell.
  final Widget child;

  @override
  _KeyboardButtonState createState() => _KeyboardButtonState();
}

class _KeyboardButtonState extends State<KeyboardButton> {
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  void _activate() {
    widget.onTap?.call();
  }

  void _handleHold() {
    setState(() => _pressed = true);
    widget.onHold?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Focus keeps the idle background and only adds the ring; hover/pressed are
    // the states that change the surface color.
    final backgroundColor = widget.keyStyle.resolve(
      hovered: _hovered,
      pressed: _pressed,
    );

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: widget.borderRadius,
        border: _focused
            ? Border.fromBorderSide(
                BorderSide(
                  color: widget.focusColor,
                  width: widget.focusWidth,
                  // Draw the ring around the key so it does not eat into the
                  // label or shift the key's content.
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: widget.padding,
        child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
      ),
    );

    result = RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _AlwaysWinningGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              _AlwaysWinningGestureRecognizer
            >(() => _AlwaysWinningGestureRecognizer(), (
              _AlwaysWinningGestureRecognizer instance,
            ) {
              instance
                ..onTap = widget.onTap
                ..onTapDown = (_) {
                  setState(() => _pressed = true);
                }
                ..onTapUp = (_) {
                  setState(() => _pressed = false);
                }
                ..onTapCancel = () {
                  setState(() => _pressed = false);
                };
            }),
      },
      child: result,
    );

    if (widget.onHold != null) {
      result = HoldDetector(
        onHold: _handleHold,
        onCancel: () => setState(() => _pressed = false),
        holdTimeout: const Duration(milliseconds: 100),
        child: result,
      );
    }

    // Drive hover directly from pointer enter/exit. FocusableActionDetector's
    // onShowHoverHighlight is gated by FocusManager.highlightMode and does not
    // fire in touch highlight mode (e.g. on web), so the hover state would
    // otherwise never show.
    result = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: result,
    );

    final Widget button = Semantics(
      button: true,
      label: widget.semanticsLabel,
      value: widget.semanticsValue,
      onTap: widget.onTap,
      // Declare the focus state explicitly. The subtree is excluded below, so
      // the inner Focus node's focusable/focused flags don't reach the tree;
      // surface them here from the tracked [_focused] state instead (which
      // reflects real focus, including under touch / switch access).
      focusable: true,
      focused: _focused,
      // Collapse the key to a single node so the screen reader announces
      // "<label>, button" once, instead of also reading the inner label widget.
      excludeSemantics: true,
      child: FocusableActionDetector(
        autofocus: widget.autofocus,
        mouseCursor: SystemMouseCursors.click,
        // Use real focus, not the highlight-gated callback: `onShowFocusHighlight`
        // never fires in touch highlight mode (mobile, Android Switch Access),
        // which would leave the focus ring undrawn and the variables row's
        // auto-scroll (forwarded via `onFocusChange`) dead under switch access.
        onFocusChange: (value) {
          setState(() => _focused = value);
          widget.onFocusChange?.call(value);
        },
        shortcuts: _activateShortcuts,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: result,
      ),
    );

    if (widget.largeContent == null) return button;
    return LargeContentViewer(
      // Center the magnified label within the viewer overlay.
      customOverlayChild: Center(child: widget.largeContent),
      enabledFromTextScaleFactor: widget.largeContentThreshold,
      child: button,
    );
  }
}

/// The keyboard shortcuts that activate a focused [KeyboardButton].
const _activateShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
};

/// A gesture recognizer that wins in every arena.
///
/// This prevents buttons with sqrt's from not responding.
class _AlwaysWinningGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
