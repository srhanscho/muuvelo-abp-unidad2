import 'package:flutter/material.dart';

import '../models/participant.dart';
import '../utils/constants.dart';
import 'money_text.dart';
import 'status_chip.dart';

/// BillItemCard: one item of the bill with a [FilterChip] per person to
/// choose who shared it.
///
/// Parameters:
/// - [description] / [price]: the item (price in pesos).
/// - [people]: everyone at the table (one chip each).
/// - [selectedIds]: who shared the item (selected chips).
/// - [onToggle]: called with a person's id when their chip is tapped.
/// - [onDelete]: removes the item.
/// - [showError]: paints the "Sin asignar" warning in red after the user
///   tried to calculate.
///
/// Used in: RegisterScreen, once per item (unassigned / single owner /
/// shared configurations).
class BillItemCard extends StatelessWidget {
  const BillItemCard({
    super.key,
    required this.description,
    required this.price,
    required this.people,
    required this.selectedIds,
    required this.onToggle,
    required this.onDelete,
    this.showError = false,
  });

  final String description;
  final int price;
  final List<Participant> people;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onDelete;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                MoneyText(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                IconButton(
                  tooltip: 'Eliminar $description',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            _ShareStatus(count: selectedIds.length, showError: showError),
            const SizedBox(height: 6),
            if (people.isEmpty)
              const Text('Agrega personas para asignar este ítem', style: TextStyle(color: AppColors.muted)),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                for (final person in people)
                  FilterChip(
                    label: Text(person.name),
                    selected: selectedIds.contains(person.id),
                    onSelected: (_) => onToggle(person.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sin asignar" (red after a failed submit), "De una persona" or
/// "Compartido entre N".
class _ShareStatus extends StatelessWidget {
  const _ShareStatus({required this.count, required this.showError});

  final int count;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return StatusChip(
        label: 'Sin asignar: toca quién lo consumió',
        color: showError ? AppColors.error : AppColors.pending,
        background: showError ? const Color(0xFFFEE2E2) : AppColors.pendingSoft,
      );
    }
    return StatusChip(
      label: count == 1 ? 'De una persona' : 'Compartido entre $count',
      color: AppColors.primary,
      background: AppColors.primarySoft,
    );
  }
}
