import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import 'debt_form_screen.dart';
import 'debts_providers.dart';

class DebtsListScreen extends StatelessWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Utang & Piutang'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Utang'), Tab(text: 'Piutang')],
          ),
        ),
        body: const TabBarView(
          children: [
            _DirectionList(direction: 'Utang'),
            _DirectionList(direction: 'Piutang'),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index;
            final direction = tabIndex == 0 ? 'Utang' : 'Piutang';
            return FloatingActionButton(
              onPressed: () => _openForm(context, initialDirection: direction),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

void _openForm(BuildContext context, {Debt? debt, String? initialDirection}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DebtFormScreen(debt: debt, initialDirection: initialDirection),
    ),
  );
}

class _DirectionList extends ConsumerWidget {
  const _DirectionList({required this.direction});

  final String direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsListProvider);

    return debtsAsync.when(
      loading: () => const SkeletonList(count: 4),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(debtsListProvider)),
      data: (allDebts) {
        final debts = allDebts.where((d) => d.direction == direction).toList();
        if (debts.isEmpty) {
          return AppEmptyState.debts(
            onAdd: () => _openForm(context, initialDirection: direction),
          );
        }
        return Column(
          children: [
            _SummaryBanner(debts: debts, direction: direction),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: debts.map((d) => _DebtCard(debt: d)).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Total belum lunas 1 arah (Utang/Piutang) — jumlah (pokok - udah dibayar)
/// dari semua yang belum lunas.
class _SummaryBanner extends ConsumerWidget {
  const _SummaryBanner({required this.debts, required this.direction});

  final List<Debt> debts;
  final String direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var outstanding = 0.0;
    var unpaidCount = 0;
    for (final d in debts) {
      final paid = ref.watch(debtProgressProvider(d.id)).valueOrNull ?? 0;
      if (paid < d.amount) {
        outstanding += d.amount - paid;
        unpaidCount++;
      }
    }
    final scheme = Theme.of(context).colorScheme;
    final label = direction == 'Utang' ? 'Total belum dibayar' : 'Total belum ditagih';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            unpaidCount > 0 ? '$label ($unpaidCount)' : label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            formatRupiah(outstanding),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semanticColors;
    final paid = ref.watch(debtProgressProvider(debt.id)).valueOrNull ?? 0;
    final pct = debt.amount > 0 ? (paid / debt.amount * 100).round() : 0;
    final lunas = pct >= 100;
    final isUtang = debt.direction == 'Utang';
    final color = lunas ? semantic.income : Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: const DismissDeleteBackground(),
      onDismissed: (_) => ref.read(debtsRepositoryProvider).delete(debt.id),
      child: Card(
        child: InkWell(
          onTap: () => _openForm(context, debt: debt),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${isUtang ? 'Utang ke' : 'Piutang dari'} ${debt.counterparty}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (lunas)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: semantic.income.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lunas',
                          style: TextStyle(
                              color: semantic.income,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
                if (debt.dueDate != null)
                  Text(
                    'Tenggat: ${DateFormat('d MMM yyyy', 'id_ID').format(debt.dueDate!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (debt.note?.isNotEmpty == true)
                  Text(debt.note!, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0, 1).toDouble(),
                    color: color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${formatRupiah(paid)} / ${formatRupiah(debt.amount)}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
