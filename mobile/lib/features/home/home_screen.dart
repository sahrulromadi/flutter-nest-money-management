import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/currency_formatter.dart';
import '../../theme/app_semantic_colors.dart';
import '../insights/insights_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final snapshotAsync = ref.watch(monthSnapshotProvider);
    final recentAsync = ref.watch(recentTransactionsForHomeProvider);
    final semantic = context.semanticColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Money Management')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthSnapshotProvider);
          ref.invalidate(recentTransactionsForHomeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _BudgetAlertBanner(),
            Text('Total Saldo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            totalBalanceAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (total) => Text(
                formatRupiah(total),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 24),
            snapshotAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (snapshot) => Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Pemasukan bulan ini',
                      value: formatRupiah(snapshot.income),
                      color: semantic.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Pengeluaran bulan ini',
                      value: formatRupiah(snapshot.expense),
                      color: semantic.expense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            recentAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('Belum ada transaksi'),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => context.push('/transactions/add'),
                            child: const Text('Catat transaksi pertama'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: transactions
                      .map((t) => ListTile(
                            leading: Icon(
                              switch (t.type) {
                                'Income' => Icons.arrow_downward,
                                'Expense' => Icons.arrow_upward,
                                _ => Icons.swap_horiz,
                              },
                            ),
                            title: Text(t.note?.isNotEmpty == true ? t.note! : t.type),
                            trailing: Text(formatRupiah(t.amount)),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAlertBanner extends ConsumerWidget {
  const _BudgetAlertBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider(null));
    final semantic = context.semanticColors;

    return budgetsAsync.maybeWhen(
      data: (budgets) {
        final overLimit = budgets.where((b) => b.percentage >= 100).length;
        final nearLimit = budgets.where((b) => b.percentage >= 80 && b.percentage < 100).length;
        if (overLimit == 0 && nearLimit == 0) return const SizedBox.shrink();

        final color = overLimit > 0 ? semantic.danger : semantic.warning;
        final text = overLimit > 0
            ? '$overLimit budget kategori udah lewat limit'
            : '$nearLimit budget kategori mendekati limit';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(text)),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
