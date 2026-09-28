import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/karasuno_decor.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../categories/categories_providers.dart';
import '../insights/insights_providers.dart';
import '../transactions/transaction_display.dart';
import '../transactions/transactions_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(todayTransactionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthSnapshotProvider);
          ref.invalidate(todayTransactionsProvider);
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
                      Text('TRANSAKSI HARI INI',
                          style: Theme.of(context).textTheme.labelLarge),
                      TextButton(
                        onPressed: () => context.push('/transactions'),
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
                          ref.invalidate(todayTransactionsProvider),
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('Belum ada transaksi hari ini'),
                          ),
                        );
                      }
                      final categoriesById =
                          ref.watch(categoriesByIdProvider);
                      return Column(
                        children: transactions.map((t) {
                          final visual =
                              transactionTypeVisual(context, t.type);
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: const DismissDeleteBackground(),
                            onDismissed: (_) => ref
                                .read(transactionsRepositoryProvider)
                                .delete(t.id),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () =>
                                  context.push('/transactions/${t.id}/edit'),
                              leading:
                                  Icon(visual.icon, color: visual.color),
                              title:
                                  Text(transactionTitle(t, categoriesById)),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatRupiah(t.amount)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(t.updatedAt.toLocal()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ),
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
                  const SizedBox(
                    height: 26,
                    child: FlyingCrow(),
                  ),
                  const SizedBox(height: 12),
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
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final semantic = context.semanticColors;

    return budgetsAsync.maybeWhen(
      data: (budgets) {
        final overLimit = budgets.where((b) => b.pct >= 100).length;
        final nearLimit =
            budgets.where((b) => b.pct >= 80 && b.pct < 100).length;
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
