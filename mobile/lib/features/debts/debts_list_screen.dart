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

class DebtsListScreen extends ConsumerWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Utang & Piutang')),
      body: debtsAsync.when(
        loading: () => const SkeletonList(count: 4),
        error: (e, _) =>
            AppErrorState(onRetry: () => ref.invalidate(debtsListProvider)),
        data: (debts) {
          if (debts.isEmpty) {
            return AppEmptyState.debts(onAdd: () => _openForm(context));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: debts.map((d) => _DebtCard(debt: d)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebtFormScreen()),
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
    final pct =
        debt.amount > 0 ? (paid / debt.amount * 100).round() : 0;
    final lunas = pct >= 100;
    final isUtang = debt.direction == 'Utang';
    final color = lunas ? semantic.income : Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: const DismissDeleteBackground(),
      onDismissed: (_) => ref.read(debtsRepositoryProvider).delete(debt.id),
      child: Card(
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
                ),
              if (debt.note?.isNotEmpty == true) Text(debt.note!),
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
    );
  }
}
