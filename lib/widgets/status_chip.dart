import 'package:flutter/material.dart';

/// StatusChip: tiny colored pill with a short state, like "Pagó" or
/// "Pendiente" in the design.
///
/// Parameters:
/// - [label]: the text.
/// - [color]: text color.
/// - [background]: pill color.
///
/// Used in: PersonShareCard (Pagó / Pendiente / Anfitrión), VacaTile
/// (Abierta / Cerrada) and BillItemCard (Sin asignar / Compartido).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
