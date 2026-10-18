import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'glass_progress.dart';
import 'money_text.dart';
import 'status_chip.dart';

/// VacaTile: one row of the "vacas de esta sesión" list on the home screen.
///
/// Parameters:
/// - [title] / [subtitle]: restaurant and "3 personas".
/// - [collected] / [total] / [percent]: progress of the payments.
/// - [isClosed]: shows "Cerrada" or "Abierta".
/// - [onTap]: opens the results of this vaca (decided by the screen).
///
/// Used in: HomeScreen, once per vaca (open and closed configurations).
class VacaTile extends StatelessWidget {
  const VacaTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.collected,
    required this.total,
    required this.percent,
    required this.isClosed,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int collected;
  final int total;
  final int percent;
  final bool isClosed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GlassProgress(percent: percent, width: 34, height: 44, showLabel: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    isClosed
                        ? const StatusChip(
                            label: 'Cerrada',
                            color: AppColors.muted,
                            background: AppColors.border,
                          )
                        : const StatusChip(
                            label: 'Abierta',
                            color: AppColors.success,
                            background: AppColors.successSoft,
                          ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(collected, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('$percent%', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
