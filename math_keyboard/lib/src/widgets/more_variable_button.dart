import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/src/widgets/keyboard_button.dart';
import 'package:math_keyboard/src/widgets/math_field.dart';
import 'package:math_keyboard/src/widgets/math_keyboard_theme.dart';

/// Button that opens an overlay with additional mathematical symbols.
class MoreVariableButton extends StatefulWidget {
  /// Constructs a [MoreVariableButton].
  const MoreVariableButton({
    Key? key,
    required this.controller,
    required this.style,
    required this.fontSize,
    required this.keyHeight,
  }) : super(key: key);

  /// The editing controller for the math field.
  final MathFieldEditingController controller;

  /// The resolved keyboard style.
  final MathKeyboardStyle style;

  /// The font size for labels.
  final double fontSize;

  /// The key height.
  final double keyHeight;

  @override
  _MoreVariableButtonState createState() => _MoreVariableButtonState();
}

class _MoreVariableButtonState extends State<MoreVariableButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  static const List<String> _overlayItems = [
    // Basic Mathematical Symbols
    '±', '=', '≠', '<', '>', '≤', '≥',
    // Set Theory
    '∅', '∈', '∉', '∋', '∌', '∪', '∩', '⊂', '⊃', '⊆', '⊇',
    // Logic
    '¬', '∧', '∨', '⇒', '⇔', '⊥', '⊤', '∼',
    // Calculus
    '∞',
    // Relations
    '∝',
    // Arrows
    '→', '←', '↑', '↓', '↔', '⇒', '⇔',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _dismissOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    final buttonBox = context.findRenderObject() as RenderBox;
    final buttonPos = buttonBox.localToGlobal(Offset.zero);
    final topOffset = buttonPos.dy + 45;

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - topOffset;

    // Update height animation
    _heightAnimation = Tween<double>(begin: 0, end: availableHeight).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(topOffset),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Wait for the next frame before starting animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  Widget _buildOverlay(double topOffset) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: _heightAnimation.value,
              decoration: BoxDecoration(
                color: widget.style.backgroundColor,
                borderRadius: widget.style.borderRadius,
                boxShadow: widget.style.boxShadow,
              ),
              child: child,
            );
          },
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Wrap(
                children: _overlayItems
                    .map(
                      (element) => SizedBox(
                        width: 56,
                        height: 56,
                        child: KeyboardButton(
                          keyStyle: widget.style.neutralKey,
                          borderRadius: widget.style.keyBorderRadius,
                          padding: widget.style.keyPadding,
                          focusColor: widget.style.focusBorderColor,
                          focusWidth: widget.style.focusBorderWidth,
                          onTap: () => widget.controller.addLeaf('{$element}'),
                          child: Math.tex(
                            element,
                            options: MathOptions(
                              fontSize: widget.fontSize,
                              color: widget.style.foregroundColor,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dismissOverlay() async {
    await _controller.reverse();
    _removeOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.keyHeight,
      height: widget.keyHeight,
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.style.utilityKey.color,
            borderRadius: widget.style.keyBorderRadius,
          ),
          child: Center(
            child: Text(
              '...',
              style: TextStyle(
                color: widget.style.foregroundColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
