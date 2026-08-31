import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimary: AppColors.lightOnPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      outline: AppColors.lightOutline,
      error: AppColors.lightDanger,
    ),
    extensions: const [AppSemanticColors.light],
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimary: AppColors.darkOnPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      outline: AppColors.darkOutline,
      error: AppColors.darkDanger,
    ),
    extensions: const [AppSemanticColors.dark],
  );
}
