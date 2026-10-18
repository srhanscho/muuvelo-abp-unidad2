import 'package:flutter/material.dart';

import '../models/participant.dart';

/// HostDropdown: [DropdownButtonFormField] to choose the host among the
/// participants. The host absorbs the rounding residue (PRD section 6).
///
/// Parameters:
/// - [participants]: the options.
/// - [hostId]: the selected person's id (or null).
/// - [onChanged]: called with the new host id.
/// - [validator]: usually `validateHost` from validators.dart.
///
/// Used in: RegisterScreen.
class HostDropdown extends StatelessWidget {
  const HostDropdown({
    super.key,
    required this.participants,
    required this.hostId,
    required this.onChanged,
    this.validator,
  });

  final List<Participant> participants;
  final String? hostId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // initialValue is read only once, so a new key forces a rebuild when
      // the list of people or the host changes from outside.
      key: ValueKey('${participants.map((p) => p.id).join(',')}|$hostId'),
      initialValue: hostId,
      isExpanded: true,
      validator: validator,
      decoration: const InputDecoration(
        labelText: 'Anfitrión',
        prefixIcon: Icon(Icons.star_outline),
        helperText: 'Si sobra un peso por redondeo, lo asume el anfitrión',
      ),
      hint: const Text('Primero agrega personas'),
      items: [
        for (final person in participants)
          DropdownMenuItem(
            value: person.id,
            child: Text(person.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: participants.isEmpty ? null : onChanged,
    );
  }
}
