import 'package:flutter/material.dart';

/// Sumber tunggal pilihan icon & warna kategori.
///
/// PENTING: `kCategoryIcons` disimpen sebagai INDEX (bukan codePoint) di kolom
/// `categories.icon`. Jadi urutan list ini KONTRAK — jangan diubah/disisipin di
/// tengah, cuma boleh APPEND di akhir. Kalau urutan berubah, icon kategori lama
/// bergeser. (Alasan pakai index: `IconData` dari int dinamis bikin
/// `flutter build` gagal tree-shake icon.)
const List<IconData> kCategoryIcons = [
  Icons.fastfood_outlined,
  Icons.directions_car_outlined,
  Icons.home_outlined,
  Icons.shopping_bag_outlined,
  Icons.local_hospital_outlined,
  Icons.school_outlined,
  Icons.movie_outlined,
  Icons.work_outline,
  Icons.savings_outlined,
  Icons.label_outline,
];

const List<Color> kCategoryColors = [
  Colors.orange,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.teal,
];

const IconData kCategoryFallbackIcon = Icons.label_outline;

/// `stored` = index (string) dari `kCategoryIcons`. Fallback ke label kalau
/// null / bukan angka / di luar range (termasuk data lama yang isinya codePoint).
IconData categoryIcon(String? stored) {
  final idx = int.tryParse(stored ?? '');
  if (idx == null || idx < 0 || idx >= kCategoryIcons.length) {
    return kCategoryFallbackIcon;
  }
  return kCategoryIcons[idx];
}

/// `stored` = hex `#rrggbb`. Null kalau format gak valid.
Color? categoryColor(String? stored) {
  if (stored == null) return null;
  final hex = stored.startsWith('#') ? stored.substring(1) : stored;
  if (hex.length != 6) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String categoryColorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
