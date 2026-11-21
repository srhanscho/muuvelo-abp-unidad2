import 'package:flutter/material.dart';

/// MuuveloIcon: shows the custom illustration `assets/icons/<name>.png`
/// and, while that file does not exist yet, a Cupertino icon instead.
///
/// So the designer can drop the PNGs in `assets/icons/` later and they
/// appear everywhere WITHOUT changing code.
///
/// Parameters:
/// - [name]: file name without extension (e.g. 'empty_vacas', 'tab_home').
/// - [size]: width and height.
/// - [fallback]: icon used when the PNG is missing.
/// - [color]: tint of the fallback icon (the PNG keeps its own colors).
/// - [semanticLabel]: text read by screen readers.
///
/// Used in: login hero, empty states, sync badge, paid/pending chips,
/// edit/delete actions and the floating tab bar.
class MuuveloIcon extends StatelessWidget {
  const MuuveloIcon(
    this.name, {
    super.key,
    required this.fallback,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final IconData fallback;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$name.png',
      width: size,
      height: size,
      semanticLabel: semanticLabel,
      // The asset is missing (or broken): draw the vector icon instead.
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallback, size: size, color: color, semanticLabel: semanticLabel),
    );
  }
}
