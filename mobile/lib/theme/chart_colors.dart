import 'package:flutter/material.dart';

/// Palet kategorikal buat chart (breakdown kategori, dll) — dari skill
/// `dataviz`, dipake apa adanya (bukan warna tema Karasuno; identity warna
/// kategori beda urusan dari UI chrome, lihat docs/DESIGN.md §1). Urutan
/// slot itu sendiri bagian dari mekanisme CVD-safety-nya — jangan diacak.
abstract final class ChartColors {
  static const categoricalLight = [
    Color(0xFF2A78D6), // 1 blue
    Color(0xFFEB6834), // 2 orange
    Color(0xFF1BAF7A), // 3 aqua
    Color(0xFFEDA100), // 4 yellow
    Color(0xFFE87BA4), // 5 magenta
    Color(0xFF008300), // 6 green
    Color(0xFF4A3AA7), // 7 violet
    Color(0xFFE34948), // 8 red
  ];

  static const categoricalDark = [
    Color(0xFF3987E5),
    Color(0xFFD95926),
    Color(0xFF199E70),
    Color(0xFFC98500),
    Color(0xFFD55181),
    Color(0xFF008300),
    Color(0xFF9085E9),
    Color(0xFFE66767),
  ];

  /// Slot ke-N (0-indexed), wrap ke "Other" (abu2) kalau lewat 8 kategori.
  static Color categorical(int index, {required bool isDark}) {
    final palette = isDark ? categoricalDark : categoricalLight;
    if (index < palette.length) return palette[index];
    return isDark ? const Color(0xFF898781) : const Color(0xFF898781);
  }
}
