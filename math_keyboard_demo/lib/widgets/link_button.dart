import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stylized button widget for linking to outside resources.
class LinkButton extends StatelessWidget {
  /// Constructs a [LinkButton] from a [label], a [url], and an optional
  /// [child].
  const LinkButton({
    Key? key,
    required this.label,
    required this.url,
    this.child,
  }) : super(key: key);

  /// Label for the button.
  final String label;

  /// URL to link to, i.e. to open.
  final String url;

  /// Icon for this button.
  ///
  /// Can be left null.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    void onPressed() => launch(url);
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(16),
      textStyle: TextStyle(
        fontSize: 20,
        decoration: TextDecoration.underline,
      ),
    );

    if (child == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      label: Text(label),
      icon: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 32,
        ),
        child: child,
      ),
    );
  }
}
