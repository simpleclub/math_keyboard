import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/src/foundation/keyboard_button.dart';
import 'package:math_keyboard/src/foundation/math2tex.dart';
import 'package:math_keyboard/src/foundation/node.dart';
import 'package:math_keyboard/src/widgets/decimal_separator.dart';
import 'package:math_keyboard/src/widgets/math_keyboard.dart';
import 'package:math_keyboard/src/widgets/view_insets.dart';

/// Widget that is like a [TextField] for math expressions.
///
/// Instead of launching a software keyboard, it will launch a custom keyboard
/// UI in an [OverlayEntry].
class MathField extends StatefulWidget {
  /// Constructs a [MathField] widget.
  const MathField({
    Key? key,
    this.autofocus = false,
    this.focusNode,
    this.controller,
    this.keyboardType = MathKeyboardType.expression,
    this.variables = const ['x'],
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.onSubmitted,
    this.opensKeyboard = true,
    this.onKeyboardHeightChanged,
  }) : super(key: key);

  final ValueChanged<double>? onKeyboardHeightChanged;

  /// The controller for the math field.
  ///
  /// This can be optionally passed in order to control a math field from the
  /// outside (defaults to `null`).
  /// If no controller is supplied, the math field state creates its own
  /// controller.
  ///
  /// If you pass a controller, you need to make sure that you also take care
  /// of disposing it.
  final MathFieldEditingController? controller;

  /// The keyboard type.
  ///
  /// This only controls the layout of the keyboard that will pop up to fill in
  /// the math field.
  final MathKeyboardType keyboardType;

  /// The additional variables a user can use.
  ///
  /// Note that these are ignored for [MathKeyboardType.numberOnly].
  ///
  /// Defaults to including "x".
  final List<String> variables;

  /// The decoration to show around the math field.
  final InputDecoration decoration;

  /// Function that is called when the expression inside of the math field
  /// changes,
  ///
  /// The passed [value] is the TeX representation of the expression. You can
  /// make use of the provided [TeXParser] to convert it into a math expression.
  final void Function(String value)? onChanged;

  /// Whether this math field should focus itself if nothing else is already
  /// focused.
  ///
  /// If `true`, the keyboard will open as soon as this math field obtains
  /// focus. Otherwise, the keyboard is only shown after the user taps the math
  /// field.
  ///
  /// Defaults to `false`. Cannot be `null`.
  final bool autofocus;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// focusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  final FocusNode? focusNode;

  /// Called when the user indicates that they are done with editing the math
  /// field.
  ///
  /// This happens e.g. when the enter key is pressed.
  ///
  /// Note that the math field is unfocused (the [focusNode] is unfocused)
  /// **before** [onSubmitted] is called.
  ///
  /// Can be `null`.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field should open a keyboard on focus by itself or not.
  ///
  /// Set this to false if you want to provide input via an external source by
  /// using [controller].
  ///
  /// Defaults to `true`.
  final bool opensKeyboard;

  @override
  _MathFieldState createState() => _MathFieldState();
}

