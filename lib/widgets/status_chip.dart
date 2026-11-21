import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/design_tokens.dart';

/// StatusChip: tiny colored pill with a short state, like "Pagó" or
/// "Pendiente".
///
/// Parameters:
/// - [label]: the text.
/// - [color]: text / icon color; [background]: pill color.
/// - [icon]: optional leading widget (e.g. a MuuveloIcon).
///
/// Named constructors keep the same colors everywhere.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, required this.background, this.icon});

  const StatusChip.paid({super.key, this.icon, this.label = 'Pagó'})
    : color = AppColors.success,
      background = AppColors.successSoft;

  const StatusChip.pending({super.key, this.icon, this.label = 'Pendiente'})
    : color = AppColors.pending,
      background = AppColors.pendingSoft;

  const StatusChip.open({super.key, this.icon, this.label = 'Abierta'})
    : color = AppColors.primary,
      background = AppColors.primarySoft;

  const StatusChip.closed({super.key, this.icon, this.label = 'Cerrada'})
    : color = AppColors.muted,
      background = AppColors.fill;

  final String label;
  final Color color;
  final Color background;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: Radii.smallAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: Space.xs)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
