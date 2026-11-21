import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'design_tokens.dart';

/// Material 3 theme dressed as iOS: grouped gray background, white
/// sections without borders, filled text fields, Cupertino page
/// transitions (swipe back) on every platform.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onSurface: AppColors.ink,
    surface: AppColors.surface,
    error: AppColors.error,
  );

  final roundedLarge = RoundedRectangleBorder(borderRadius: Radii.largeAll);

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppText.family,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.fill,
    dividerColor: AppColors.separator,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: Color(0xF0F2F2F7),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
        navLargeTitleTextStyle: AppText.largeTitle,
        navTitleTextStyle: AppText.headline,
        textStyle: AppText.body,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.headline,
    ),
    cardTheme: CardThemeData(color: AppColors.surface, elevation: 0, margin: EdgeInsets.zero, shape: roundedLarge),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: roundedLarge,
        elevation: 0,
        textStyle: AppText.headline,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.primary,
        textStyle: AppText.headline.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fill,
      hintStyle: AppText.body.copyWith(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 14),
      border: OutlineInputBorder(borderRadius: Radii.smallAll, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: Radii.smallAll, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.smallAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Radii.smallAll,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Radii.smallAll,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: AppText.footnote.copyWith(color: AppColors.error),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.subheadline.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: Radii.smallAll),
      insetPadding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.muted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.large))),
    ),
  );
}
