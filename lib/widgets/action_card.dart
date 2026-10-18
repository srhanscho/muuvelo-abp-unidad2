import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// ActionCard: big tappable card with an icon, a title and a subtitle,
/// like "Foto al recibo" in the design.
///
/// Parameters:
/// - [icon] / [title] / [subtitle]: content.
/// - [onTap]: what to do when tapped; `null` draws the card DISABLED
///   (greyed out) so the subtitle can explain why.
/// - [highlighted]: purple filled (main action) or white (secondary).
///
/// Used in: HomeScreen for "Nueva vaca" (highlighted) and "Ver resultados"
/// (white, disabled until a vaca exists).
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final background = highlighted ? AppColors.primary : AppColors.surface;
    final foreground = highlighted ? Colors.white : AppColors.ink;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: highlighted ? null : Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: highlighted ? Colors.white.withValues(alpha: 0.18) : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: highlighted ? Colors.white : AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: foreground.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (enabled) Icon(Icons.chevron_right, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
