import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';
import '../../theme/app_semantic_colors.dart';

/// Ikon + warna per tipe transaksi — dipakai di list & Home biar konsisten.
/// Income ijo (masuk), Expense merah (keluar), Transfer oranye Karasuno.
({IconData icon, Color color}) transactionTypeVisual(
  BuildContext context,
  String type,
) {
  final semantic = context.semanticColors;
  return switch (type) {
    'Income' => (icon: Icons.arrow_downward, color: semantic.income),
    'Expense' => (icon: Icons.arrow_upward, color: semantic.expense),
    _ => (
        icon: Icons.swap_horiz,
        color: Theme.of(context).colorScheme.primary,
      ),
  };
}

/// Judul row transaksi: catatan kalau ada, else nama kategori, else tipe.
/// (Transfer ga punya kategori → jatuh ke "Transfer".)
String transactionTitle(Transaction t, Map<String, Category> categoriesById) {
  if (t.note?.isNotEmpty == true) return t.note!;
  final cat = t.categoryId == null ? null : categoriesById[t.categoryId];
  return cat?.name ?? t.type;
}
