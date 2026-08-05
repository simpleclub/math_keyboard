import 'package:flutter/services.dart';
import 'package:math_keyboard/src/foundation/node.dart';

/// Identifiers for the individual math tools (content buttons) that a
/// [MathKeyboard] can offer.
///
/// These are used with the `allowedTools` parameter of the keyboard widgets to
/// restrict which tools are shown (and typeable via a physical keyboard).
///
/// Note that the digits `0`-`9` are intentionally **not** part of this
/// enumeration: they are always available and cannot be disabled. Structural
/// keys (delete, navigation, submit and the page toggle) are likewise always
/// available.
enum MathKeyboardTool {
  /// The decimal separator (`.`).
  decimal,

  /// Addition (`+`).
  add,

  /// Subtraction (`−`).
  subtract,

  /// Multiplication (`×`).
  multiply,

  /// Division (`÷`), which inserts a fraction.
  divide,

  /// A fraction template (`\frac{\Box}{\Box}`).
  fraction,

  /// Square (`\Box^2`).
  square,

  /// Power / exponent (`\Box^{\Box}`).
  power,

  /// Square root (`\sqrt{\Box}`).
  sqrt,

  /// Nth root (`\sqrt[\Box]{\Box}`).
  nthRoot,

  /// Sine (`\sin`).
  sin,

  /// Inverse sine (`\sin^{-1}`).
  asin,

  /// Cosine (`\cos`).
  cos,

  /// Inverse cosine (`\cos^{-1}`).
  acos,

  /// Tangent (`\tan`).
  tan,

  /// Inverse tangent (`\tan^{-1}`).
  atan,

  /// Natural logarithm (`\ln`).
  ln,

  /// Logarithm with base (`\log_{\Box}`).
  log,

  /// Opening parenthesis (`(`).
  openParen,

  /// Closing parenthesis (`)`).
  closeParen,
}

/// Class representing a button configuration.
abstract class KeyboardButtonConfig {
  /// Constructs a [KeyboardButtonConfig].
  const KeyboardButtonConfig({
    this.flex,
    this.keyboardCharacters = const [],
  });

  /// Optional flex.
  final int? flex;

  /// The list of [KeyEvent.character] that should trigger this keyboard
  /// button on a physical keyboard.
  ///
  /// Note that the case of the characters is ignored.
  ///
  /// Special keyboard keys like backspace and arrow keys are specially handled
  /// and do *not* require this to be set.
  ///
  /// Must not be `null` but can be empty.
  final List<String> keyboardCharacters;
}

/// Class representing a button configuration for a [FunctionButton].
class BasicKeyboardButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [KeyboardButtonConfig].
  const BasicKeyboardButtonConfig({
    required this.label,
    required this.value,
    this.tool,
    this.args,
    this.asTex = false,
    this.highlighted = false,
    super.keyboardCharacters,
    super.flex,
  });

  /// The label of the button.
  final String label;

  /// The value in tex.
  final String value;

  /// The tool this button represents.
  ///
  /// Used to filter buttons via the keyboard's `allowedTools` parameter. A
  /// `null` value means the button is always shown and cannot be disabled
  /// (this is the case for the digits `0`-`9`).
  final MathKeyboardTool? tool;

  /// List defining the arguments for the function behind this button.
  final List<TeXArg>? args;

  /// Whether to display the label as TeX or as plain text.
  final bool asTex;

  /// The highlight level of this button.
  final bool highlighted;
}

/// Class representing a button configuration of the Delete Button.
class DeleteButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [DeleteButtonConfig].
  DeleteButtonConfig({super.flex});
}

/// Class representing a button configuration of the Previous Button.
class PreviousButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [DeleteButtonConfig].
  PreviousButtonConfig({super.flex});
}

/// Class representing a button configuration of the Next Button.
class NextButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [DeleteButtonConfig].
  NextButtonConfig({super.flex});
}

/// Class representing a button configuration of the Submit Button.
class SubmitButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [SubmitButtonConfig].
  SubmitButtonConfig({super.flex});
}

/// Class representing a button configuration of the Page Toggle Button.
class PageButtonConfig extends KeyboardButtonConfig {
  /// Constructs a [PageButtonConfig].
  const PageButtonConfig({super.flex});
}

