import 'package:flutter/foundation.dart';

/// Describes the screen-reader (accessibility) strings of a math keyboard and
/// its math field.
///
/// Every string is an English default via [fallback]. Provide a customized
/// instance through a `MathKeyboardTheme` (or the `semantics` argument of a
/// `MathField`) to localize the spoken announcements or adapt them to a
/// product's terminology. This is the intended localization seam: the package
/// itself ships no translations.
///
/// Some announcements are dynamic (they embed a variable name or the token next
/// to the cursor), so they are exposed as builder callbacks rather than plain
/// strings. Typeset labels are resolved from the ordered [functionMappings] and
/// [tokenMappings] so that a localized instance can rename, for example, "sine"
/// to "Sinus".
///
/// Equality compares these callbacks by identity. Prefer **stable** function
/// references (top-level or static functions, or an instance stored in a field)
/// for the builder fields. Passing fresh inline closures on every `build`
/// (`variableLabel: (n) => …`) creates a new, unequal instance each frame,
/// which makes a `MathKeyboardTheme` notify and rebuild its dependents every
/// time. The English defaults already use stable references.
@immutable
class MathKeyboardSemantics {
  /// Constructs a [MathKeyboardSemantics].
  const MathKeyboardSemantics({
    required this.deleteLabel,
    required this.submitLabel,
    required this.showNumbersKeyboardLabel,
    required this.showFunctionsKeyboardLabel,
    required this.keyboardGroupLabel,
    required this.variablesGroupLabel,
    required this.functionsGroupLabel,
    required this.numbersGroupLabel,
    required this.moveCursorLeftLabel,
    required this.moveCursorRightLabel,
    required this.mathFieldLabel,
    required this.emptyLabel,
    required this.expressionContainerLabel,
    required this.numeratorLabel,
    required this.denominatorLabel,
    required this.exponentLabel,
    required this.rootIndexLabel,
    required this.underRootLabel,
    required this.underSquareRootLabel,
    required this.logBaseLabel,
    required this.logArgumentLabel,
    required this.insideParenthesesLabel,
    required this.variableLabel,
    required this.beforeToken,
    required this.startOfContainer,
    required this.endOfContainer,
    required this.functionMappings,
    required this.tokenMappings,
  });

  /// The label of the backspace key.
  final String deleteLabel;

  /// The label of the submit key.
  final String submitLabel;

  /// The label of the page toggle while the functions page is showing.
  final String showNumbersKeyboardLabel;

  /// The label of the page toggle while the numbers page is showing.
  final String showFunctionsKeyboardLabel;

  /// The accessibility label of the group wrapping the whole keyboard.
  final String keyboardGroupLabel;

  /// The accessibility label of the group holding the variable keys.
  final String variablesGroupLabel;

  /// The accessibility label of the group holding the typeset function keys.
  final String functionsGroupLabel;

  /// The accessibility label of the group holding the number and operator keys.
  final String numbersGroupLabel;

  /// The label of the key that moves the cursor to the left.
  final String moveCursorLeftLabel;

  /// The label of the key that moves the cursor to the right.
  final String moveCursorRightLabel;

  /// The label describing the math field itself, used when the field's
  /// decoration provides neither a label nor a hint.
  final String mathFieldLabel;

  /// The word describing an empty container at the cursor, such as a freshly
  /// inserted, still-empty fraction numerator.
  final String emptyLabel;

  /// The name of the top-level container (the whole expression).
  final String expressionContainerLabel;

  /// The name of a fraction's numerator container.
  final String numeratorLabel;

  /// The name of a fraction's denominator container.
  final String denominatorLabel;

  /// The name of an exponent container.
  final String exponentLabel;

  /// The name of an nth root's index container.
  final String rootIndexLabel;

  /// The name of an nth root's radicand container.
  final String underRootLabel;

  /// The name of a square root's radicand container.
  final String underSquareRootLabel;

  /// The name of a logarithm's base container.
  final String logBaseLabel;

  /// The name of a logarithm's argument container.
  final String logArgumentLabel;

  /// The name of a generic parenthesized container.
  final String insideParenthesesLabel;

  /// Builds the label of a variable key for the variable [name].
  final String Function(String name) variableLabel;

  /// Builds the cursor announcement stating the cursor sits before [token].
  final String Function(String token) beforeToken;

  /// Builds the cursor announcement for the leading boundary of [container].
  final String Function(String container) startOfContainer;

  /// Builds the cursor announcement for the trailing boundary of [container].
  final String Function(String container) endOfContainer;

  /// The ordered TeX fragment → spoken label mappings for typeset function
  /// labels and expressions.
  ///
  /// Order matters: more specific fragments must precede their base forms (for
  /// example the inverse trigonometric functions before the plain ones, and the
  /// nth root before the square root).
  final List<(String, String)> functionMappings;

