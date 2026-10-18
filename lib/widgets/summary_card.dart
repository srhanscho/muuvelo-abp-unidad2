import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'money_text.dart';

/// SummaryCard: white card with subtotal, tip and the big total.
///
/// Parameters:
/// - [title]: main line (restaurant name or "Vista previa").
/// - [subtitle]: optional second line (e.g. "3 personas").
/// - [subtotal] / [tip] / [tipPercent] / [total]: amounts in pesos.
///
/// Used in: RegisterScreen (live preview that updates while typing) and
/// ResultsScreen (final summary of the vaca).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.subtotal,
    required this.tip,
    required this.tipPercent,
    required this.total,
  });

  final String title;
  final String? subtitle;
  final int subtotal;
  final int tip;
  final int tipPercent;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            _AmountRow(label: 'Subtotal', pesos: subtotal),
            _AmountRow(label: 'Propina ($tipPercent%)', pesos: tip),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
                MoneyText(total, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One "label ...... amount" line inside the card.
class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.pesos});

  final String label;
  final int pesos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          MoneyText(pesos, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