/// List of keyboard button configs for the digits from 0-9.
///
/// List access from 0 to 9 will return the appropriate digit button.
final _digitButtons = [
  for (var i = 0; i < 10; i++)
    BasicKeyboardButtonConfig(
      label: '$i',
      value: '$i',
      keyboardCharacters: ['$i'],
    ),
];

const _decimalButton = BasicKeyboardButtonConfig(
  label: '.',
  value: '.',
  tool: MathKeyboardTool.decimal,
  keyboardCharacters: ['.', ','],
  highlighted: true,
);

const _subtractButton = BasicKeyboardButtonConfig(
  label: '−',
  value: '-',
  tool: MathKeyboardTool.subtract,
  keyboardCharacters: ['-'],
  highlighted: true,
);

/// Keyboard showing extended functionality.
final functionKeyboard = [
  [
    const BasicKeyboardButtonConfig(
      label: r'\frac{\Box}{\Box}',
      value: r'\frac',
      tool: MathKeyboardTool.fraction,
      args: [TeXArg.braces, TeXArg.braces],
      asTex: true,
    ),
    const BasicKeyboardButtonConfig(
      label: r'\Box^2',
      value: '^2',
      tool: MathKeyboardTool.square,
      args: [TeXArg.braces],
      asTex: true,
    ),
    const BasicKeyboardButtonConfig(
      label: r'\Box^{\Box}',
      value: '^',
      tool: MathKeyboardTool.power,
      args: [TeXArg.braces],
      asTex: true,
      keyboardCharacters: [
        '^',
        // This is a workaround for keyboard layout that use ^ as a toggle key.
        // In that case, "Dead" is reported as the character (e.g. for German
        // keyboards).
        'Dead',
      ],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\sin',
      value: r'\sin(',
      tool: MathKeyboardTool.sin,
      asTex: true,
      keyboardCharacters: ['s'],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\sin^{-1}',
      value: r'\sin^{-1}(',
      tool: MathKeyboardTool.asin,
      asTex: true,
    ),
  ],
  [
    const BasicKeyboardButtonConfig(
      label: r'\sqrt{\Box}',
      value: r'\sqrt',
      tool: MathKeyboardTool.sqrt,
      args: [TeXArg.braces],
      asTex: true,
      keyboardCharacters: ['r'],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\sqrt[\Box]{\Box}',
      value: r'\sqrt',
      tool: MathKeyboardTool.nthRoot,
      args: [TeXArg.brackets, TeXArg.braces],
      asTex: true,
    ),
    const BasicKeyboardButtonConfig(
      label: r'\cos',
      value: r'\cos(',
      tool: MathKeyboardTool.cos,
      asTex: true,
      keyboardCharacters: ['c'],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\cos^{-1}',
      value: r'\cos^{-1}(',
      tool: MathKeyboardTool.acos,
      asTex: true,
    ),
  ],
  [
    const BasicKeyboardButtonConfig(
      label: r'\log_{\Box}(\Box)',
      value: r'\log_',
      tool: MathKeyboardTool.log,
      asTex: true,
      args: [TeXArg.braces, TeXArg.parentheses],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\ln(\Box)',
      value: r'\ln(',
      tool: MathKeyboardTool.ln,
      asTex: true,
      keyboardCharacters: ['l'],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\tan',
      value: r'\tan(',
      tool: MathKeyboardTool.tan,
      asTex: true,
      keyboardCharacters: ['t'],
    ),
    const BasicKeyboardButtonConfig(
      label: r'\tan^{-1}',
      value: r'\tan^{-1}(',
      tool: MathKeyboardTool.atan,
      asTex: true,
    ),
  ],
  [
    const PageButtonConfig(flex: 3),
    const BasicKeyboardButtonConfig(
      label: '(',
      value: '(',
      tool: MathKeyboardTool.openParen,
      highlighted: true,
      keyboardCharacters: ['('],
    ),
    const BasicKeyboardButtonConfig(
      label: ')',
      value: ')',
      tool: MathKeyboardTool.closeParen,
      highlighted: true,
      keyboardCharacters: [')'],
    ),
    PreviousButtonConfig(),
    NextButtonConfig(),
    DeleteButtonConfig(),
  ],
];

