import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/chart_colors.dart';
import '../auth/current_user_provider.dart';
import '../categories/categories_providers.dart';
import '../debts/debt_form_screen.dart';
import '../debts/debts_list_screen.dart';
import '../debts/debts_providers.dart';
import '../goals/goals_list_screen.dart';
import '../goals/goals_providers.dart';
import '../transactions/category_transactions_screen.dart';
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
              if (periods.isEmpty)
                _PeriodSelector(periods: periods)
              else
                Row(
                  children: [
                    Expanded(child: _PeriodSelector(periods: periods)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Mulai periode baru',
                      onPressed: () => _startNewPeriod(context, ref),
                    ),
                  ],
                ),
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
              const _GoalsInsightSection(),
              const _DebtsInsightSection(),
              Text('Breakdown Pengeluaran',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _CategoryBreakdownChart(type: 'Expense'),
              const SizedBox(height: 24),
              Text('Breakdown Pemasukan',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _CategoryBreakdownChart(type: 'Income'),
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
    if (periods.isEmpty) return const SizedBox.shrink();
    // Bind ke periode yang beneran lagi dilihat (bukan raw selection yg bisa null).
    final viewedId = ref.watch(viewedPeriodProvider)?.id;
    final fmt = DateFormat('d MMM yyyy', 'id_ID');

    String label(Period p) => p.endedAt == null
        ? 'Aktif — sejak ${fmt.format(p.startedAt)}'
        : '${fmt.format(p.startedAt)} – ${fmt.format(p.endedAt!)}';

    return DropdownButtonFormField<String>(
      initialValue: periods.any((p) => p.id == viewedId) ? viewedId : null,
      decoration: const InputDecoration(labelText: 'Periode'),
      items: [
        for (final p in periods)
          DropdownMenuItem(value: p.id, child: Text(label(p))),
      ],
      onChanged: (v) =>
          ref.read(selectedPeriodIdProvider.notifier).state = v,
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
                onTap: () => ref
                    .read(selectedPeriodIdProvider.notifier)
                    .state = s.period.id,
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
    final categoriesById = ref.watch(categoriesByIdProvider);
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
            final categoryName = categoriesById[it.budget.categoryId]?.name;
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
              background: const DismissDeleteBackground(),
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

class _CategoryBreakdownChart extends ConsumerWidget {
  const _CategoryBreakdownChart({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider(type));
    final categoriesById = ref.watch(categoriesByIdProvider);
    final range = ref.watch(reportRangeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return breakdownAsync.when(
      loading: () => const Column(
        children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
          Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Skeleton(height: 16)),
        ],
      ),
      error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(categoryBreakdownProvider(type))),
      data: (items) {
        if (items.isEmpty) return const Text('Belum ada data');
        final maxTotal =
            items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
        String nameOf(String? id) {
          if (id == null) return 'Tanpa kategori';
          return categoriesById[id]?.name ?? '?';
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++)
              InkWell(
                onTap: items[i].categoryId == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryTransactionsScreen(
                              categoryId: items[i].categoryId!,
                              title: nameOf(items[i].categoryId),
                              from: range.from,
                              to: range.to,
                            ),
                          ),
                        ),
                child: Padding(
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
              ),
          ],
        );
      },
    );
  }
}

/// Ringkasan Goals di Insights (kalau ada) — nama + progress bar. Tap row /
/// "Lihat semua" -> GoalsListScreen (gak ada edit per-item, plan 036).
class _GoalsInsightSection extends ConsumerWidget {
  const _GoalsInsightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListProvider);
    final goals = goalsAsync.valueOrNull ?? const <Goal>[];
    if (goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Goals', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoalsListScreen()),
              ),
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        for (final g in goals) _GoalInsightRow(goal: g),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GoalInsightRow extends ConsumerWidget {
  const _GoalInsightRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semanticColors;
    final collected = ref.watch(goalProgressProvider(goal.id)).valueOrNull ?? 0;
    final pct = goal.targetAmount > 0
        ? (collected / goal.targetAmount * 100).round()
        : 0;
    final color =
        pct >= 100 ? semantic.income : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GoalsListScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal.name),
                Text(
                    '${formatRupiah(collected)} / ${formatRupiah(goal.targetAmount)}'),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1).toDouble(),
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan Utang/Piutang di Insights (kalau ada). Tap row -> edit debt
/// langsung (plan 036 — fitur edit); "Lihat semua" -> DebtsListScreen.
class _DebtsInsightSection extends ConsumerWidget {
  const _DebtsInsightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsListProvider);
    final debts = debtsAsync.valueOrNull ?? const <Debt>[];
    if (debts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utang & Piutang', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebtsListScreen()),
              ),
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        for (final d in debts) _DebtInsightRow(debt: d),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DebtInsightRow extends ConsumerWidget {
  const _DebtInsightRow({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semanticColors;
    final paid = ref.watch(debtProgressProvider(debt.id)).valueOrNull ?? 0;
    final pct = debt.amount > 0 ? (paid / debt.amount * 100).round() : 0;
    final color =
        pct >= 100 ? semantic.income : Theme.of(context).colorScheme.primary;
    final label =
        '${debt.direction == 'Utang' ? 'Utang ke' : 'Piutang dari'} ${debt.counterparty}';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DebtFormScreen(debt: debt)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text('${formatRupiah(paid)} / ${formatRupiah(debt.amount)}'),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1).toDouble(),
                color: color,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
