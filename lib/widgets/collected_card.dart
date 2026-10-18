import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'glass_progress.dart';
import 'money_text.dart';
import 'status_chip.dart';

/// CollectedCard: the big glass plus "how much has been collected".
///
/// Parameters:
/// - [collected] / [total]: pesos.
/// - [percent]: 0..100, passed to [GlassProgress].
/// - [paidCount] / [peopleCount]: e.g. "2 de 3 pagaron".
/// - [isClosed]: changes the caption to "Cerrada con" once the account is
///   closed (PRD: closing with what was collected is valid).
///
/// Used in: ResultsScreen (open and closed configurations).
class CollectedCard extends StatelessWidget {
  const CollectedCard({
    super.key,
    required this.collected,
    required this.total,
    required this.percent,
    required this.paidCount,
    required this.peopleCount,
    required this.isClosed,
  });

  final int collected;
  final int total;
  final int percent;
  final int paidCount;
  final int peopleCount;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GlassProgress(percent: percent, width: 96, height: 124),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isClosed ? 'CERRADA CON' : 'RECOGIDO',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MoneyText(
                      collected,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Row(
                    children: [
                      const Text('de ', style: TextStyle(color: AppColors.muted)),
                      Flexible(
                        child: MoneyText(total, style: const TextStyle(color: AppColors.muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatusChip(
                    label: '$paidCount de $peopleCount pagaron',
                    color: AppColors.primary,
                    background: AppColors.primarySoft,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