  /// The TeX token → spoken word mappings for single leaves, such as operators
  /// and constants.
  final Map<String, String> tokenMappings;

  /// Returns a spoken description for a typeset function [tex] label or
  /// expression.
  ///
  /// Falls back to stripping the TeX control characters when no mapping matches.
  String functionLabel(String tex) {
    for (final (fragment, spoken) in functionMappings) {
      if (tex.contains(fragment)) return spoken;
    }
    return tex
        .replaceAll(r'\Box', '')
        .replaceAll(RegExp(r'[\\{}\[\]^]'), '')
        .trim();
  }

  /// Returns a spoken description for a single leaf [tex] token, such as a
  /// digit, operator, or variable.
  String tokenLabel(String tex) {
    final mapped = tokenMappings[tex];
    if (mapped != null) return mapped;
    // Variables are stored wrapped in braces, e.g. "{x}".
    return tex.replaceAll(RegExp(r'[{}]'), '');
  }

  /// The default, English strings.
  static const MathKeyboardSemantics fallback = MathKeyboardSemantics(
    deleteLabel: 'Delete',
    submitLabel: 'Submit',
    showNumbersKeyboardLabel: 'Show numbers keyboard',
    showFunctionsKeyboardLabel: 'Show formula keyboard',
    keyboardGroupLabel: 'Math keyboard',
    variablesGroupLabel: 'Variables',
    functionsGroupLabel: 'Formula',
    numbersGroupLabel: 'Numbers',
    moveCursorLeftLabel: 'Move cursor left',
    moveCursorRightLabel: 'Move cursor right',
    mathFieldLabel: 'Math field',
    emptyLabel: 'empty',
    expressionContainerLabel: 'expression',
    numeratorLabel: 'numerator',
    denominatorLabel: 'denominator',
    exponentLabel: 'exponent',
    rootIndexLabel: 'root index',
    underRootLabel: 'under the root',
    underSquareRootLabel: 'under the square root',
    logBaseLabel: 'base',
    logArgumentLabel: 'argument',
    insideParenthesesLabel: 'inside parentheses',
    variableLabel: _defaultVariableLabel,
    beforeToken: _defaultBeforeToken,
    startOfContainer: _defaultStartOfContainer,
    endOfContainer: _defaultEndOfContainer,
    functionMappings: _defaultFunctionMappings,
    tokenMappings: _defaultTokenMappings,
  );

  static String _defaultVariableLabel(String name) => 'Variable $name';

  static String _defaultBeforeToken(String token) => 'before $token';

  static String _defaultStartOfContainer(String container) =>
      'start of $container';

  static String _defaultEndOfContainer(String container) => 'end of $container';

  static const List<(String, String)> _defaultFunctionMappings = [
    (r'\frac', 'fraction'),
    (r'\sqrt[', 'nth root'),
    (r'\sqrt', 'square root'),
    (r'\sin^{-1}', 'inverse sine'),
    (r'\sin', 'sine'),
    (r'\cos^{-1}', 'inverse cosine'),
    (r'\cos', 'cosine'),
    (r'\tan^{-1}', 'inverse tangent'),
    (r'\tan', 'tangent'),
    (r'\log', 'logarithm'),
    (r'\ln', 'natural logarithm'),
    (r'^2', 'square'),
    (r'^', 'power'),
  ];

  static const Map<String, String> _defaultTokenMappings = {
    r'\cdot': 'times',
    r'\div': 'divided by',
    // The division key inserts a fraction, so its inserted token is `\frac`.
    r'\frac': 'divided by',
    r'\pi': 'pi',
    '+': 'plus',
    '-': 'minus',
    '(': 'open parenthesis',
    ')': 'close parenthesis',
  };

