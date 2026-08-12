import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/src/custom_key_icons/custom_key_icons.dart';
import 'package:math_keyboard/src/foundation/keyboard_button.dart';
import 'package:math_keyboard/src/foundation/math_keyboard_semantics.dart';
import 'package:math_keyboard/src/widgets/decimal_separator.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';
import 'package:math_keyboard/src/widgets/math_field.dart';
import 'package:math_keyboard/src/widgets/math_keyboard_theme.dart';
import 'package:math_keyboard/src/widgets/view_insets.dart';

/// Enumeration for the types of keyboard that a math keyboard can adopt.
///
/// This way we allow different button configurations. The user may only need to
/// input a number.
enum MathKeyboardType {
  /// Keyboard for entering complete math expressions.
  ///
  /// This shows numbers + operators and a toggle button to switch to another
  /// page with extended functions.
  expression,

  /// Keyboard for number input only.
  numberOnly,
}

/// Widget displaying the math keyboard.
///
/// Typically driven by a [MathField], which wires the focus integration
/// automatically. When embedding [MathKeyboard] directly, note that its keys
/// live in a [FocusScope] that *contains* tab traversal: focus only leaves the
/// keys through [onExitToField]/[onExitToNext], and those only fire when a
/// [focusScopeNode] is also supplied (the edge check needs the scope). So a
/// bare [MathKeyboard] with no focus wiring keeps tab focus among its keys; to
/// let focus leave (WCAG 2.1.2), pass [focusScopeNode] together with
/// [onExitToField] and [onExitToNext] — the way [MathField] does.
class MathKeyboard extends StatelessWidget {
  /// Constructs a [MathKeyboard].
  const MathKeyboard({
    Key? key,
    required this.controller,
    this.type = MathKeyboardType.expression,
    this.variables = const [],
    this.onSubmit,
    this.insetsState,
    this.slideAnimation,
    this.style,
    this.semantics,
    this.focusScopeNode,
    this.onExitToField,
    this.onExitToNext,
    this.onClose,
    this.padding = const EdgeInsets.only(bottom: 4, left: 4, right: 4),
  }) : assert(
         focusScopeNode != null ||
             (onExitToField == null && onExitToNext == null),
         'Provide focusScopeNode when supplying onExitToField/onExitToNext — '
         'the edge check needs the scope to know which key is last, so the '
         'callbacks never fire without it.',
       ),
       super(key: key);

  /// The controller for editing the math field.
  ///
  /// Must not be `null`.
  final MathFieldEditingController controller;

  /// The state for reporting the keyboard insets.
  ///
  /// If `null`, the math keyboard will not report about its bottom inset.
  final MathKeyboardViewInsetsState? insetsState;

  /// Animation that indicates the current slide progress of the keyboard.
  ///
  /// If `null`, the keyboard is always fully slided out.
  final Animation<double>? slideAnimation;

  /// The Variables a user can use.
  final List<String> variables;

  /// The Type of the Keyboard.
  final MathKeyboardType type;

  /// The visual styling of the keyboard.
  ///
  /// If `null`, the style is resolved from the nearest [MathKeyboardTheme], or
  /// [MathKeyboardStyle.fallback] if there is none.
  final MathKeyboardStyle? style;

  /// The screen-reader strings of the keyboard.
  ///
  /// If `null`, the semantics are resolved from the nearest [MathKeyboardTheme],
  /// or [MathKeyboardSemantics.fallback] if there is none.
  final MathKeyboardSemantics? semantics;

  /// The focus scope that owns the keys.
  ///
  /// Optional; `MathField` provides this automatically. Only needed when
  /// embedding [MathKeyboard] directly.
  ///
  /// The math field hands focus to this scope so a keyboard or switch-access
  /// user can move onto the keys (the field keeps ownership otherwise, which is
  /// why physical typing still works). The keys are ordinary buttons: tab moves
  /// between them, and the arrow keys additionally move across the grid.
  final FocusScopeNode? focusScopeNode;

  /// Called when tab moves past the first key (shift+tab), to return to the
  /// field instead of trapping focus inside the keys.
  ///
  /// Optional; wired automatically by `MathField`.
  final VoidCallback? onExitToField;

