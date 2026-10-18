import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// SectionHeader: small uppercase title that separates blocks of a screen,
/// like "LA CUENTA" in the design.
///
/// Parameters:
/// - [title]: text (it is shown in uppercase).
/// - [trailing]: optional widget at the right (a counter, a button...).
///
/// Used in: HomeScreen, RegisterScreen and ResultsScreen.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          // `?trailing` adds the widget only when it is not null.
          ?trailing,
        ],
      ),
    );
  }
}