  /// Creates a copy of these semantics with the given fields replaced.
  MathKeyboardSemantics copyWith({
    String? deleteLabel,
    String? submitLabel,
    String? showNumbersKeyboardLabel,
    String? showFunctionsKeyboardLabel,
    String? keyboardGroupLabel,
    String? variablesGroupLabel,
    String? functionsGroupLabel,
    String? numbersGroupLabel,
    String? moveCursorLeftLabel,
    String? moveCursorRightLabel,
    String? mathFieldLabel,
    String? emptyLabel,
    String? expressionContainerLabel,
    String? numeratorLabel,
    String? denominatorLabel,
    String? exponentLabel,
    String? rootIndexLabel,
    String? underRootLabel,
    String? underSquareRootLabel,
    String? logBaseLabel,
    String? logArgumentLabel,
    String? insideParenthesesLabel,
    String Function(String name)? variableLabel,
    String Function(String token)? beforeToken,
    String Function(String container)? startOfContainer,
    String Function(String container)? endOfContainer,
    List<(String, String)>? functionMappings,
    Map<String, String>? tokenMappings,
  }) {
    return MathKeyboardSemantics(
      deleteLabel: deleteLabel ?? this.deleteLabel,
      submitLabel: submitLabel ?? this.submitLabel,
      showNumbersKeyboardLabel:
          showNumbersKeyboardLabel ?? this.showNumbersKeyboardLabel,
      showFunctionsKeyboardLabel:
          showFunctionsKeyboardLabel ?? this.showFunctionsKeyboardLabel,
      keyboardGroupLabel: keyboardGroupLabel ?? this.keyboardGroupLabel,
      variablesGroupLabel: variablesGroupLabel ?? this.variablesGroupLabel,
      functionsGroupLabel: functionsGroupLabel ?? this.functionsGroupLabel,
      numbersGroupLabel: numbersGroupLabel ?? this.numbersGroupLabel,
      moveCursorLeftLabel: moveCursorLeftLabel ?? this.moveCursorLeftLabel,
      moveCursorRightLabel: moveCursorRightLabel ?? this.moveCursorRightLabel,
      mathFieldLabel: mathFieldLabel ?? this.mathFieldLabel,
      emptyLabel: emptyLabel ?? this.emptyLabel,
      expressionContainerLabel:
          expressionContainerLabel ?? this.expressionContainerLabel,
      numeratorLabel: numeratorLabel ?? this.numeratorLabel,
      denominatorLabel: denominatorLabel ?? this.denominatorLabel,
      exponentLabel: exponentLabel ?? this.exponentLabel,
      rootIndexLabel: rootIndexLabel ?? this.rootIndexLabel,
      underRootLabel: underRootLabel ?? this.underRootLabel,
      underSquareRootLabel: underSquareRootLabel ?? this.underSquareRootLabel,
      logBaseLabel: logBaseLabel ?? this.logBaseLabel,
      logArgumentLabel: logArgumentLabel ?? this.logArgumentLabel,
      insideParenthesesLabel:
          insideParenthesesLabel ?? this.insideParenthesesLabel,
      variableLabel: variableLabel ?? this.variableLabel,
      beforeToken: beforeToken ?? this.beforeToken,
      startOfContainer: startOfContainer ?? this.startOfContainer,
      endOfContainer: endOfContainer ?? this.endOfContainer,
      functionMappings: functionMappings ?? this.functionMappings,
      tokenMappings: tokenMappings ?? this.tokenMappings,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MathKeyboardSemantics &&
        other.deleteLabel == deleteLabel &&
        other.submitLabel == submitLabel &&
        other.showNumbersKeyboardLabel == showNumbersKeyboardLabel &&
        other.showFunctionsKeyboardLabel == showFunctionsKeyboardLabel &&
        other.keyboardGroupLabel == keyboardGroupLabel &&
        other.variablesGroupLabel == variablesGroupLabel &&
        other.functionsGroupLabel == functionsGroupLabel &&
        other.numbersGroupLabel == numbersGroupLabel &&
        other.moveCursorLeftLabel == moveCursorLeftLabel &&
        other.moveCursorRightLabel == moveCursorRightLabel &&
        other.mathFieldLabel == mathFieldLabel &&
        other.emptyLabel == emptyLabel &&
        other.expressionContainerLabel == expressionContainerLabel &&
        other.numeratorLabel == numeratorLabel &&
        other.denominatorLabel == denominatorLabel &&
        other.exponentLabel == exponentLabel &&
        other.rootIndexLabel == rootIndexLabel &&
        other.underRootLabel == underRootLabel &&
        other.underSquareRootLabel == underSquareRootLabel &&
        other.logBaseLabel == logBaseLabel &&
        other.logArgumentLabel == logArgumentLabel &&
        other.insideParenthesesLabel == insideParenthesesLabel &&
        other.variableLabel == variableLabel &&
        other.beforeToken == beforeToken &&
        other.startOfContainer == startOfContainer &&
        other.endOfContainer == endOfContainer &&
        listEquals(other.functionMappings, functionMappings) &&
        mapEquals(other.tokenMappings, tokenMappings);
  }

  @override
  int get hashCode => Object.hashAll([
    deleteLabel,
    submitLabel,
    showNumbersKeyboardLabel,
    showFunctionsKeyboardLabel,
    keyboardGroupLabel,
    variablesGroupLabel,
    functionsGroupLabel,
    numbersGroupLabel,
    moveCursorLeftLabel,
    moveCursorRightLabel,
    mathFieldLabel,
    emptyLabel,
    expressionContainerLabel,
    numeratorLabel,
    denominatorLabel,
    exponentLabel,
    rootIndexLabel,
    underRootLabel,
    underSquareRootLabel,
    logBaseLabel,
    logArgumentLabel,
    insideParenthesesLabel,
    variableLabel,
    beforeToken,
    startOfContainer,
    endOfContainer,
    Object.hashAll(functionMappings),
    Object.hashAll(
      tokenMappings.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  ]);
}
