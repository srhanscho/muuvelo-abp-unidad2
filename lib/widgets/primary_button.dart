import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// PrimaryButton: the full-width, 50 px tall filled button of each screen
/// (only one per screen). While [loading] it shows a spinner and ignores
/// taps, so a slow network cannot create the same vaca twice.
///
/// Parameters:
/// - [label] / [icon]: content.
/// - [onPressed]: null disables the button.
/// - [loading]: shows the activity indicator.
/// - [background] / [foreground]: override the purple tint (the gold
///   "Cerrar y cobrar" button).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.background = AppColors.primary,
    this.foreground = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.4),
        disabledForegroundColor: foreground.withValues(alpha: 0.8),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? CupertinoActivityIndicator(color: foreground)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.s)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

/// PlainButton: secondary action drawn as tinted text (iOS plain button).
class PlainButton extends StatelessWidget {
  const PlainButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: tint, minimumSize: const Size.fromHeight(48)),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.s)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
