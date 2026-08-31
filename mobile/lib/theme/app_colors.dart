import 'package:flutter/material.dart';

/// Token warna tema Karasuno (Haikyuu!!) — lihat docs/DESIGN.md §2-4.
abstract final class AppColors {
  // Light mode
  static const lightPrimary = Color(0xFFF2620D);
  static const lightPrimaryContainer = Color(0xFFFFE0C7);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFF1A1A1E); // Crow Black
  static const lightBackground = Color(0xFFFAFAF8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1A1A1E);
  static const lightOutline = Color(0xFFE4E1DC);

  // Dark mode
  static const darkPrimary = Color(0xFFFF7A1F);
  static const darkPrimaryContainer = Color(0xFF5C2E0C);
  static const darkOnPrimary = Color(0xFF1A1A1E);
  static const darkSecondary = Color(0xFFE8E6E1);
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkOnSurface = Color(0xFFF5F5F3);
  static const darkOutline = Color(0xFF3A3A3D);

  // Semantik (§4) — sama di light & dark kecuali kontras
  static const lightIncome = Color(0xFF12A150);
  static const darkIncome = Color(0xFF34D399);
  static const lightExpense = Color(0xFFE5484D);
  static const darkExpense = Color(0xFFF87171);
  static const lightWarning = Color(0xFFF5A623);
  static const darkWarning = Color(0xFFFBBF24);
  static const lightDanger = Color(0xFFDC2626);
  static const darkDanger = Color(0xFFEF4444);
}
