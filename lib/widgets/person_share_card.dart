import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/split_result.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'avatar_initials.dart';
import 'money_text.dart';
import 'muuvelo_icon.dart';
import 'status_chip.dart';

/// PersonShareCard: what one person owes, whether they paid, and (when
/// expanded) the items they consumed with their fraction, e.g.
/// "Postre (1/3)". One row of a grouped section.
///
/// Parameters:
/// - [name] / [initials] / [amount]: who and how much (pesos).
/// - [isHost]: shows the "Anfitrión" chip (the host absorbs rounding).
/// - [isPaid]: state of the "Pagó" switch.
/// - [shares]: the person's items, already calculated by split_service.
/// - [onPaidChanged]: called when the switch is tapped. `null` hides the
///   switch (closed vaca or read-only Detalle).
/// - [saving]: shows a spinner while the change goes to the database.
class PersonShareCard extends StatelessWidget {
  const PersonShareCard({
    super.key,
    required this.name,
    required this.initials,
    required this.amount,
    required this.isHost,
    required this.isPaid,
    required this.shares,
    required this.onPaidChanged,
    this.saving = false,
  });

  final String name;
  final String initials;
  final int amount;
  final bool isHost;
  final bool isPaid;
  final List<ItemShare> shares;
  final ValueChanged<bool>? onPaidChanged;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Remove the default divider lines of the ExpansionTile.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: Space.l, right: Space.s),
        childrenPadding: const EdgeInsets.fromLTRB(64, 0, Space.l, Space.m),
        shape: const Border(),
        collapsedShape: const Border(),
        showTrailingIcon: false,
        leading: AvatarInitials(initials: initials, highlighted: isPaid),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.headline, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Space.xs),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      isPaid
                          ? const StatusChip.paid(
                              icon: MuuveloIcon('paid', size: 12, fallback: CupertinoIcons.checkmark_alt, color: AppColors.success),
                            )
                          : const StatusChip.pending(
                              icon: MuuveloIcon('pending', size: 12, fallback: CupertinoIcons.clock, color: AppColors.pending),
                            ),
                      if (isHost) const StatusChip.open(label: 'Anfitrión'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.s),
            // Amount on top (the most important number), switch below.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(amount, style: AppText.money.copyWith(fontSize: 19, fontWeight: FontWeight.w700)),
                if (onPaidChanged != null || saving)
                  SizedBox(
                    width: 60,
                    height: 44,
                    child: Center(
                      child: saving
                          ? const CupertinoActivityIndicator()
                          : Semantics(
                              label: '$name pagó',
                              child: CupertinoSwitch(
                                value: isPaid,
                                activeTrackColor: AppColors.success,
                                onChanged: onPaidChanged,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: Space.xs),
          child: Text(
            'Ver consumo (${shares.length} ${shares.length == 1 ? 'ítem' : 'ítems'})',
            style: AppText.footnote.copyWith(color: AppColors.primary),
          ),
        ),
        children: [
          if (shares.isEmpty)
            const Align(alignment: Alignment.centerLeft, child: Text('No consumió ítems', style: AppText.footnote)),
          for (final share in shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(share.label, style: AppText.subheadline.copyWith(color: AppColors.ink))),
                  MoneyText(share.amount, style: AppText.subheadline),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
