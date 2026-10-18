import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// AvatarInitials: round avatar with a person's initials, e.g. "JD".
///
/// Parameters:
/// - [initials]: text to show (computed by `Participant.initials`).
/// - [size]: diameter in pixels.
/// - [highlighted]: purple filled when true, outlined grey when false
///   (used to show who has NOT paid yet).
///
/// Used in: ParticipantsEditor (chips of the register form) and
/// PersonShareCard (results screen).
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({super.key, required this.initials, this.size = 40, this.highlighted = true});

  final String initials;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? AppColors.primary : AppColors.surface,
        border: Border.all(color: highlighted ? AppColors.primary : AppColors.muted),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: highlighted ? Colors.white : AppColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
