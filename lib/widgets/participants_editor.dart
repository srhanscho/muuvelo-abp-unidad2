import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/participant.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import 'avatar_initials.dart';
import 'custom_text_field.dart';

/// ParticipantsEditor: text field + "add" button + one row per person
/// (tap the name to rename, minus button to remove).
///
/// It only DRAWS; the rules (no duplicates, max 10...) live in the screen
/// and `validators.dart`.
///
/// Parameters:
/// - [controller]: text of the name being typed.
/// - [participants]: people already added.
/// - [hostId]: shows a star next to the host.
/// - [errorText]: message under the field.
/// - [onAdd] / [onRemove] / [onRename]: report actions to the screen.
class ParticipantsEditor extends StatelessWidget {
  const ParticipantsEditor({
    super.key,
    required this.controller,
    required this.participants,
    required this.errorText,
    required this.onAdd,
    required this.onRemove,
    required this.onRename,
    this.hostId,
  });

  final TextEditingController controller;
  final List<Participant> participants;
  final String? hostId;
  final String? errorText;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<Participant> onRename;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Nombre de la persona',
                  hint: 'Ej: Juliana',
                  icon: CupertinoIcons.person_add,
                  controller: controller,
                  errorText: errorText,
                  maxLength: Limits.maxParticipantName,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: Space.s),
              Padding(
                // Aligns the button with the text box (below the label).
                padding: const EdgeInsets.only(top: 22),
                child: IconButton.filled(
                  tooltip: 'Agregar persona',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    fixedSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(borderRadius: Radii.smallAll),
                  ),
                  icon: const Icon(CupertinoIcons.add, color: Colors.white),
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        ),
        for (final person in participants) ...[
          Container(height: 0.5, margin: const EdgeInsets.only(left: 64), color: AppColors.separator),
          _PersonRow(
            person: person,
            isHost: person.id == hostId,
            onRename: () => onRename(person),
            onRemove: () => onRemove(person.id),
          ),
        ],
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.isHost, required this.onRename, required this.onRemove});

  final Participant person;
  final bool isHost;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRename,
      child: Padding(
        padding: const EdgeInsets.only(left: Space.l, right: Space.xs),
        child: Row(
          children: [
            AvatarInitials(initials: person.initials, size: 36),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(person.name, style: AppText.body, overflow: TextOverflow.ellipsis),
            ),
            if (isHost) const Icon(CupertinoIcons.star_fill, size: 16, color: AppColors.pending),
            IconButton(
              tooltip: 'Quitar a ${person.name}',
              icon: const Icon(CupertinoIcons.minus_circle_fill, color: AppColors.error),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
