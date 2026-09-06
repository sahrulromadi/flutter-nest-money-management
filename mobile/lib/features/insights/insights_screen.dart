import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/chart_colors.dart';
import '../auth/current_user_provider.dart';
import '../categories/categories_providers.dart';
import 'budget_form_sheet.dart';
import 'insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(allPeriodsProvider);
    final viewed = ref.watch(viewedPeriodProvider);
    final closed = ref.watch(viewedPeriodClosedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: periodsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(children: [
            Skeleton(height: 40, radius: 4),
            SizedBox(height: 12),
            Skeleton(height: 160, radius: 6),
          ]),
        ),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(allPeriodsProvider),
        ),
        data: (periods) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PeriodSelector(periods: periods),
              const SizedBox(height: 16),
              const _PeriodSummaries(),
              const SizedBox(height: 24),
              if (periods.isEmpty)
                _NoPeriodCta(onStart: () => _startNewPeriod(context, ref))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (!closed && viewed != null)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => showBudgetFormSheet(context),
                      ),
                  ],
                ),
                if (closed)
                  Text('Periode ditutup — budget read-only',
                      style: Theme.of(context).textTheme.bodySmall),
                _BudgetList(readOnly: closed),
                const SizedBox(height: 24),
              ],
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
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId == null) return;
    await ref.read(budgetRepositoryProvider).startNewPeriod(userId, date);
    ref.read(selectedPeriodIdProvider.notifier).state = null; // balik ke aktif
  }
}

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.periods});

  final List<Period> periods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedPeriodIdProvider);
    final fmt = DateFormat('d MMM yyyy', 'id_ID');

    String label(Period p) => p.endedAt == null
        ? 'Aktif — sejak ${fmt.format(p.startedAt)}'
        : '${fmt.format(p.startedAt)} – ${fmt.format(p.endedAt!)}';

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Periode'),
            items: [
              if (periods.every((p) => p.endedAt != null))
                const DropdownMenuItem(value: null, child: Text('Bulan ini')),
              for (final p in periods)
                DropdownMenuItem(value: p.id, child: Text(label(p))),
            ],
            onChanged: (v) =>
                ref.read(selectedPeriodIdProvider.notifier).state = v,
          ),
        ),
      ],
    );
  }
}

class _PeriodSummaries extends ConsumerWidget {
  const _PeriodSummaries();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(periodSummariesProvider);
    final semantic = context.semanticColors;
    final fmt = DateFormat('d MMM', 'id_ID');

    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan per Periode',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final s in list)
              InkWell(
                onTap: () => ref.read(selectedPeriodIdProvider.notifier).state =
                    s.period.endedAt == null ? null : s.period.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.period.endedAt == null
                            ? 'Aktif (sejak ${fmt.format(s.period.startedAt)})'
                            : '${fmt.format(s.period.startedAt)} – ${fmt.format(s.period.endedAt!)}'),
                      ),
                      Text('+${formatRupiah(s.income)}',
                          style: TextStyle(color: semantic.income)),
                      const SizedBox(width: 8),
                      Text('-${formatRupiah(s.expense)}',
                          style: TextStyle(color: semantic.expense)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _NoPeriodCta extends StatelessWidget {
  const _NoPeriodCta({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        AppEmptyState.insights(),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(
            onPressed: onStart,
            child: const Text('Mulai periode'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BudgetList extends ConsumerWidget {
  const _BudgetList({this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
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
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(budgetsWithProgressProvider)),
      data: (items) {
        if (items.isEmpty) {
          return const Text('Belum ada budget di periode ini');
        }
        return Column(
          children: items.map((it) {
            final categoryName = categoriesAsync.maybeWhen(
              data: (cats) =>
                  cats.where((c) => c.id == it.budget.categoryId).firstOrNull?.name,
              orElse: () => null,
            );
            final color = it.pct >= 100
                ? semantic.danger
                : it.pct >= 80
                    ? semantic.warning
                    : semantic.income;
            final row = Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName ?? it.budget.categoryId),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (it.pct / 100).clamp(0, 1).toDouble(),
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatRupiah(it.spent)} / ${formatRupiah(it.budget.limitAmount)}',
                  ),
                ],
              ),
            );
            if (readOnly) return row;
            return Dismissible(
              key: ValueKey(it.budget.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: semantic.danger,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => ref
                  .read(budgetRepositoryProvider)
                  .deleteBudget(it.budget.id),
              child: row,
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
    final categoriesAsync = ref.watch(categoriesListProvider(null));
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
        final maxTotal =
            items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
        String nameOf(String id) => categoriesAsync.maybeWhen(
              data: (cats) =>
                  cats.where((c) => c.id == id).firstOrNull?.name ?? '?',
              orElse: () => '…',
            );
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(nameOf(items[i].categoryId),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            maxTotal == 0 ? 0 : (items[i].total / maxTotal),
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
