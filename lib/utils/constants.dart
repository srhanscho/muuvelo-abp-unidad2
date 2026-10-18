import 'package:flutter/material.dart';

/// Muuvelo palette (PRD section 5). Use these names instead of raw hex
/// values in widgets, so a color change happens in one place.
abstract final class AppColors {
  static const primary = Color(0xFF5B21D6);
  static const primarySoft = Color(0xFFEDE6FB);
  static const ink = Color(0xFF1A1430);
  static const cream = Color(0xFFFBF7F1);
  static const surface = Colors.white;
  static const muted = Color(0xFF6B6480);
  static const border = Color(0xFFECE6DC);

  /// Gold of the main "Cerrar cuenta" button (design 02-el-vaso).
  static const gold = Color(0xFFF8CF7A);

  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const pending = Color(0xFFD97706);
  static const pendingSoft = Color(0xFFFEF3C7);
  static const error = Color(0xFFDC2626);
}

/// All route names in one place, so a typo is a compile error instead of
/// a "route not found" at runtime.
abstract final class Routes {
  static const home = '/';
  static const register = '/registro';
  static const results = '/resultados'; // argument: vaca id (String)
}

/// Business limits used by the validators and the form.
abstract final class Limits {
  static const minParticipants = 2;
  static const maxParticipants = 10;
  static const maxParticipantName = 20;
  static const minRestaurantName = 2;
  static const maxRestaurantName = 40;
  static const maxItemDescription = 40;
  static const maxItemPrice = 10000000; // $ 10.000.000
  static const maxTipPercent = 30;
}

/// Tip presets offered as ChoiceChips, and the one selected by default.
const List<int> tipPresets = [10, 15, 20];
const int defaultTipPercent = 10;
