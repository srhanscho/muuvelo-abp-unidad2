import 'package:flutter/material.dart';

import '../models/split_result.dart';
import '../utils/constants.dart';
import 'avatar_initials.dart';
import 'money_text.dart';
import 'status_chip.dart';

/// PersonShareCard: what one person owes, whether they paid, and (inside
/// an [ExpansionTile]) the items they consumed with their fraction, e.g.
/// "Postre (1/3)".
///
/// Parameters:
/// - [name] / [initials] / [amount]: who and how much (pesos).
/// - [isHost]: shows the "Anfitrión" chip (the host absorbs rounding).
/// - [isPaid]: state of the "Pagó" checkbox.
/// - [shares]: the person's items, already calculated by split_service.
/// - [onPaidChanged]: called when the checkbox is tapped. `null` disables
///   the checkbox (used when the vaca is closed).
///
/// Used in: ResultsScreen, once per participant, in several configurations
/// (host / guest, paid / pending, open / closed vaca).
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
  });

  final String name;
  final String initials;
  final int amount;
  final bool isHost;
  final bool isPaid;
  final List<ItemShare> shares;
  final ValueChanged<bool>? onPaidChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 0),
            child: Row(
              children: [
                AvatarInitials(initials: initials, highlighted: isPaid),
                const SizedBox(width: 12),
                Expanded(
                  child: _NameAndStatus(name: name, isHost: isHost, isPaid: isPaid),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Inset so the amount lines up with the checkbox below.
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: MoneyText(
                        amount,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _PaidCheckbox(isPaid: isPaid, name: name, onChanged: onPaidChanged),
                  ],
                ),
              ],
            ),
          ),
          // Remove the default divider lines of the ExpansionTile.
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              dense: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              title: Text(
                'Ver consumo (${shares.length} ${shares.length == 1 ? 'ítem' : 'ítems'})',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              children: [
                if (shares.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No consumió ítems', style: TextStyle(color: AppColors.muted)),
                  ),
                for (final share in shares)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(share.label)),
                        MoneyText(share.amount, style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameAndStatus extends StatelessWidget {
  const _NameAndStatus({required this.name, required this.isHost, required this.isPaid});

  final String name;
  final bool isHost;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            isPaid
                ? const StatusChip(label: 'Pagó', color: AppColors.success, background: AppColors.successSoft)
                : const StatusChip(
                    label: 'Pendiente',
                    color: AppColors.pending,
                    background: AppColors.pendingSoft,
                  ),
            if (isHost)
              const StatusChip(
                label: 'Anfitrión',
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
          ],
        ),
      ],
    );
  }
}

/// Checkbox + "Pagó" label. The whole row is tappable (bigger tap target).
class _PaidCheckbox extends StatelessWidget {
  const _PaidCheckbox({required this.isPaid, required this.name, required this.onChanged});

  final bool isPaid;
  final String name;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onChanged == null ? null : () => onChanged!(!isPaid),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pagó'),
          Checkbox(
            value: isPaid,
            semanticLabel: '$name pagó',
            onChanged: onChanged == null ? null : (value) => onChanged!(value ?? false),
          ),
        ],
      ),
    );
  }
}
