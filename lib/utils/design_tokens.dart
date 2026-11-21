import 'package:flutter/material.dart';

import 'constants.dart';

// Design tokens ("Cimientos de UI"): every spacing, radius and text style
// of the app comes from here, so screens stay consistent.

/// Spacing scale. Nothing in the app uses other values.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Horizontal page margin (iOS uses 16-20).
  static const page = 20.0;

  /// Room at the bottom of tab screens so the floating bar never hides
  /// the last item.
  static const tabBarClearance = 112.0;
}

/// ONLY two corner radii in the whole app.
abstract final class Radii {
  /// Fields, chips, small tiles.
  static const small = 10.0;

  /// Grouped sections, cards, buttons, sheets.
  static const large = 16.0;

  static final smallAll = BorderRadius.circular(small);
  static final largeAll = BorderRadius.circular(large);
}

/// iOS type scale. Money always uses [money] / [moneyHero] (tabular
/// figures so digits line up).
abstract final class AppText {
  /// Inter (open-source, SIL OFL) is bundled in assets/fonts/. Apple's SF Pro
  /// may only be used on Apple platforms, so Inter gives a similar look here.
  static const String family = 'Inter';

  static const _tabular = [FontFeature.tabularFigures()];

  static const largeTitle = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.ink,
    height: 1.15,
  );
  static const title2 = TextStyle(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.2);
  static const headline = TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const body = TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const subheadline = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.muted);
  static const footnote = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.muted);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);

  /// Uppercase header above a grouped section.
  static const sectionHeader = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    letterSpacing: 0.4,
  );

  static const money = TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink, fontFeatures: _tabular);

  /// The biggest thing on a screen: the amount that matters.
  static const moneyHero = TextStyle(
    fontFamily: family,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );
}
