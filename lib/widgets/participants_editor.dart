import 'package:flutter/material.dart';

import '../models/participant.dart';
import 'avatar_initials.dart';
import 'custom_text_field.dart';

/// ParticipantsEditor: text field + "add" button + one chip per person,
/// each chip with a delete (x) icon.
///
/// It only DRAWS; the rules (no duplicates, max 10...) live in the screen
/// and `validators.dart`.
///
/// Parameters:
/// - [controller]: text of the name being typed.
/// - [participants]: people already added (shown as chips).
/// - [errorText]: message under the field (duplicate, empty, too few...).
/// - [onAdd]: called by the add button or the keyboard "done" key.
/// - [onRemove]: called with the id of the chip that was deleted.
///
/// Used in: RegisterScreen.
class ParticipantsEditor extends StatelessWidget {
  const ParticipantsEditor({
    super.key,
    required this.controller,
    required this.participants,
    required this.errorText,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<Participant> participants;
  final String? errorText;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Nombre de la persona',
                icon: Icons.person_add_alt_1,
                controller: controller,
                errorText: errorText,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filled(
                tooltip: 'Agregar persona',
                iconSize: 28,
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final person in participants)
              InputChip(
                avatar: AvatarInitials(initials: person.initials, size: 26),
                label: Text(person.name),
                deleteButtonTooltipMessage: 'Quitar a ${person.name}',
                onDeleted: () => onRemove(person.id),
              ),
          ],
        ),
      ],
    );
  }
}
