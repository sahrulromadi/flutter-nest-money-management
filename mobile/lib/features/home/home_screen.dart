import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_illustration.dart';
import '../../shared/category_visuals.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/karasuno_decor.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../categories/categories_providers.dart';
import '../insights/insights_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsForHomeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthSnapshotProvider);
          ref.invalidate(recentTransactionsForHomeProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _ScoreboardHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BudgetAlertBanner(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TRANSAKSI TERAKHIR',
                          style: Theme.of(context).textTheme.labelLarge),
                      TextButton(
                        onPressed: () => context.go('/transactions'),
                        child: const Text('Lihat semua'),
                      ),
                    ],
                  ),
                  const CourtDivider(),
                  recentAsync.when(
                    loading: () => const Column(
                      children: [
                        SkeletonTile(),
                        SkeletonTile(),
                        SkeletonTile(),
                      ],
                    ),
                    error: (e, _) => AppErrorState(
                      onRetry: () =>
                          ref.invalidate(recentTransactionsForHomeProvider),
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return AppEmptyState.transactions(
                          onAdd: () => context.push('/transactions/add'),
                        );
                      }
                      final catMap = ref.watch(categoriesByIdProvider);
                      return Column(
                        children: transactions.map((t) {
                          final cat = t.categoryId == null
                              ? null
                              : catMap[t.categoryId];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              cat != null
                                  ? categoryIcon(cat.icon)
                                  : switch (t.type) {
                                      'Income' => Icons.arrow_downward,
                                      'Expense' => Icons.arrow_upward,
                                      _ => Icons.swap_horiz,
                                    },
                              color:
                                  cat != null ? categoryColor(cat.color) : null,
                            ),
                            title: Text(t.note?.isNotEmpty == true
                                ? t.note!
                                : t.type),
                            trailing: Text(formatRupiah(t.amount)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header ala scoreboard: label "TOTAL SALDO" + angka gede, motif sayap
/// samar di background, warna crow-black.
class _ScoreboardHeader extends ConsumerWidget {
  const _ScoreboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final totalAsync = ref.watch(totalBalanceProvider);
    final snapshotAsync = ref.watch(monthSnapshotProvider);
    final semantic = context.semanticColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? scheme.surface
            : scheme.secondary,
        border: Border(bottom: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: FeatherBackdrop(opacity: 0.10)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MONEY MANAGEMENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TOTAL SALDO',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  totalAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Skeleton(width: 200, height: 34, radius: 4),
                    ),
                    error: (e, _) => Text(
                      '—',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    data: (total) => Text(
                      formatRupiah(total),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  snapshotAsync.maybeWhen(
                    data: (s) => Row(
                      children: [
                        _MiniScore(
                          label: 'MASUK',
                          value: formatRupiah(s.income),
                          color: semantic.income,
                        ),
                        const SizedBox(width: 24),
                        _MiniScore(
                          label: 'KELUAR',
                          value: formatRupiah(s.expense),
                          color: semantic.expense,
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox(
                      height: 34,
                      child: Row(
                        children: [
                          Skeleton(width: 90, height: 14),
                          SizedBox(width: 24),
                          Skeleton(width: 90, height: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
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
        final nearLimit = budgets
            .where((b) => b.percentage >= 80 && b.percentage < 100)
            .length;
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
            borderRadius: BorderRadius.circular(6),
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