/// Standard keyboard for math expression input.
final standardKeyboard = [
  [
    _digitButtons[7],
    _digitButtons[8],
    _digitButtons[9],
    const BasicKeyboardButtonConfig(
      label: '×',
      value: r'\cdot',
      tool: MathKeyboardTool.multiply,
      keyboardCharacters: ['*'],
      highlighted: true,
    ),
    const BasicKeyboardButtonConfig(
      label: '÷',
      value: r'\frac',
      tool: MathKeyboardTool.divide,
      keyboardCharacters: ['/'],
      args: [TeXArg.braces, TeXArg.braces],
      highlighted: true,
    ),
  ],
  [
    _digitButtons[4],
    _digitButtons[5],
    _digitButtons[6],
    const BasicKeyboardButtonConfig(
      label: '+',
      value: '+',
      tool: MathKeyboardTool.add,
      keyboardCharacters: ['+'],
      highlighted: true,
    ),
    _subtractButton,
  ],
  [
    _digitButtons[1],
    _digitButtons[2],
    _digitButtons[3],
    _decimalButton,
    DeleteButtonConfig(),
  ],
  [
    const PageButtonConfig(),
    _digitButtons[0],
    PreviousButtonConfig(),
    NextButtonConfig(),
    SubmitButtonConfig(),
  ],
];

/// Keyboard getting shown for number input only.
final numberKeyboard = [
  [
    _digitButtons[7],
    _digitButtons[8],
    _digitButtons[9],
    _subtractButton,
  ],
  [
    _digitButtons[4],
    _digitButtons[5],
    _digitButtons[6],
    _decimalButton,
  ],
  [
    _digitButtons[1],
    _digitButtons[2],
    _digitButtons[3],
    DeleteButtonConfig(),
  ],
  [
    PreviousButtonConfig(),
    _digitButtons[0],
    NextButtonConfig(),
    SubmitButtonConfig(),
  ],
];

/// Whether the given [config] should be shown for the given set of
/// [allowedTools].
///
/// A `null` [allowedTools] means that every tool is allowed. Structural buttons
/// (delete, navigation, submit, page toggle) and buttons without an associated
/// tool (i.e. the digits `0`-`9`) are always allowed.
bool isKeyboardButtonAllowed(
  KeyboardButtonConfig config,
  Set<MathKeyboardTool>? allowedTools,
) {
  if (allowedTools == null) return true;
  if (config is BasicKeyboardButtonConfig && config.tool != null) {
    return allowedTools.contains(config.tool);
  }
  return true;
}

/// Whether the given [layout] contains at least one content tool that is
/// permitted by [allowedTools].
///
/// This is used to decide whether a second keyboard page should be shown at
/// all.
bool layoutHasAllowedTool(
  List<List<KeyboardButtonConfig>> layout,
  Set<MathKeyboardTool>? allowedTools,
) {
  for (final row in layout) {
    for (final config in row) {
      if (config is BasicKeyboardButtonConfig && config.tool != null) {
        if (allowedTools == null || allowedTools.contains(config.tool)) {
          return true;
        }
      }
    }
  }
  return false;
}

/// Filters and compacts the given keyboard [layout] for the set of
/// [allowedTools].
///
/// Buttons whose tool is not allowed are dropped, the remaining buttons in a
/// row expand to fill the gap (via their existing flex), and rows that become
/// completely empty are removed. When [removePageButton] is `true`, the page
/// toggle button is also stripped (used when there is no second page to toggle
/// to).
List<List<KeyboardButtonConfig>> filterKeyboardLayout(
  List<List<KeyboardButtonConfig>> layout,
  Set<MathKeyboardTool>? allowedTools, {
  bool removePageButton = false,
}) {
  final result = <List<KeyboardButtonConfig>>[];
  for (final row in layout) {
    final filteredRow = <KeyboardButtonConfig>[];
    for (final config in row) {
      if (removePageButton && config is PageButtonConfig) continue;
      if (!isKeyboardButtonAllowed(config, allowedTools)) continue;
      filteredRow.add(config);
    }
    if (filteredRow.isEmpty) continue;
    result.add(filteredRow);
  }
  return result;
}
