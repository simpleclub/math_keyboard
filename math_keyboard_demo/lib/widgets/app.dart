import 'package:flutter/material.dart';
import 'package:math_keyboard_demo/data/strings.dart';
import 'package:math_keyboard_demo/widgets/editable_mixed_text_field.dart';
import 'package:math_keyboard_demo/widgets/scaffold.dart';

/// Demo application for `math_keyboard`.
class DemoApp extends StatefulWidget {
  /// Constructs a [DemoApp].
  const DemoApp({Key? key}) : super(key: key);

  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  var _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: EditableMixedTextField(),
    );
  }
}
