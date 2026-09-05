import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/chart_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../categories/categories_providers.dart';
import 'budget_form_sheet.dart';
import 'insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Budget & reports murni backend (belum local-first) — jangan nembak
    // network kalau belum login, nanti 401 keliatan sbg error yg bingungin.
    if (ref.watch(authControllerProvider) != AuthPhase.unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: const AppLoginRequiredState(
          message: 'Login dulu buat lihat budget & laporan.\n'
              'Insights disimpen di server, belum ada versi offline-nya.',
        ),
      );
    }

    final activePeriodAsync = ref.watch(activeBudgetPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBudgetPeriodProvider);
          ref.invalidate(budgetsProvider);
          ref.invalidate(reportsSummaryProvider);
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(cashflowTrendProvider);
        },
        child: activePeriodAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Skeleton(width: 220, height: 20),
              SizedBox(height: 24),
              Skeleton(height: 40, radius: 4),
              SizedBox(height: 12),
              Skeleton(height: 160, radius: 6),
            ],
          ),
          error: (e, _) => AppErrorState(
            onRetry: () => ref.invalidate(activeBudgetPeriodProvider),
          ),
          // Laporan (reports API) di-scope ke periode budget aktif. Tanpa
          // periode aktif, backend `/reports/*` balik 404 by design — jadi
          // jangan render chart-nya, tampilin ajakan mulai periode.
          data: (period) {
            if (period == null) {
              return ListView(
                children: [
                  const SizedBox(height: 40),
                  AppEmptyState.insights(),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: () => _startNewPeriod(context, ref),
                      child: const Text('Mulai periode budget'),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Periode aktif: sejak ${DateFormat('d MMM yyyy', 'id_ID').format(period.startedAt)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _startNewPeriod(context, ref),
                      child: const Text('Periode baru'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => showBudgetFormSheet(context),
                    ),
                  ],
                ),
                const _BudgetList(),
                const SizedBox(height: 24),
                Text('Cashflow Trend',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const _CashflowChart(),
                const SizedBox(height: 24),
                Text('Breakdown Pengeluaran',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const _CategoryBreakdownChart(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startNewPeriod(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    await ref.read(budgetApiProvider).startNewPeriod(date);
    ref.invalidate(activeBudgetPeriodProvider);
    ref.invalidate(budgetsProvider);
  }
}

class _BudgetList extends ConsumerWidget {
  const _BudgetList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider(null));
    final categoriesAsync = ref.watch(categoriesListProvider(null));
    final semantic = context.semanticColors;

    return budgetsAsync.when(
      loading: () => const Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Skeleton(height: 40, radius: 4),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Skeleton(height: 40, radius: 4),
          ),
        ],
      ),
      error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(budgetsProvider)),
      data: (budgets) {
        if (budgets.isEmpty) return const Text('Belum ada budget di periode ini');
        return Column(
          children: budgets.map((b) {
            final categoryName = categoriesAsync.maybeWhen(
              data: (cats) => cats.where((c) => c.id == b.categoryId).firstOrNull?.name,
              orElse: () => null,
            );
            final color = b.percentage >= 100
                ? semantic.danger
                : b.percentage >= 80
                    ? semantic.warning
                    : semantic.income;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName ?? b.categoryId),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (b.percentage / 100).clamp(0, 1),
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${formatRupiah(b.spent)} / ${formatRupiah(b.limitAmount)}'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CashflowChart extends ConsumerWidget {
  const _CashflowChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(cashflowTrendProvider);
    final semantic = context.semanticColors;

    return trendAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Skeleton(height: 160, radius: 6),
      ),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(cashflowTrendProvider)),
      data: (points) {
        if (points.isEmpty) return const Text('Belum ada data');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].income),
                      ],
                      color: semantic.income,
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].expense),
                      ],
                      color: semantic.expense,
                      isCurved: true,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: semantic.income, label: 'Income'),
                const SizedBox(width: 16),
                _LegendDot(color: semantic.expense, label: 'Expense'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CategoryBreakdownChart extends ConsumerWidget {
  const _CategoryBreakdownChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return breakdownAsync.when(
      loading: () => const Column(
        children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
        ],
      ),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(categoryBreakdownProvider)),
      data: (items) {
        if (items.isEmpty) return const Text('Belum ada data');
        final maxTotal = items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 90, child: Text(items[i].categoryName, overflow: TextOverflow.ellipsis)),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: maxTotal == 0 ? 0 : (items[i].total / maxTotal),
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: ChartColors.categorical(i, isDark: isDark),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formatRupiah(items[i].total)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
