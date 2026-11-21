import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/participant.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'money_text.dart';
import 'muuvelo_icon.dart';

/// BillItemCard: one item of the bill with a toggle pill per person to
/// choose who shared it. Lives inside a grouped section.
///
/// Parameters:
/// - [description] / [price]: the item (price in pesos).
/// - [people]: everyone at the table (one pill each).
/// - [selectedIds]: who shared the item.
/// - [onToggle]: called with a person's id when their pill is tapped.
/// - [onEdit] / [onDelete]: change or remove the item.
/// - [showError]: paints "Sin asignar" in red after a failed submit.
class BillItemCard extends StatelessWidget {
  const BillItemCard({
    super.key,
    required this.description,
    required this.price,
    required this.people,
    required this.selectedIds,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.showError = false,
  });

  final String description;
  final int price;
  final List<Participant> people;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final count = selectedIds.length;
    final (String status, Color statusColor) = count == 0
        ? ('Sin asignar: toca quién lo consumió', showError ? AppColors.error : AppColors.pending)
        : (count == 1 ? 'De una persona' : 'Compartido entre $count · 1/$count cada uno', AppColors.muted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.xs, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(description, style: AppText.headline, overflow: TextOverflow.ellipsis),
              ),
              MoneyText(price, style: AppText.money),
              IconButton(
                tooltip: 'Editar $description',
                icon: const MuuveloIcon('edit', size: 20, fallback: CupertinoIcons.pencil, color: AppColors.primary),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Eliminar $description',
                icon: const Icon(CupertinoIcons.trash, size: 20, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
          Text(status, style: AppText.footnote.copyWith(color: statusColor)),
          const SizedBox(height: Space.s),
          if (people.isEmpty) const Text('Agrega personas para asignar este ítem', style: AppText.footnote),
          Padding(
            padding: const EdgeInsets.only(right: Space.m),
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final person in people)
                  SharerPill(
                    name: person.name,
                    selected: selectedIds.contains(person.id),
                    onTap: () => onToggle(person.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle pill with a person's name (selected = tinted with a check).
class SharerPill extends StatelessWidget {
  const SharerPill({super.key, required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: selected ? AppColors.primary : AppColors.fill,
        borderRadius: Radii.smallAll,
        child: InkWell(
          borderRadius: Radii.smallAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Colors.white),
                    const SizedBox(width: Space.xs),
                  ],
                  Text(
                    name,
                    style: AppText.subheadline.copyWith(
                      color: selected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
