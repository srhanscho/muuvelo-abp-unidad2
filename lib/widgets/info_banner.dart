import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// InfoBanner: soft colored box with an icon and a short explanation.
///
/// Parameters:
/// - [icon]: any widget (Icon or MuuveloIcon).
/// - [title] / [message]: content.
/// - [color]: accent for the title; [background] for the box.
///
/// Used in: Edición (paid people warning), Gestión (closed state), Inicio.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  final Widget icon;
  final String title;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.l),
      decoration: BoxDecoration(color: background, borderRadius: Radii.largeAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTheme(data: IconThemeData(color: color, size: 22), child: icon),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.headline.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(message, style: AppText.subheadline.copyWith(color: AppColors.ink, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
