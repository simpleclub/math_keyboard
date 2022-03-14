import 'package:flutter/material.dart';
import 'package:math_keyboard/src/widgets/math_field.dart';
import 'package:math_keyboard/src/widgets/math_keyboard.dart';

/// A [FormField] that contains a [MathField].
///
/// This is a convenience widget that wraps a [MathField] widget in a
/// [FormField].
///
/// A [Form] ancestor is not required. The [Form] simply makes it easier to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// See also:
///
///  * [MathField], which is the underlying math field without the [Form]
///    integration.
///  * [InputDecorator], which shows the labels and other visual elements that
///    surround the actual text editing widget.
class MathFormField extends FormField<String> {
  /// Creates a [FormField] that contains a [MathField].
  MathFormField({
    Key? key,
    this.controller,
    FocusNode? focusNode,
    InputDecoration decoration = const InputDecoration(),
    MathKeyboardType keyboardType = MathKeyboardType.expression,
    List<String> variables = const [],
    bool autofocus = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    FormFieldValidator<String>? validator,
  }) : super(
          key: key,
          initialValue:
              controller != null ? controller.currentEditingValue() : '',
          validator: validator,
          autovalidateMode: autovalidateMode,
          builder: (FormFieldState<String> field) {
            final state = field as _MathFormFieldState;

            void onChangedHandler(String value) {
              field.didChange(value);
              if (onChanged != null) {
                onChanged(value);
              }
            }

            return MathField(
              controller: state._controller,
              focusNode: focusNode,
              decoration: decoration.copyWith(errorText: field.errorText),
              keyboardType: keyboardType,
              variables: variables,
              autofocus: autofocus,
              onChanged: onChangedHandler,
              onSubmitted: onFieldSubmitted,
            );
          },
        );

  /// Controls the math input being edited.
  ///
  /// If null, this widget will create its own [MathFieldEditingController].
  final MathFieldEditingController? controller;

  @override
  _MathFormFieldState createState() => _MathFormFieldState();
}

class _MathFormFieldState extends FormFieldState<String> {
  late MathFieldEditingController _controller;

  @override
  MathFormField get widget => super.widget as MathFormField;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _controller = MathFieldEditingController();
    } else {
      _controller = widget.controller!;
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(MathFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        widget.controller!.addListener(_handleControllerChanged);
        _controller = widget.controller!;
      } else if (widget.controller == null) {
        oldWidget.controller!.removeListener(_handleControllerChanged);
        _controller = MathFieldEditingController();
      } else {
        oldWidget.controller!.removeListener(_handleControllerChanged);
        widget.controller!.addListener(_handleControllerChanged);
        _controller = widget.controller!;
      }
      setValue(_controller.currentEditingValue());
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);

    // todo: allow changing the value from outside of the controller.
  }

  @override
  void reset() {
    // setState will be called in the superclass, so even though state is being
    // manipulated, no setState call is needed here.
    _controller.clear();
    super.reset();
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we
    // register this change listener. In these cases, we'll also receive change
    // notifications for changes originating from within this class -- for
    // example, the reset() method. In such cases, the FormField value will
    // already have been set.
    if (_controller.currentEditingValue() != value) {
      didChange(_controller.currentEditingValue());
    }
  }
}
