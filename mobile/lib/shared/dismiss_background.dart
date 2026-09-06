import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';

/// Background merah + ikon sampah buat semua `Dismissible` swipe-to-delete —
/// biar konsisten (`direction: DismissDirection.endToStart`).
class DismissDeleteBackground extends StatelessWidget {
  const DismissDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.semanticColors.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