class _MathFieldState extends State<MathField> with TickerProviderStateMixin {
  late final _scrollController = ScrollController();
  late final _keyboardSlideController = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );
  late final _cursorBlinkController = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
    // We start the controller at 1/2 so that immediately when the controller
    // is forwarded the cursor appears. The cursor is visible when the value
    // is greater than 1/2.
    value: 1 / 2,
  );
  late var _cursorOpacity = 0.0;

  OverlayEntry? _overlayEntry;
  late var _focusNode = widget.focusNode ??
      FocusNode(
        debugLabel: 'math_keyboard_$hashCode',
        descendantsAreFocusable: false,
      );
  late var _controller = widget.controller ?? MathFieldEditingController();

  List<String> get _variables => [
        r'\pi',
        'e',
        ...widget.variables,
      ];

  bool get _isKeyboardShown =>
      _overlayEntry != null &&
      _keyboardSlideController.status != AnimationStatus.dismissed;

  @override
  void initState() {
    super.initState();

    _keyboardSlideController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      } else if (status == AnimationStatus.completed) {
        _showFieldOnScreen();
      }
    });
    _cursorBlinkController.addListener(_handleBlinkUpdate);
    _controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(MathField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller != null) {
        // We should only detach our listener and not dispose an outside
        // controller if provided.
        _controller.removeListener(_handleControllerUpdate);
      } else {
        _controller.dispose();
      }

      _controller = widget.controller ?? MathFieldEditingController();
      _controller.addListener(_handleControllerUpdate);
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        assert(widget.focusNode != null);
        // Dispose the focus node created by our state instance.
        _focusNode.dispose();
        // Assign the new outside focus node.
        _focusNode = widget.focusNode!;
      } else if (widget.focusNode == null) {
        assert(oldWidget.focusNode != null);
        // Instantiate new local focus node.
        _focusNode = FocusNode(
          debugLabel: 'math_keyboard_$hashCode',
          descendantsAreFocusable: false,
        );
      } else {
        // Switch the outside focus node.
        _focusNode = widget.focusNode!;
      }
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _scrollController.dispose();
    _keyboardSlideController.dispose();
    _cursorBlinkController.dispose();

    if (widget.controller != null) {
      // We should only detach our listener and not dispose an outside
      // controller if provided.
      _controller.removeListener(_handleControllerUpdate);
    } else {
      _controller.dispose();
    }

    if (widget.focusNode == null) {
      // Dispose the local focus node.
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _handleBlinkUpdate() {
    if (_cursorBlinkController.value > 1 / 2) {
      if (_cursorOpacity == 1) return;
      // Set the cursor opacity to 1 when the blink controller value is greater
      // than 1/2, i.e. roughly half of the time.
      setState(() {
        _cursorOpacity = 1;
      });
      return;
    }

    if (_cursorOpacity == 0) return;
    // Set the cursor opacity to 0 when the blink controller value is smaller
    // than *or equal to* 1/2. Note that we always start at 1/2 in order to
    // immediately make the cursor visible once the controller advances.
    setState(() {
      _cursorOpacity = 0;
    });
  }

  void _handleControllerUpdate() {
    // We want to automatically scroll the math field to the right when the
    // cursor is all the way to the right.
    if (_controller.root.cursorAtTheEnd()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.fastOutSlowIn,
        );
      });
    }

    final expression = _controller.currentEditingValue(
      placeholderWhenEmpty: false,
    );
    // We want to make sure to execute the callback after we have
    // executed all of our logic that we know has to be executed.
    // This is because the callback might throw an exception, in which
    // case we would lose the cursor.
    widget.onChanged?.call(expression);
  }

  /// Handles any focus changes of the math field, i.e. essentially when
  /// the math keyboard should be opened and when it should be closed.
  ///
  /// When [open] is true, the keyboard should be opened and vice versa.
  void _handleFocusChanged(BuildContext context, {required bool open}) {
    if (!open) {
      _keyboardSlideController.reverse();
      _cursorBlinkController.value = 1 / 2;
    } else {
      _openKeyboard(context);
      _keyboardSlideController.forward(from: 0);
      _cursorBlinkController.repeat();

      _showFieldOnScreen();
    }

    setState(() {
      // Mark as dirty in order to respond to the focus node update.
    });
  }

  bool _showFieldOnScreenScheduled = false;

  /// Shows the math field on screen by e.g. auto scrolling in list views.
  void _showFieldOnScreen() {
    if (_showFieldOnScreenScheduled) {
      return;
    }
    _showFieldOnScreenScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _showFieldOnScreenScheduled = false;
      if (!mounted) return;

      context.findRenderObject()!.showOnScreen(
            duration: const Duration(milliseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
    });
  }

  void _openKeyboard(BuildContext context) {
    if (!widget.opensKeyboard) return;

    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Localizations.override(
          // Make sure to inject the same locale the math field uses in order
          // to match the decimal separators.
          context: this.context,
          locale: Localizations.localeOf(this.context),
          child: MathKeyboard(
            controller: _controller,
            type: widget.keyboardType,
            variables: _variables,
            onSubmit: _submit,
            onHeightChanged: widget.onKeyboardHeightChanged,
            // Note that we need to pass the insets state like this because the
            // overlay context does not have the ancestor state.
            insetsState: MathKeyboardViewInsetsState.of(this.context),
            slideAnimation: _keyboardSlideController,
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Launches keyboard slide animation in reversed direction.
  /// By the end of it the [_overlayEntry] will be removed
  /// by the [_keyboardSlideController] listener callback.
  ///
  /// Keep in mind: it does not remove the focus from the field.
  void _closeKeyboard() {
    _keyboardSlideController.reverse();
  }

  void _submit() {
    _focusNode.unfocus();
    widget.onSubmitted?.call(
      _controller.currentEditingValue(placeholderWhenEmpty: false),
    );
  }

  KeyEventResult _handleKey(FocusNode node, RawKeyEvent keyEvent) {
    if (keyEvent is! RawKeyDownEvent) {
      // We do not want to handle key up events in order to prevent double
      // detection of logical key events (pressing backspace would be triggered
      // twice - once for key down and once for key up). Characters already
      // handle this by default (keyEvent.character is null for key up) but
      // we can still cancel early :)
      return KeyEventResult.ignored;
    }

    final configs = <List<KeyboardButtonConfig>>[
      if (widget.keyboardType ==
          MathKeyboardType.expression) ...<List<KeyboardButtonConfig>>[
        ...standardKeyboard,
        ...functionKeyboard,
      ] else if (widget.keyboardType == MathKeyboardType.numberOnly) ...[
        ...numberKeyboard,
      ],
    ].fold<List<KeyboardButtonConfig>>([], (previousValue, element) {
      return previousValue..addAll(element);
    });

    final characterResult = _handleCharacter(keyEvent.character, configs);
    if (characterResult != null) {
      return characterResult;
    }
    final logicalKeyResult = _handleLogicalKey(keyEvent.logicalKey, configs);
    if (logicalKeyResult != null) {
      return logicalKeyResult;
    }

    return KeyEventResult.ignored;
  }

  /// Handles the given [RawKeyEvent.character].
  ///
  /// Returns `null` if not handled (indecisive) and a [KeyEventResult] if we
  /// can conclude about the complete key handling from the action taken.
  KeyEventResult? _handleCharacter(
      String? character, List<KeyboardButtonConfig> configs) {
    if (character == null) return null;
    final lowerCaseCharacter = character.toLowerCase();

    // The button configs take precedence over any variables.
    for (final config in configs) {
      if (config is! BasicKeyboardButtonConfig) continue;
      if (config.keyboardCharacters.isEmpty) continue;

      if (config.keyboardCharacters
          .any((element) => element.toLowerCase() == lowerCaseCharacter)) {
        final basicConfig = config;
        if (basicConfig.args != null) {
          _controller.addFunction(basicConfig.value, basicConfig.args!);
        } else {
          _controller.addLeaf(basicConfig.value);
        }
        return KeyEventResult.handled;
      }
    }

    if (widget.keyboardType == MathKeyboardType.numberOnly) {
      // Return early in number-only mode because the handlers below are only
      // for variables/constants.
      return null;
    }

    // Handle generally specified constants.
    if (lowerCaseCharacter == 'p') {
      _controller.addLeaf(r'{\pi}');
      return KeyEventResult.handled;
    }
    if (lowerCaseCharacter == 'e') {
      _controller.addLeaf('{e}');
      return KeyEventResult.handled;
    }

    // Handle user-specified variables.
    for (final variable in widget.variables) {
      final startingCharacter = variable.substring(0, 1).toLowerCase();
      if (startingCharacter == lowerCaseCharacter) {
        _controller.addLeaf('{$variable}');
        return KeyEventResult.handled;
      }
    }
    return null;
  }

  /// Handles the given [RawKeyEvent.logicalKey].
  ///
  /// Returns `null` if not handled (indecisive) and a [KeyEventResult] if we
  /// can conclude about the complete key handling from the action taken.
  KeyEventResult? _handleLogicalKey(
      LogicalKeyboardKey logicalKey, List<KeyboardButtonConfig> configs) {
    // Check logical, fixed keyboard bindings (like backspace and arrow keys).
    if (logicalKey == LogicalKeyboardKey.backspace &&
        configs.any((element) => element is DeleteButtonConfig)) {
      _controller.goBack(deleteMode: true);
      return KeyEventResult.handled;
    }
    if ((logicalKey == LogicalKeyboardKey.arrowRight ||
            logicalKey == LogicalKeyboardKey.arrowDown) &&
        configs.any((element) => element is NextButtonConfig)) {
      _controller.goNext();
      return KeyEventResult.handled;
    }
    if ((logicalKey == LogicalKeyboardKey.arrowLeft ||
            logicalKey == LogicalKeyboardKey.arrowUp) &&
        configs.any((element) => element is PreviousButtonConfig)) {
      _controller.goBack();
      return KeyEventResult.handled;
    }
    if ((logicalKey == LogicalKeyboardKey.enter ||
            logicalKey == LogicalKeyboardKey.numpadEnter) &&
        configs.any((element) => element is SubmitButtonConfig)) {
      _submit();
      return KeyEventResult.handled;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isKeyboardShown) {
          _closeKeyboard();
          return false;
        }
        return true;
      },
      child: MouseRegion(
        cursor: MaterialStateMouseCursor.textable,
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          // On devices with software keyboards, we *cannot* (properly) prevent the
          // software keyboard from showing when a key on the physical keyboard
          // is pressed. See https://github.com/flutter/flutter/issues/44681.
          // todo: fix the problem once we have an update on flutter/flutter#44681.
          onFocusChange: (primary) =>
              _handleFocusChanged(context, open: primary),
          onKey: _handleKey,
          child: GestureDetector(
            onTap: () {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              } else if (!_isKeyboardShown) {
                // Sometimes the field can be focused but the keyboard is not shown.
                // For example if it was closed with [_closeKeyboard].
                _handleFocusChanged(context, open: true);
              }
            },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _FieldPreview(
                  controller: _controller,
                  scrollController: _scrollController,
                  cursorOpacity: _cursorOpacity,
                  hasFocus: _focusNode.hasFocus,
                  decoration: widget.decoration
                      .applyDefaults(Theme.of(context).inputDecorationTheme),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for previewing the user's input.
class _FieldPreview extends StatelessWidget {
  /// Constructs a [_FieldPreview].
  const _FieldPreview({
    Key? key,
    required this.controller,
    required this.cursorOpacity,
    required this.hasFocus,
    required this.decoration,
    required this.scrollController,
  }) : super(key: key);

  /// The controller for the math field.
  final MathFieldEditingController controller;

  /// The scroll controller handling the horizontal positioning inside of the
  /// preview viewport.
  final ScrollController scrollController;

  /// The opacity that the cursor should have in the preview.
  final double cursorOpacity;

  /// Whether this input field has focus right now.
  final bool hasFocus;

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  // Adapted from InputDecorator._getFillColor.
  Color _getDisabledCursorColor(ThemeData themeData) {
    if (!(decoration.filled ?? false)) {
      return themeData.colorScheme.surface;
    }

    if (decoration.fillColor != null) {
      return Color.alphaBlend(
          decoration.fillColor!, themeData.colorScheme.surface);
    }

    // dark theme: 10% white (enabled), 5% white (disabled)
    // light theme: 4% black (enabled), 2% black (disabled)
    const darkEnabled = Color(0x1AFFFFFF);
    const darkDisabled = Color(0x0DFFFFFF);
    const lightEnabled = Color(0x0A000000);
    const lightDisabled = Color(0x05000000);

    final Color foregroundColor;
    switch (themeData.brightness) {
      case Brightness.dark:
        foregroundColor = decoration.enabled ? darkEnabled : darkDisabled;
        break;
      case Brightness.light:
        foregroundColor = decoration.enabled ? lightEnabled : lightDisabled;
        break;
    }
    return Color.alphaBlend(foregroundColor, themeData.colorScheme.surface);
  }

  // Adapted from InputDecorator._getInlineStyle.
  TextStyle _getHintStyle(ThemeData themeData) {
    return themeData.textTheme.titleMedium!
        .copyWith(
            color: decoration.enabled
                ? themeData.hintColor
                : themeData.disabledColor)
        .merge(decoration.hintStyle);
  }

  @override
  Widget build(BuildContext context) {
    final tex = controller.root
        .buildTeXString(
          cursorColor: Color.lerp(
            _getDisabledCursorColor(Theme.of(context)),
            Theme.of(context).textSelectionTheme.cursorColor ??
                Theme.of(context).colorScheme.secondary,
            cursorOpacity,
          ),
        )
        .replaceAll(
          // We assume that every dot in the tex string is a decimal dot
          // that can simply be replaced by an alternate decimal separator
          // for the preview.
          '.',
          // We need to wrap the decimal separator in an extra group ("{}")
          // because commas will otherwise be spaced as if they created a
          // list, e.g. in vector notation (there is a padding to the right
          // of the comma).
          '{${decimalSeparator(context)}}',
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        minHeight: 48,
      ),
      child: InputDecorator(
        textAlignVertical: TextAlignVertical.center,
        // TODO: replace once the decorator handles the hint.
        // isEmpty: controller.isEmpty,
        isEmpty: false,
        isFocused: hasFocus,
        decoration: decoration,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Stack(
            children: [
              Transform.translate(
                offset: !controller.isEmpty
                    ? Offset.zero
                    // This is a workaround for aligning the cursor properly
                    // when the math field is empty. This way it matches the
                    // TextField behavior.
                    : Offset(-1, 0),
                child: Math.tex(
                  tex,
                  options: MathOptions(
                    fontSize: MathOptions.defaultFontSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // todo: let InputDecorator take care of the hint text (as soon as
              // todo| we figure out how to deal with the baseline problem).
              if (controller.isEmpty)
                Text(
                  decoration.hintText ?? '',
                  style: _getHintStyle(Theme.of(context)),
                )
            ],
          ),
        ),
      ),
    );
  }
}

/// A controller for an editable math field.
class MathFieldEditingController extends ChangeNotifier {
  /// Constructs a [MathKeyboardViewModel].
  MathFieldEditingController() {
    currentNode = root;
    currentNode.setCursor();
  }

  /// Type of the Keyboard.
  bool secondPage = false;

  /// The root node of the expression.
  TeXNode root = TeXNode(null);

  /// The block the user is currently in.
  late TeXNode currentNode;

  /// Returns the current editing value (expression), which requires temporarily
  /// removing the cursor. When [placeholderWhenEmpty] is true, a TeX \Box
  /// is returned as a placeholder.
  String currentEditingValue({bool placeholderWhenEmpty = true}) {
    currentNode.removeCursor();
    // Store the expression as a TeX string.
    final expression = root.buildTeXString(
      // By passing null as the cursor color here, we are asserting
      // that the cursor is not part of the tree in a way.
      cursorColor: null,
      placeholderWhenEmpty: placeholderWhenEmpty,
    );
    currentNode.setCursor();

    return expression;
  }

  /// Searches through a TeXNode tree and recursively removes Cursor instances,
  /// reconstructing the tree without these cursors and returning a new TeXNode
  /// without any cursor elements.
  TeXNode removeCursorRecursively(TeXNode texNode) {
    final returnNode = TeXNode(null);
    int? rootCursorIndex;
    final children = texNode.children;
    final returnChildren = <TeX>[];
    for (var i = 0; i < children.length; i++) {
      final currentChild = children[i];
      if (currentChild is Cursor) {
        rootCursorIndex = i;
        returnChildren.add(currentChild);
      } else if (currentChild is TeXFunction) {
        final childNodes = List.of(currentChild.argNodes);
        final returnChildNodes = <TeXNode>[];
        for (final innerChildNode in childNodes) {
          final returnInnerChildNode = removeCursorRecursively(innerChildNode);
          returnChildNodes.add(returnInnerChildNode);
        }
        final returnTeXFunction = TeXFunction(
          currentChild.expression,
          currentChild.parent,
          currentChild.args,
          returnChildNodes,
        );
        returnTeXFunction.parent = texNode;
        returnChildren.add(returnTeXFunction);
      } else {
        returnChildren.add(currentChild);
      }
    }
    if (rootCursorIndex != null) {
      returnChildren.removeAt(rootCursorIndex);
    }
    returnNode.children.addAll(returnChildren);
    return returnNode;
  }

  /// Traverses a TeXNode tree, setting each TeXFunction node's parent to the current node
  /// and applies this process recursively to all argument nodes within these functions.
  TeXNode setParentRecursively(TeXNode node) {
    final childrenLength = node.children.length;
    for (var i = 0; i < childrenLength; i++) {
      final child = node.children[i];
      if (child is TeXFunction) {
        child.parent = node;
        final innerNodesLength = child.argNodes.length;
        for (var j = 0; j < innerNodesLength; j++) {
          setParentRecursively(child.argNodes[j]);
        }
      }
    }
    return node;
  }

  /// Sets the cursor position to the end of each node's children list in a TeXNode tree.
  /// It ensures that the cursor is correctly placed after the last child for every node in the tree.
  TeXNode correctCursorPositionRecursively(TeXNode node) {
    final childrenLength = node.children.length;
    node.courserPosition = childrenLength;
    for (var i = 0; i < childrenLength; i++) {
      final child = node.children[i];
      if (child is TeXFunction) {
        final innerNodesLength = child.argNodes.length;
        for (var j = 0; j < innerNodesLength; j++) {
          correctCursorPositionRecursively(child.argNodes[j]);
        }
      }
    }
    return node;
  }

  /// Adds the given [TeX] to a [TeXNode] and sets it as the root node
  void setRootNodeTeX(List<TeX> tex) {
    final returnNode = TeXNode(null);
    returnNode.children.addAll(tex);
    setRootNode(returnNode);
  }

  /// Clears the current value and sets the root node to it to the given [texNode].
  void setRootNode(TeXNode texNode) {
    try {
      final removedCursor = removeCursorRecursively(texNode);
      final correctedParent = setParentRecursively(removedCursor);
      final correctedPosition =
          correctCursorPositionRecursively(correctedParent);
      root = correctedPosition;
    } catch (e) {
      throw Exception('Unsupported input TeXNode');
    }
    currentNode = root;
    currentNode.courserPosition = currentNode.children.length;
    currentNode.setCursor();
    notifyListeners();
  }

  /// Clears the current value and sets it to the [expression] equivalent.
  void updateValue(Expression expression) {
    try {
      root = convertMathExpressionToTeXNode(expression);
    } catch (e) {
      throw Exception('Unsupported input expression $expression ($e)');
    }
    currentNode = root;
    currentNode.courserPosition = currentNode.children.length;
    currentNode.setCursor();
    notifyListeners();
  }

  /// Navigate to the previous node.
  void goBack({bool deleteMode = false}) {
    final state =
        deleteMode ? currentNode.remove() : currentNode.shiftCursorLeft();
    switch (state) {
      // CASE 1: Courser was moved 1 position to the left in the current node.
      case NavigationState.success:
        notifyListeners();
        return;
      // CASE 2: The upcoming tex is a function.
      // We want to step in this function rather than skipping/deleting it.
      case NavigationState.func:
        final pos = currentNode.courserPosition;
        currentNode = (currentNode.children[pos] as TeXFunction).argNodes.last;
        currentNode.courserPosition = currentNode.children.length;
        currentNode.setCursor();
        notifyListeners();
        return;
      // CASE 3: The courser is already at the beginning of this node.
      case NavigationState.end:
        // If the current node is the root, we can't navigate further.
        if (currentNode.parent == null) {
          return;
        }
        // Otherwise, the current node must be a function argument.
        currentNode.removeCursor();
        final parent = currentNode.parent!;
        final nextArg = parent.argNodes.indexOf(currentNode) - 1;
        // If the parent function has another argument before this one,
        // we jump into that, otherwise we position the courser right
        // before the function.
        if (nextArg < 0) {
          currentNode = parent.parent;
          currentNode.courserPosition = currentNode.children.indexOf(parent);
          if (deleteMode) {
            currentNode.children.remove(parent);
          }
          currentNode.setCursor();
        } else {
          currentNode = currentNode.parent!.argNodes[nextArg];
          currentNode.courserPosition = currentNode.children.length;
          currentNode.setCursor();
        }
        notifyListeners();
    }
  }

  /// Navigate to the next node.
  void goNext() {
    final state = currentNode.shiftCursorRight();
    switch (state) {
      // CASE 1: Courser was moved 1 position to the right in the current node.
      case NavigationState.success:
        notifyListeners();
        return;
      // CASE 2: The upcoming tex is a function.
      // We want to step in this function rather than skipping it.
      case NavigationState.func:
        final pos = currentNode.courserPosition - 1;
        currentNode = (currentNode.children[pos] as TeXFunction).argNodes.first;
        currentNode.courserPosition = 0;
        currentNode.setCursor();
        notifyListeners();
        return;
      // CASE 3: The courser is already at the end of this node.
      case NavigationState.end:
        // If the current node is the root, we can't navigate further.
        if (currentNode.parent == null) {
          return;
        }
        // Otherwise, the current node must be a function argument.
        currentNode.removeCursor();
        final parent = currentNode.parent!;
        final nextArg = parent.argNodes.indexOf(currentNode) + 1;
        // If the parent function has another argument after this one,
        // we jump into that, otherwise we position the courser right
        // after the function.
        if (nextArg >= parent.argNodes.length) {
          currentNode = parent.parent;
          currentNode.courserPosition =
              currentNode.children.indexOf(parent) + 1;
          currentNode.setCursor();
        } else {
          currentNode = currentNode.parent!.argNodes[nextArg];
          currentNode.courserPosition = 0;
          currentNode.setCursor();
        }
        notifyListeners();
    }
  }

  /// Add leaf to the current node.
  void addLeaf(String tex) {
    currentNode.addTeX(TeXLeaf(tex));
    notifyListeners();
  }

  /// Add function to the current node.
  void addFunction(String tex, List<TeXArg> args) {
    currentNode.removeCursor();
    final func = TeXFunction(tex, currentNode, args);

    /// Adding a pow requires further action, that's why we handle it in it's
    /// own function.
    if (tex.startsWith('^')) {
      addPow(func);
    }
    // The same applies for fractions.
    else if (tex == r'\frac') {
      addFrac(func);
    } else {
      currentNode.addTeX(func);
      currentNode = func.argNodes.first;
    }
    currentNode.setCursor();
    notifyListeners();
  }

  /// Adds a pow to the current node
  ///
  /// If the expression is ^2 instead of ^, we want to set 2 as the argument
  /// of the pow function directly.
  void addPow(TeXFunction pow) {
    final posBefore = currentNode.courserPosition - 1;

    /// We don't allow having to pow's next to each other (x^2^2), since this
    /// is not supported by TeX.
    if (currentNode.children.isEmpty ||
        currentNode.courserPosition == 0 ||
        currentNode.children[posBefore].expression == '^' ||
        currentNode.courserPosition < currentNode.children.length &&
            currentNode.children[posBefore + 1].expression == '^') {
      return;
    }
    if (pow.expression.endsWith('2')) {
      final powCopy = TeXFunction('^', pow.parent, pow.args, pow.argNodes);
      powCopy.argNodes.first.addTeX(const TeXLeaf('2'));
      currentNode.addTeX(powCopy);
    } else {
      currentNode.addTeX(pow);
      currentNode = pow.argNodes.first;
    }
  }

  /// Adds a fraction to the current node.
  ///
  /// There are two options: Either we divide the previous term, or we add an
  /// empty frac.
  void addFrac(TeXFunction frac) {
    // We first want to divide the list with children at the current courser
    // position. This way, we can always look at the last element in the list,
    // when taking the numerator, and don't need to keep track of the index.
    final tail = currentNode.children.sublist(currentNode.courserPosition);
    currentNode.children
        .removeRange(currentNode.courserPosition, currentNode.children.length);
    // Expressions that indicate operators.
    final operators = ['+', '-', r'\cdot', r'\div'];
    // We need to determine whether we want to append an empty fraction or
    // divide the last expression, therefore keep it as the numerator.
    var keepNumerator = true;
    // There are 3 cases where we want to append a clean fraction, and therefore
    // don't keep a numerator.
    // CASE 1: The current node is empty.
    if (currentNode.children.isEmpty) {
      keepNumerator = false;
    }
    // CASE 2: The tex symbol before is a opening parenthesis.
    else if (currentNode.children.last.expression.endsWith('(')) {
      keepNumerator = false;
    }
    // CASE 3: The tex symbol before is an operator.
    else if (operators.contains(currentNode.children.last.expression)) {
      keepNumerator = false;
    }
    // If the goal is to divide the previous expression, we want to remove this
    // part from the current node and use it as the first argument of the frac.
    if (keepNumerator) {
      _takeNumerator(frac);
      // We then need to set the courserPosition to the new length of the
      // current node's children list.
      currentNode.courserPosition = currentNode.children.length;
    }
    currentNode.addTeX(frac);
    // We know want to add all elements that we saved earlier to the end of
    // the list.
    currentNode.children.addAll(tail);
    // If we took the numerator, we want to jump straight into the second
    // argument.
    currentNode = frac.argNodes[keepNumerator ? 1 : 0];
  }

  /// Takes a numerator off the current node and inserts it in a frac's first
  /// argument.
  void _takeNumerator(TeXFunction frac) {
    // We remove the last TeX-object from the current node and insert it in the
    // frac's first argument.
    var lastTeX = currentNode.children.removeLast();
    frac.argNodes.first.children.insert(0, lastTeX);
    // If we move a TeXFunction, we need to update it's parent!
    if (lastTeX is TeXFunction) {
      lastTeX.parent = frac.argNodes.first;
    }
    // It is probably not enough to just take the last TeX-object. In the
    // following base cases we need to move further TeX-objects.

    // CASE 1: Number (consisting of more than one digit)
    // If the last expression was a number, we need to make sure that we take
    // the whole number, since the digits are in fact single TeX objects.
    final numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.'];
    if (numbers.contains(lastTeX.expression)) {
      while (currentNode.children.isNotEmpty &&
          numbers.contains(currentNode.children.last.expression)) {
        lastTeX = currentNode.children.removeLast();
        frac.argNodes.first.children.insert(0, lastTeX);
      }
    }
    // CASE 2: Parentheses
    // If the last expression was an closing parenthesis, we need to repeat
    // this with every TeX object (going backwards) until we reach the
    // counter part of this parenthesis.
    else if (lastTeX.expression == ')') {
      // This was an exercise in my first semester at university LOL.
      final stack = [')'];
      while (currentNode.children.isNotEmpty && stack.isNotEmpty) {
        lastTeX = currentNode.children.removeLast();
        // If we move a TeXFunction, we need to update it's parent!
        if (lastTeX is TeXFunction) {
          lastTeX.parent = frac.argNodes.first;
        }
        if (lastTeX.expression.contains(')')) {
          stack.add(')');
        }
        if (lastTeX.expression.contains('(')) {
          stack.removeLast();
        }
        frac.argNodes.first.children.insert(0, lastTeX);
      }
    }
    // CASE 3: Power
    // There's one more case where we need to take more off the current node
    // then the last expression. The power has it's first argument (the base)
    // in front of itself. Therefore we need to determine the base and insert
    // it in the fractions first argument. We can use a recursive call for
    // that.
    else if (lastTeX.expression.startsWith('^')) {
      _takeNumerator(frac);
    }
  }

  /// Clears all by resetting the controller.
  ///
  /// This will discard the old [root].
  void clear() {
    root = TeXNode(null);
    currentNode = root;
    currentNode.courserPosition = 0;
    currentNode.setCursor();
    notifyListeners();
  }

  /// Switches between Page 1 and 2.
  void togglePage() {
    secondPage = !secondPage;
    notifyListeners();
  }

  /// Whether the controller is empty or not.
  bool get isEmpty {
    // Consider that there's always the courser as a child.
    if (root == currentNode) {
      return root.children.length < 2;
    } else {
      return root.children.isEmpty;
    }
  }

  var _disposed = false;

  @override
  void dispose() {
    assert(!_disposed);
    _disposed = true;
    super.dispose();
  }

  @override
  void removeListener(VoidCallback listener) {
    // Workaround for the fact that the AnimatedBuilder's in the math keyboard
    // overlay might be disposed after the math field is disposed.
    if (_disposed) return;
    super.removeListener(listener);
  }
}
