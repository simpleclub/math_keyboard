import 'package:flutter/material.dart';
import 'package:math_keyboard/src/foundation/keyboard_button.dart';

/// Defines the layout and options for a page of buttons on the keyboard.
class CustomButtonPage {
  /// Defines the layout of the buttons on the page.
  final List<List<KeyboardButtonConfig>> buttonLayout;

  /// An optional label to help users identify this page.
  final String? label;

  /// An optional icon to help users identify this page. If both an icon and
  /// label are provided, the icon will be preferred.
  final IconData? icon;

  /// Defines a custom button page, optionally including a label or icon
  /// that represent the contents of the page.
  const CustomButtonPage({
    required this.buttonLayout,
    this.label,
    this.icon,
  });
}
