import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// CustomTextField: the ONE text input used across the app, iOS style
/// (small label above, light gray filled box, no outline).
///
/// It wraps a [TextFormField] so every field looks the same and so the
/// validation rules are plugged in from outside.
///
/// Parameters:
/// - [label] / [icon] / [hint]: what the user sees.
/// - [controller]: holds the typed text (owned by the screen).
/// - [validator]: a pure function from `utils/validators.dart`.
/// - [errorText]: an error decided by the screen (e.g. duplicate name).
/// - [keyboardType] / [inputFormatters] / [maxLength]: limit what can be typed.
/// - [obscure]: password field; adds a show/hide eye button.
/// - [autofillHints]: lets the OS password manager help.
/// - [textInputAction] / [onSubmitted]: what the keyboard "enter" key does.
class CustomTextField extends StatefulWidget {
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
    this.obscure = false,
    this.autofillHints,
    this.textCapitalization,
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
  final bool obscure;
  final Iterable<String>? autofillHints;
  final TextCapitalization? textCapitalization;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Space.xs, bottom: 6),
          child: Text(widget.label, style: AppText.footnote.copyWith(fontWeight: FontWeight.w500)),
        ),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          obscureText: _hidden,
          autofillHints: widget.autofillHints,
          autocorrect: !widget.obscure,
          enableSuggestions: !widget.obscure,
          style: AppText.body,
          cursorColor: AppColors.primary,
          textCapitalization:
              widget.textCapitalization ??
              (widget.keyboardType == null ? TextCapitalization.sentences : TextCapitalization.none),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, color: AppColors.muted, size: 20),
            errorText: widget.errorText,
            errorMaxLines: 2,
            // Hide the "0/40" counter: the validator already explains the limit.
            counterText: '',
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(_hidden ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: AppColors.muted),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
