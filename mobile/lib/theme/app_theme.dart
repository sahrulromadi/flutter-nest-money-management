import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

abstract final class AppTheme {
  // ponytail: font display "jersey" (Oswald/Anton/Bebas Neue) belum di-bundle —
  // butuh file .ttf di assets/fonts/ + entri pubspec. Sementara pakai default
  // font dengan weight tebal + letterSpacing negatif biar berasa scoreboard.
  // Kalau font di-drop-in nanti: tinggal tambah `fontFamily: 'Jersey'` di
  // _displayText di bawah.
  static const String? _jerseyFamily = null;

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontFamily: _jerseyFamily,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontFamily: _jerseyFamily,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontFamily: _jerseyFamily,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  static const _cardTheme = CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    margin: EdgeInsets.zero,
  );

  // Pemilihan chip (akun/kategori/tipe) ditandai WARNA aja, bukan ceklis.
  // Selected = oranye primary penuh + label kontras (bukan oranye pucat).
  static ChipThemeData _chip(ColorScheme s) => ChipThemeData(
        showCheckmark: false,
        backgroundColor: s.surface,
        selectedColor: s.primary,
        secondarySelectedColor: s.primary,
        labelStyle: TextStyle(color: s.onSurface),
        secondaryLabelStyle: TextStyle(
          color: s.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: s.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      );

  static AppBarTheme _appBar(ColorScheme s) => AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        // Garis oranye tipis di bawah app bar — kesan garis lapangan.
        shape: Border(bottom: BorderSide(color: s.primary, width: 2)),
      );

  static final light = () {
    const scheme = ColorScheme.light(
      primary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimary: AppColors.lightOnPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      outline: AppColors.lightOutline,
      error: AppColors.lightDanger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: scheme,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightOnPrimary,
      ),
      cardTheme: _cardTheme.copyWith(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      appBarTheme: _appBar(scheme),
      chipTheme: _chip(scheme),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      extensions: const [AppSemanticColors.light],
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme));
  }();

  static final dark = () {
    const scheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimary: AppColors.darkOnPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      outline: AppColors.darkOutline,
      error: AppColors.darkDanger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: scheme,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkOnPrimary,
      ),
      cardTheme: _cardTheme.copyWith(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      appBarTheme: _appBar(scheme),
      chipTheme: _chip(scheme),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      extensions: const [AppSemanticColors.dark],
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme));
  }();
}
