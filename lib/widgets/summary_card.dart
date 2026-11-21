import 'package:flutter/material.dart';

import '../utils/design_tokens.dart';
import 'grouped_section.dart';
import 'money_text.dart';

/// SummaryCard: the big total first (most important number), then the
/// subtotal and tip as quiet rows.
///
/// Parameters:
/// - [title]: restaurant name; [subtitle]: e.g. "3 personas · 2 ítems".
/// - [subtotal] / [tip] / [tipPercent] / [total]: amounts in pesos.
/// - [header]: optional uppercase header above the section.
///
/// Used in: Registro / Edición (live preview) and Detalle.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.subtotal,
    required this.tip,
    required this.tipPercent,
    required this.total,
    this.header,
  });

  final String title;
  final String? subtitle;
  final int subtotal;
  final int tip;
  final int tipPercent;
  final int total;
  final String? header;

  @override
  Widget build(BuildContext context) {
    return GroupedSection(
      header: header,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.headline, overflow: TextOverflow.ellipsis),
              if (subtitle != null) Text(subtitle!, style: AppText.footnote),
              const SizedBox(height: Space.m),
              const Text('Total', style: AppText.subheadline),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MoneyText(total, style: AppText.moneyHero),
              ),
            ],
          ),
        ),
        _AmountRow(label: 'Subtotal', pesos: subtotal),
        _AmountRow(label: 'Propina ($tipPercent%)', pesos: tip),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.pesos});

  final String label;
  final int pesos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          MoneyText(pesos, style: AppText.body.copyWith(color: AppText.subheadline.color)),
        ],
      ),
    );
  }
}
