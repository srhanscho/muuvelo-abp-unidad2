import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// InfoBanner: soft colored box with an icon and a short explanation.
///
/// Parameters:
/// - [icon] / [title] / [message]: content.
/// - [color]: accent for the icon and title; [background] for the box.
///
/// Used in: HomeScreen (explains the problem, and the empty list) and
/// ResultsScreen (the "cuenta cerrada" state).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(color: AppColors.ink, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
