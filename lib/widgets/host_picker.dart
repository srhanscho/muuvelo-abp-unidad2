import 'package:flutter/cupertino.dart';

import '../models/participant.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'grouped_section.dart';

/// HostPicker: row "Anfitrión · Ana ›" that opens a [CupertinoActionSheet]
/// to choose the host. The host absorbs the rounding residue.
///
/// Parameters:
/// - [participants]: the options.
/// - [hostId]: the selected person's id (or null).
/// - [onChanged]: called with the new host id.
class HostPicker extends StatelessWidget {
  const HostPicker({super.key, required this.participants, required this.hostId, required this.onChanged});

  final List<Participant> participants;
  final String? hostId;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final chosen = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('¿Quién es el anfitrión?'),
        message: const Text('Si sobra un peso por redondeo, lo asume el anfitrión.'),
        actions: [
          for (final person in participants)
            CupertinoActionSheetAction(
              isDefaultAction: person.id == hostId,
              onPressed: () => Navigator.of(sheetContext).pop(person.id),
              child: Text(person.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    String? name;
    for (final p in participants) {
      if (p.id == hostId) name = p.name;
    }
    return GroupedRow(
      leading: const IconTile(icon: Icon(CupertinoIcons.star_fill), color: AppColors.pending),
      title: 'Anfitrión',
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Text(
          name ?? 'Agrega personas',
          style: AppText.body.copyWith(color: AppColors.muted),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      onTap: participants.isEmpty ? null : () => _pick(context),
    );
  }
}
