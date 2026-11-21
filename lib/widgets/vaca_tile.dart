import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/design_tokens.dart';
import 'glass_progress.dart';
import 'money_text.dart';
import 'status_chip.dart';

/// VacaTile: one row of a vaca list (inside a grouped section).
///
/// Parameters:
/// - [title] / [subtitle]: restaurant and "Hoy · 3 personas".
/// - [amount]: the amount shown at the right (the most prominent thing).
/// - [amountCaption]: what that amount means ("por cobrar", "total").
/// - [percent]: progress of the payments (small glass).
/// - [isClosed]: shows "Cerrada" or "Abierta · 2 de 3".
/// - [statusLabel]: text of the chip.
/// - [onTap]: opens the vaca (decided by the screen).
class VacaTile extends StatelessWidget {
  const VacaTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountCaption,
    required this.percent,
    required this.isClosed,
    required this.statusLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int amount;
  final String amountCaption;
  final int percent;
  final bool isClosed;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.m),
          child: Row(
            children: [
              GlassProgress(percent: percent, width: 30, height: 40, showLabel: false),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.footnote, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.xs),
                    isClosed ? StatusChip.closed(label: statusLabel) : StatusChip.open(label: statusLabel),
                  ],
                ),
              ),
              const SizedBox(width: Space.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(amount, style: AppText.money.copyWith(fontWeight: FontWeight.w700)),
                  Text(amountCaption, style: AppText.caption),
                ],
              ),
              const SizedBox(width: Space.xs),
              const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFFC4C4C7)),
            ],
          ),
        ),
      ),
    );
  }
}
