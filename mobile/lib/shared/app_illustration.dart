import 'package:flutter/material.dart';

import 'karasuno_decor.dart';

/// Empty / error state bertema Karasuno — siluet gagak + copy voli.
/// Satu widget reusable biar ukuran & tone konsisten.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Empty state siap-pakai per fitur (copy bertema voli).
  factory AppEmptyState.transactions({VoidCallback? onAdd}) => AppEmptyState(
        message: 'Belum ada rally.\nCatat transaksi pertama.',
        actionLabel: onAdd == null ? null : 'Catat transaksi',
        onAction: onAdd,
      );

  factory AppEmptyState.accounts({VoidCallback? onAdd}) => AppEmptyState(
        message: 'Belum ada akun di roster.',
        actionLabel: onAdd == null ? null : 'Tambah akun',
        onAction: onAdd,
      );

  factory AppEmptyState.categories() => const AppEmptyState(
        message: 'Papan taktik masih kosong.\nBikin kategori dulu.',
      );

  factory AppEmptyState.goals({VoidCallback? onAdd}) => AppEmptyState(
        message: 'Belum ada target.\nSet goal tabungan pertama.',
        actionLabel: onAdd == null ? null : 'Tambah goal',
        onAction: onAdd,
      );

  factory AppEmptyState.recurring({VoidCallback? onAdd}) => AppEmptyState(
        message: 'Belum ada transaksi berulang.',
        actionLabel: onAdd == null ? null : 'Tambah aturan',
        onAction: onAdd,
      );

  factory AppEmptyState.insights() => const AppEmptyState(
        message: 'Scoreboard belum jalan.\nMulai periode budget dulu.',
      );

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CrowMark(size: 88),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state — gagak "jatuh" + tombol coba lagi.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.onRetry, this.detail});

  final VoidCallback onRetry;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: 2.6,
              child: CrowMark(
                size: 72,
                color: Theme.of(context)
                    .colorScheme
                    .error
                    .withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Gagal ambil data.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
