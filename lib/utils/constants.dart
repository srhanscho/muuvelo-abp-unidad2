import 'package:flutter/material.dart';

/// Muuvelo palette, iOS style: brand purple is ONLY the tint (buttons,
/// links, selected states, the glass liquid); everything else is neutral.
/// Use these names instead of raw hex values in widgets.
abstract final class AppColors {
  /// Brand tint.
  static const primary = Color(0xFF5B21D6);

  /// Lilac: soft tint background (selected chips, icon tiles).
  static const primarySoft = Color(0xFFEDE6FB);

  /// iOS grouped background and the white sections on top of it.
  static const background = Color(0xFFF2F2F7);
  static const surface = Colors.white;

  /// Text: iOS label / secondaryLabel.
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF8E8E93);

  /// Hairline separators inside grouped sections.
  static const separator = Color(0x99C6C6C8);

  /// Filled text fields and neutral chips.
  static const fill = Color(0xFFEFEFF4);

  /// Dark summary card (design 05-historial).
  static const night = Color(0xFF1A1430);

  /// iOS system colors for states.
  static const success = Color(0xFF34C759);
  static const successSoft = Color(0xFFE3F8E8);
  static const pending = Color(0xFFFF9500);
  static const pendingSoft = Color(0xFFFFF1DC);
  static const error = Color(0xFFFF3B30);
  static const errorSoft = Color(0xFFFFE5E3);

  /// Gold: only for the single "Cerrar y cobrar" moment.
  static const gold = Color(0xFFF8CF7A);

  /// Tab bar icon colors (clay icon style).
  static const tabHome = Color(0xFFFF6B4A);
  static const tabVacas = Color(0xFFF25CA2);
  static const tabNew = Color(0xFF6CCB3F);
  static const tabCobros = Color(0xFF6E73F2);
}

/// All route names in one place, so a typo is a compile error instead of
/// a "route not found" at runtime.
abstract final class Routes {
  static const home = '/';
  static const register = '/registro';
  static const detail = '/vaca'; // argument: vaca id (String)
  static const edit = '/editar'; // argument: vaca id (String)
  static const results = '/cobro'; // argument: vaca id (String)
  static const success = '/listo'; // argument: SuccessArgs
}

/// Business limits used by the validators and the form (same as the
/// CHECK constraints of the database).
abstract final class Limits {
  static const minParticipants = 2;
  static const maxParticipants = 10;
  static const maxParticipantName = 20;
  static const minRestaurantName = 2;
  static const maxRestaurantName = 40;
  static const maxItemDescription = 40;
  static const maxItemPrice = 10000000; // $ 10.000.000
  static const maxTipPercent = 30;
  static const minPasswordLength = 6;
}

/// Tip presets offered in the segmented control, and the default one.
const List<int> tipPresets = [10, 15, 20];
const int defaultTipPercent = 10;