  /// Called when tab moves past the last key, to leave for the control after
  /// the field instead of wrapping back to the first key (WCAG 2.1.2).
  ///
  /// Optional; wired automatically by `MathField`.
  final VoidCallback? onExitToNext;

  /// Called to dismiss the keyboard, e.g. on escape from a key.
  ///
  /// Optional; wired automatically by `MathField`.
  final VoidCallback? onClose;

  /// Function that is called when the enter / submit button is tapped.
  ///
  /// Can be `null`.
  final VoidCallback? onSubmit;

  /// Insets of the keyboard.
  ///
  /// Defaults to `const EdgeInsets.only(bottom: 4, left: 4, right: 4),`.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? MathKeyboardTheme.styleOf(context);
    final semantics = this.semantics ?? MathKeyboardTheme.semanticsOf(context);
    final scaler = MediaQuery.textScalerOf(context);
    // The constructor asserts `maxTextScaleFactor >= 1`, but asserts are
    // stripped in release builds, so guard the upper bound: a runtime-computed
    // value below 1 would otherwise make `clamp` throw (lower > upper).
    final textScale = (scaler.scale(style.baseFontSize) / style.baseFontSize)
        .clamp(1.0, math.max(1.0, style.maxTextScaleFactor));
    final fontSize = style.baseFontSize * textScale;
    // Keys default to a fixed size (maxTextScaleFactor == 1): large-text
    // accessibility is provided by the large-content-viewer (long-press a key
    // to magnify it), so the layout does not need to reflow. A consumer can
    // instead opt into resize (WCAG 1.4.4) by raising maxTextScaleFactor, in
    // which case keys grow up to keyHeight * maxTextScaleFactor. The FittedBox
    // on each label stays as a safety net against overflow.
    final keyHeight = style.keyHeight * textScale;
    // In landscape the expression keyboard shows the functions and numbers side
    // by side with a full-height submit key, instead of paging. The number-only
    // keyboard keeps its compact paged layout.
    final isLandscape =
        type != MathKeyboardType.numberOnly &&
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final curvedSlideAnimation = CurvedAnimation(
      parent: slideAnimation ?? AlwaysStoppedAnimation(1),
      curve: Curves.ease,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: const Offset(0, 0),
      ).animate(curvedSlideAnimation),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: style.borderRadius,
                  boxShadow: style.boxShadow,
                ),
                child: SafeArea(
                  top: false,
                  child: _KeyboardBody(
                    insetsState: insetsState,
                    slideAnimation: slideAnimation == null
                        ? null
                        : curvedSlideAnimation,
                    // Note: the subtree is intentionally NOT wrapped in a
                    // `MediaQuery` with `TextScaler.noScaling`. The
                    // large-content-viewer keys read the ambient text scale to
                    // decide whether to enable the long-press magnifier, so it
                    // must remain visible here. Labels avoid double-scaling by
                    // setting `TextScaler.noScaling` on the individual `Text`s.
                    // Group the whole keyboard so it announces as a single unit
                    // containing the section landmarks. It is deliberately not a
                    // landmark itself — only the sections are jump targets, to
                    // avoid nested landmarks.
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: semantics.keyboardGroupLabel,
                      child: FocusScope(
                        node: focusScopeNode,
                        child: _wrapTabBoundary(
                          CallbackShortcuts(
                            bindings: {
                              if (onClose != null)
                                const SingleActivator(
                                  LogicalKeyboardKey.escape,
                                ): onClose!,
                            },
                            // Tab traverses the keys as ordinary buttons (and
                            // out to the next control at the ends); the arrow
                            // keys are a bonus for 2-D movement across the grid.
                            child: Shortcuts(
                              shortcuts: const {
                                SingleActivator(
                                  LogicalKeyboardKey.arrowLeft,
                                ): DirectionalFocusIntent(
                                  TraversalDirection.left,
                                ),
                                SingleActivator(
                                  LogicalKeyboardKey.arrowRight,
                                ): DirectionalFocusIntent(
                                  TraversalDirection.right,
                                ),
                                SingleActivator(
                                  LogicalKeyboardKey.arrowUp,
                                ): DirectionalFocusIntent(
                                  TraversalDirection.up,
                                ),
                                SingleActivator(
                                  LogicalKeyboardKey.arrowDown,
                                ): DirectionalFocusIntent(
                                  TraversalDirection.down,
                                ),
                              },
                              child: FocusTraversalGroup(
                                // Sections carry an explicit traversal order
                                // (numbers, then formula, then submit) via
                                // FocusTraversalOrder; keys without one fall
                                // back to reading order within their section.
                                policy: OrderedTraversalPolicy(),
                                child: isLandscape
                                    ? _buildLandscape(
                                        context,
                                        style: style,
                                        semantics: semantics,
                                        fontSize: fontSize,
                                        keyHeight: keyHeight,
                                      )
                                    : _buildPortrait(
                                        context,
                                        style: style,
                                        semantics: semantics,
                                        fontSize: fontSize,
                                        keyHeight: keyHeight,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lets tab traverse the keys as buttons, but hands focus out of the keyboard
  /// at the ends instead of wrapping (which would trap focus inside the keys).
  Widget _wrapTabBoundary(Widget child) {
    if (onExitToField == null && onExitToNext == null) return child;
    return Actions(
      actions: <Type, Action<Intent>>{
        NextFocusIntent: CallbackAction<NextFocusIntent>(
          onInvoke: (_) {
            if (_focusedIsAtEdge(last: true)) {
              onExitToNext?.call();
            } else {
              FocusManager.instance.primaryFocus?.nextFocus();
            }
            return null;
          },
        ),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: (_) {
            if (_focusedIsAtEdge(last: false)) {
              onExitToField?.call();
            } else {
              FocusManager.instance.primaryFocus?.previousFocus();
            }
            return null;
          },
        ),
      },
      child: child,
    );
  }

  /// Whether the focused key is the first (`last: false`) or last
  /// (`last: true`) key in the keyboard's traversal order.
  bool _focusedIsAtEdge({required bool last}) {
    final scope = focusScopeNode;
    final focused = FocusManager.instance.primaryFocus;
    if (scope == null || focused == null) return false;
    final descendants = scope.traversalDescendants.toList();
    if (descendants.isEmpty) return false;
    final ordered = OrderedTraversalPolicy().sortDescendants(
      descendants,
      focused,
    );
    return focused == (last ? ordered.last : ordered.first);
  }

  /// The portrait layout: a centered column of the variables row and the paged
  /// buttons.
  Widget _buildPortrait(
    BuildContext context, {
    required MathKeyboardStyle style,
    required MathKeyboardSemantics semantics,
    required double fontSize,
    required double keyHeight,
  }) {
    return Padding(
      padding: padding + style.padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type != MathKeyboardType.numberOnly) ...[
                Semantics(
                  role: SemanticsRole.region,
                  container: true,
                  explicitChildNodes: true,
                  label: semantics.variablesGroupLabel,
                  child: _Variables(
                    controller: controller,
                    variables: variables,
                    style: style,
                    semantics: semantics,
                    fontSize: fontSize,
                    keyHeight: keyHeight,
                  ),
                ),
                SizedBox(height: style.rowSpacing),
              ],
              _Buttons(
                controller: controller,
                page1: type == MathKeyboardType.numberOnly
                    ? numberKeyboard
                    : standardKeyboard,
                page2: type == MathKeyboardType.numberOnly
                    ? null
                    : functionKeyboard,
                onSubmit: onSubmit,
                style: style,
                semantics: semantics,
                fontSize: fontSize,
                keyHeight: keyHeight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The landscape layout: functions and numbers shown side by side with a
  /// full-height submit key.
  Widget _buildLandscape(
    BuildContext context, {
    required MathKeyboardStyle style,
    required MathKeyboardSemantics semantics,
    required double fontSize,
    required double keyHeight,
  }) {
    return Padding(
      padding:
          padding +
          style.padding +
          EdgeInsets.symmetric(horizontal: style.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _LandscapeButtons(
            controller: controller,
            variables: variables,
            onSubmit: onSubmit,
            style: style,
            semantics: semantics,
            fontSize: fontSize,
            keyHeight: keyHeight,
          ),
        ),
      ),
    );
  }
}

/// Widget that reports about the math keyboard body's bottom inset.
class _KeyboardBody extends StatefulWidget {
  const _KeyboardBody({
    Key? key,
    this.insetsState,
    this.slideAnimation,
    required this.child,
  }) : super(key: key);

  final MathKeyboardViewInsetsState? insetsState;

  /// The animation for sliding the keyboard.
  ///
  /// This is used in the body for reporting fractional sliding progress, i.e.
  /// reporting a smaller size while sliding.
  final Animation<double>? slideAnimation;

  final Widget child;

  @override
  _KeyboardBodyState createState() => _KeyboardBodyState();
}

class _KeyboardBodyState extends State<_KeyboardBody> {
  @override
  void initState() {
    super.initState();

    widget.slideAnimation?.addListener(_handleAnimation);
  }

  @override
  void didUpdateWidget(_KeyboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.insetsState != widget.insetsState) {
      _removeInsets(oldWidget.insetsState);
      _reportInsets(widget.insetsState);
    }

    if (oldWidget.slideAnimation != widget.slideAnimation) {
      oldWidget.slideAnimation?.removeListener(_handleAnimation);
      widget.slideAnimation?.addListener(_handleAnimation);
    }
  }

  @override
  void dispose() {
    _removeInsets(widget.insetsState);
    widget.slideAnimation?.removeListener(_handleAnimation);

    super.dispose();
  }

  void _handleAnimation() {
    _reportInsets(widget.insetsState);
  }

  void _removeInsets(MathKeyboardViewInsetsState? insetsState) {
    if (insetsState == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.insetsState![ObjectKey(this)] = null;
    });
  }

  void _reportInsets(MathKeyboardViewInsetsState? insetsState) {
    if (insetsState == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox;
      insetsState[ObjectKey(this)] =
          renderBox.size.height * (widget.slideAnimation?.value ?? 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    _reportInsets(widget.insetsState);
    return widget.child;
  }
}

/// Widget showing the variables a user can use.
class _Variables extends StatelessWidget {
  /// Constructs a [_Variables] Widget.
  const _Variables({
    Key? key,
    required this.controller,
    required this.variables,
    required this.style,
    required this.semantics,
    required this.fontSize,
    required this.keyHeight,
    this.leadingPadding,
  }) : super(key: key);

  /// The editing controller for the math field that the variables are connected
  /// to.
  final MathFieldEditingController controller;

  /// The variables to show.
  final List<String> variables;

  /// The resolved keyboard style.
  final MathKeyboardStyle style;

  /// The resolved keyboard semantics strings.
  final MathKeyboardSemantics semantics;

  /// The scaled font size of key labels.
  final double fontSize;

  /// The scaled height of a key.
  final double keyHeight;

  /// The leading inset of the row; defaults to [MathKeyboardStyle.horizontalPadding].
  final double? leadingPadding;

  @override
  Widget build(BuildContext context) {
    final leftPadding = leadingPadding ?? style.horizontalPadding;
    return SizedBox(
      height: keyHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Up to five keys are shown across the row. With more than five, the
          // keys are sized to five-and-a-half slots so the sixth bleeds off the
          // right edge — an affordance telling the user the row scrolls. (This
          // generalizes the design's phone-specific 55px to any keyboard width.)
          final slots = variables.length <= 5 ? 5.0 : 5.5;
          final keyWidth =
              ((constraints.maxWidth -
                          leftPadding -
                          style.rowSpacing * (slots - 1)) /
                      slots)
                  .clamp(keyHeight, double.infinity);
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return ListView.separated(
                itemCount: variables.length,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: leftPadding),
                separatorBuilder: (context, index) =>
                    SizedBox(width: style.rowSpacing),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: keyWidth,
                    child: Builder(
                      builder: (itemContext) => KeyboardButton(
                        keyStyle: style.neutralKey,
                        borderRadius: style.keyBorderRadius,
                        padding: style.keyPadding,
                        focusColor: style.focusBorderColor,
                        focusWidth: style.focusBorderWidth,
                        semanticsLabel: semantics.variableLabel(
                          variables[index],
                        ),
                        onFocusChange: (focused) {
                          if (!focused) return;
                          // Keep the focused variable visible under keyboard and
                          // switch-access navigation.
                          Scrollable.ensureVisible(
                            itemContext,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 100),
                          );
                        },
                        onTap: () =>
                            controller.addLeaf('{${variables[index]}}'),
                        largeContentThreshold:
                            style.largeContentViewerThreshold,
                        largeContent: style.largeContentViewerEnabled
                            ? Math.tex(
                                variables[index],
                                options: MathOptions(
                                  fontSize:
                                      fontSize * style.largeContentLabelScale,
                                  color: style.foregroundColor,
                                ),
                              )
                            : null,
                        child: Math.tex(
                          variables[index],
                          options: MathOptions(
                            fontSize: fontSize,
                            color: style.foregroundColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget displaying the buttons.
class _Buttons extends StatelessWidget {
  /// Constructs a [_Buttons] Widget.
  const _Buttons({
    Key? key,
    required this.controller,
    required this.style,
    required this.semantics,
    required this.fontSize,
    required this.keyHeight,
    this.page1,
    this.page2,
    this.onSubmit,
  }) : super(key: key);

  /// The editing controller for the math field that the variables are connected
  /// to.
  final MathFieldEditingController controller;

  /// The resolved keyboard style.
  final MathKeyboardStyle style;

  /// The resolved keyboard semantics strings.
  final MathKeyboardSemantics semantics;

  /// The scaled font size of key labels.
  final double fontSize;

  /// The scaled height of a key.
  final double keyHeight;

  /// The buttons to display.
  final List<List<KeyboardButtonConfig>>? page1;

  /// The buttons to display.
  final List<List<KeyboardButtonConfig>>? page2;

  /// Function that is called when the enter / submit button is tapped.
  ///
  /// Can be `null`.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // `togglePage()` is public and flips `secondPage` for any keyboard
        // type, but a number-only keyboard has no second page. Treat a stray
        // toggle as staying on page 1 so the layout and its region label never
        // disagree (and never force-unwrap a null `page2`).
        final showSecondPage = controller.secondPage && page2 != null;
        final layout = (showSecondPage ? page2! : page1) ?? numberKeyboard;
        // The visible page is a landmark region, named for whichever page
        // (numbers or functions) is currently showing, so a screen reader can
        // jump to it.
        return Semantics(
          role: SemanticsRole.region,
          container: true,
          explicitChildNodes: true,
          label: showSecondPage
              ? semantics.functionsGroupLabel
              : semantics.numbersGroupLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var rowIndex = 0; rowIndex < layout.length; rowIndex++) ...[
                if (rowIndex > 0) SizedBox(height: style.rowSpacing),
                SizedBox(
                  height: keyHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: style.horizontalPadding,
                    ),
                    child: Row(
                      // Stretch keys to fill the fixed row height so each button
                      // is exactly [keyHeight] tall instead of shrink-wrapping to
                      // its label.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < layout[rowIndex].length;
                          index++
                        ) ...[
                          if (index > 0) SizedBox(width: style.rowSpacing),
                          _Keys.button(
                            context,
                            layout[rowIndex][index],
                            controller: controller,
                            style: style,
                            semantics: semantics,
                            fontSize: fontSize,
                            onSubmit: onSubmit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Builds the [KeyboardButton] widget for a single [KeyboardButtonConfig].
///
/// Shared by the portrait and landscape layouts so the tier mapping, actions,
/// and semantics stay identical between them.
abstract final class _Keys {
  /// Whether [label] is a single digit `0`-`9`.
  static bool _isDigit(String label) =>
      label.length == 1 &&
      label.codeUnitAt(0) >= 0x30 &&
      label.codeUnitAt(0) <= 0x39;

  /// Builds the keyboard button for [config].
  static Widget button(
    BuildContext context,
    KeyboardButtonConfig config, {
    required MathFieldEditingController controller,
    required MathKeyboardStyle style,
    required MathKeyboardSemantics semantics,
    required double fontSize,
    VoidCallback? onSubmit,
  }) {
    return switch (config) {
      final BasicKeyboardButtonConfig config => _BasicButton(
        flex: config.flex,
        label: config.label,
        value: config.value,
        onTap: config.args != null
            ? () => controller.addFunction(config.value, config.args!)
            : () => controller.addLeaf(config.value),
        asTex: config.asTex,
        // Digits and typeset functions share the secondary surface; operators,
        // the decimal separator, and parentheses use the neutral surface.
        tier: config.asTex || _isDigit(config.label)
            ? MathKeyboardKeyTier.function
            : MathKeyboardKeyTier.neutral,
        style: style,
        semantics: semantics,
        fontSize: fontSize,
      ),
      final DeleteButtonConfig config => _NavigationButton(
        flex: config.flex,
        icon: Icons.backspace,
        semanticsLabel: semantics.deleteLabel,
        tier: MathKeyboardKeyTier.utility,
        style: style,
        fontSize: fontSize,
        onTap: () => controller.goBack(deleteMode: true),
      ),
      final PageButtonConfig config => _BasicButton(
        // A mode switch, not content: drop the long-press magnifier under a
        // screen reader. Sighted users keep it.
        enableLargeContentViewer: !MediaQuery.accessibleNavigationOf(context),
        flex: config.flex,
        icon: controller.secondPage ? null : CustomKeyIcons.key_symbols,
        label: controller.secondPage ? '123' : null,
        onTap: controller.togglePage,
        semanticsLabel: controller.secondPage
            ? semantics.showNumbersKeyboardLabel
            : semantics.showFunctionsKeyboardLabel,
        tier: MathKeyboardKeyTier.utility,
        style: style,
        semantics: semantics,
        fontSize: fontSize,
      ),
      final PreviousButtonConfig config => _NavigationButton(
        flex: config.flex,
        icon: Icons.chevron_left_rounded,
        semanticsLabel: semantics.moveCursorLeftLabel,
        semanticsValue: controller.describeCursorContext(semantics),
        tier: MathKeyboardKeyTier.neutral,
        style: style,
        fontSize: fontSize,
        onTap: controller.goBack,
      ),
      final NextButtonConfig config => _NavigationButton(
        flex: config.flex,
        icon: Icons.chevron_right_rounded,
        semanticsLabel: semantics.moveCursorRightLabel,
        semanticsValue: controller.describeCursorContext(semantics),
        tier: MathKeyboardKeyTier.neutral,
        style: style,
        fontSize: fontSize,
        onTap: controller.goNext,
      ),
      final SubmitButtonConfig config => _BasicButton(
        flex: config.flex,
        icon: Icons.keyboard_return,
        semanticsLabel: semantics.submitLabel,
        tier: MathKeyboardKeyTier.primary,
        style: style,
        semantics: semantics,
        fontSize: fontSize,
        onTap: onSubmit,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// The landscape body: the function keys (left) and number keys (right) shown
/// together, with a dedicated full-height submit key on the trailing edge.
class _LandscapeButtons extends StatelessWidget {
  const _LandscapeButtons({
    Key? key,
    required this.controller,
    required this.variables,
    required this.onSubmit,
    required this.style,
    required this.semantics,
    required this.fontSize,
    required this.keyHeight,
  }) : super(key: key);

  final MathFieldEditingController controller;
  final List<String> variables;
  final VoidCallback? onSubmit;
  final MathKeyboardStyle style;
  final MathKeyboardSemantics semantics;
  final double fontSize;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // The symbols (variables + three function rows) and numbers sections
        // each have four rows, so both columns and the full-height submit key
        // are this tall.
        final columnHeight = keyHeight * 4 + style.rowSpacing * 3;

        // [nextOrder], when given, pins each key an explicit traversal order so
        // tab follows the configured row-major layout instead of the geometry
        // of the (unevenly sized) cells.
        Widget row(
          List<KeyboardButtonConfig> configs, {
          int Function()? nextOrder,
        }) {
          Widget keyAt(int index) {
            final key = _Keys.button(
              context,
              configs[index],
              controller: controller,
              style: style,
              semantics: semantics,
              fontSize: fontSize,
              onSubmit: onSubmit,
            );
            if (nextOrder == null) return key;
            return FocusTraversalOrder(
              order: NumericFocusOrder(nextOrder().toDouble()),
              child: key,
            );
          }

          return SizedBox(
            height: keyHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < configs.length; index++) ...[
                  if (index > 0) SizedBox(width: style.rowSpacing),
                  keyAt(index),
                ],
              ],
            ),
          );
        }

        Widget column(List<Widget> rows) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0) SizedBox(height: style.rowSpacing),
                rows[index],
              ],
            ],
          );
        }

        // Expose each section as a labelled landmark region so a screen reader
        // can jump straight to variables, functions, numbers, or submit via its
        // landmark/rotor navigation.
        Widget semanticGroup(String label, Widget child) => Semantics(
          role: SemanticsRole.region,
          container: true,
          explicitChildNodes: true,
          label: label,
          child: child,
        );

        final variablesGroup = semanticGroup(
          semantics.variablesGroupLabel,
          _Variables(
            controller: controller,
            variables: variables,
            style: style,
            semantics: semantics,
            fontSize: fontSize,
            keyHeight: keyHeight,
            leadingPadding: 0,
          ),
        );

        // Global traversal orders, so a single OrderedTraversalPolicy sends tab
        // through the whole keyboard as numbers → variables → functions →
        // submit, each in reading order. The ranges keep the sections apart:
        // numbers 0.., variables 100, functions 200.., submit 300.
        var numberKeyOrder = 0;
        var functionKeyOrder = 200;

        final functionsGroup = semanticGroup(
          semantics.functionsGroupLabel,
          column([
            for (final functionRow in landscapeFunctionKeyboard)
              row(functionRow, nextOrder: () => functionKeyOrder++),
          ]),
        );

        final numbersGroup = semanticGroup(
          semantics.numbersGroupLabel,
          column([
            for (final numberRow in landscapeNumberKeyboard)
              row(numberRow, nextOrder: () => numberKeyOrder++),
          ]),
        );

        // The submit key is a single button, so it only needs a semantics
        // boundary to stay a sibling of the section landmarks (rather than
        // merging upward and swallowing them). It is deliberately not a
        // labelled region — that would announce "Submit" twice, once for the
        // region and once for the button.
        final submitGroup = Semantics(
          container: true,
          explicitChildNodes: true,
          child: SizedBox(
            width: keyHeight,
            height: columnHeight,
            child: KeyboardButton(
              onTap: onSubmit,
              keyStyle: style.primaryKey,
              borderRadius: style.keyBorderRadius,
              padding: style.keyPadding,
              focusColor: style.focusBorderColor,
              focusWidth: style.focusBorderWidth,
              semanticsLabel: semantics.submitLabel,
              child: Icon(
                Icons.keyboard_return,
                color: style.foregroundColor,
                size: fontSize,
              ),
            ),
          ),
        );

        // The variables and submit sections have no per-key order of their own,
        // so pin them to a single order each (between and after the numbered
        // ranges above). Arrow keys still move across all keys by geometry.
        Widget ordered(double order, Widget child) =>
            FocusTraversalOrder(order: NumericFocusOrder(order), child: child);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 322,
              child: column([ordered(100, variablesGroup), functionsGroup]),
            ),
            SizedBox(width: style.horizontalPadding),
            Expanded(flex: 256, child: numbersGroup),
            SizedBox(width: style.horizontalPadding),
            ordered(300, submitGroup),
          ],
        );
      },
    );
  }
}

/// Widget displaying a single keyboard button.
class _BasicButton extends StatelessWidget {
  /// Constructs a [_BasicButton].
  const _BasicButton({
    Key? key,
    required this.flex,
    required this.tier,
    required this.style,
    required this.semantics,
    required this.fontSize,
    this.label,
    this.value,
    this.icon,
    this.onTap,
    this.asTex = false,
    this.semanticsLabel,
    this.enableLargeContentViewer = true,
  }) : assert(label != null || icon != null),
       super(key: key);

  /// Whether this key gets a long-press large-content magnifier.
  ///
  /// Disabled for the page-toggle key while a screen reader is active: it is a
  /// mode switch rather than content, and the magnifier popup adds no value
  /// there.
  final bool enableLargeContentViewer;

  /// The flexible flex value.
  final int? flex;

  /// The color tier of this button.
  final MathKeyboardKeyTier tier;

  /// The resolved keyboard style.
  final MathKeyboardStyle style;

  /// The resolved keyboard semantics strings.
  final MathKeyboardSemantics semantics;

  /// The scaled font size of the label.
  final double fontSize;

  /// The label for this button.
  final String? label;

  /// The TeX token this button inserts, used to resolve the spoken semantics
  /// label of plain-text keys (e.g. `\cdot` → "times") instead of announcing
  /// the raw glyph.
  final String? value;

  /// Icon for this button.
  final IconData? icon;

  /// Function to be called on tap.
  final VoidCallback? onTap;

  /// Show label as tex.
  final bool asTex;

  /// The semantics label describing this button.
  final String? semanticsLabel;

  /// Builds the label widget (icon, typeset, or text) at the given [size].
  Widget _label(BuildContext context, double size) {
    if (label == null) {
      return Icon(icon, color: style.foregroundColor, size: size);
    }
    if (asTex) {
      return Math.tex(
        label!,
        options: MathOptions(fontSize: size, color: style.foregroundColor),
      );
    }
    // The decimal separator is rendered per the current locale.
    final symbol = label == '.' ? decimalSeparator(context) : label!;
    return Text(
      symbol,
      // The size is already resolved; don't let the ambient text scale grow it
      // again (the large-content-viewer provides the magnification instead).
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontSize: size,
        color: style.foregroundColor,
        fontFamily: style.fontFamily,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? resolvedSemanticsLabel;
    if (semanticsLabel != null) {
      resolvedSemanticsLabel = semanticsLabel;
    } else if (asTex) {
      resolvedSemanticsLabel = semantics.functionLabel(label!);
    } else if (label == '.') {
      resolvedSemanticsLabel = decimalSeparator(context);
    } else {
      // Speak the inserted token (e.g. "times" for ×, "minus" for −) rather
      // than the raw glyph, so the announcement is reliable and localizable.
      resolvedSemanticsLabel = semantics.tokenLabel(value ?? label!);
    }

    return Expanded(
      flex: flex ?? 2,
      child: KeyboardButton(
        onTap: onTap,
        keyStyle: style.keyStyle(tier),
        borderRadius: style.keyBorderRadius,
        padding: style.keyPadding,
        focusColor: style.focusBorderColor,
        focusWidth: style.focusBorderWidth,
        semanticsLabel: resolvedSemanticsLabel,
        // Icon-only keys (submit, page toggle) do not get a magnified popup;
        // text and typeset keys show an enlarged label on long-press when the
        // viewer is enabled.
        largeContent:
            enableLargeContentViewer &&
                style.largeContentViewerEnabled &&
                label != null
            ? _label(context, fontSize * style.largeContentLabelScale)
            : null,
        largeContentThreshold: style.largeContentViewerThreshold,
        child: _label(context, fontSize),
      ),
    );
  }
}

/// Keyboard button for navigation actions.
class _NavigationButton extends StatelessWidget {
  /// Constructs a [_NavigationButton].
  const _NavigationButton({
    Key? key,
    required this.flex,
    required this.tier,
    required this.style,
    required this.fontSize,
    this.icon,
    this.semanticsLabel,
    this.semanticsValue,
    this.onTap,
  }) : super(key: key);

  /// The flexible flex value.
  final int? flex;

  /// The color tier of this button.
  final MathKeyboardKeyTier tier;

  /// The resolved keyboard style.
  final MathKeyboardStyle style;

  /// The scaled size of the icon.
  final double fontSize;

  /// Icon to be shown.
  final IconData? icon;

  /// The semantics label describing this button.
  final String? semanticsLabel;

  /// The semantics value describing this button's current state.
  final String? semanticsValue;

  /// Function used when user holds the button down.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex ?? 2,
      child: KeyboardButton(
        onTap: onTap,
        onHold: onTap,
        keyStyle: style.keyStyle(tier),
        borderRadius: style.keyBorderRadius,
        padding: style.keyPadding,
        focusColor: style.focusBorderColor,
        focusWidth: style.focusBorderWidth,
        semanticsLabel: semanticsLabel,
        semanticsValue: semanticsValue,
        child: Icon(icon, color: style.foregroundColor, size: fontSize),
      ),
    );
  }
}
