import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CustomTextField: the ONE text input used across the app.
///
/// It wraps a [TextFormField] so every field looks the same (rounded white
/// box with an icon) and so validation rules are plugged in from outside.
///
/// Parameters:
/// - [label] / [icon] / [hint]: what the user sees.
/// - [controller]: holds the typed text (owned by the screen).
/// - [validator]: a pure function from `utils/validators.dart`; runs when
///   the parent `Form` calls `validate()`.
/// - [errorText]: an error decided by the screen (e.g. duplicate name).
/// - [keyboardType] / [inputFormatters] / [maxLength]: limit what can be typed.
/// - [textInputAction] / [onSubmitted]: what the keyboard "enter" key does.
///
/// Used in: RegisterScreen (restaurant name), ParticipantsEditor (person
/// name) and AddItemDialog (description and price).
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.hint,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      textCapitalization: keyboardType == null ? TextCapitalization.sentences : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        errorText: errorText,
        // Hide the "0/40" counter: the validator already explains the limit.
        counterText: '',
      ),
    );
  }
}
