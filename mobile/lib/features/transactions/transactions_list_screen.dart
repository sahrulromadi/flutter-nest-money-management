import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/currency_formatter.dart';
import '../../theme/app_semantic_colors.dart';
import '../accounts/accounts_providers.dart';
import 'transactions_providers.dart';

class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(transactionsListProvider(const TransactionFilter()));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada transaksi'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.push('/transactions/add'),
                    child: const Text('Catat transaksi pertama'),
                  ),
                ],
              ),
            );
          }
          return _GroupedList(transactions: transactions);
        },
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.transactions});

  final List<Transaction> transactions;

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    if (that == today) return 'Hari ini';
    if (that == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      final label = _dayLabel(t.occurredAt);
      groups.putIfAbsent(label, () => []).add(t);
    }

    return ListView(
      children: groups.entries.expand((entry) sync* {
        yield Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            entry.key,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        );
        for (final t in entry.value) {
          yield _TransactionTile(transaction: t);
        }
      }).toList(),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semanticColors;
    final color = switch (transaction.type) {
      'Income' => semantic.income,
      'Expense' => semantic.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };
    final sign = switch (transaction.type) {
      'Income' => '+',
      'Expense' => '-',
      _ => '',
    };

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: semantic.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          ref.read(transactionsRepositoryProvider).delete(transaction.id),
      child: ListTile(
        leading: Icon(
          switch (transaction.type) {
            'Income' => Icons.arrow_downward,
            'Expense' => Icons.arrow_upward,
            _ => Icons.swap_horiz,
          },
        ),
        title: Text(transaction.note?.isNotEmpty == true ? transaction.note! : transaction.type),
        subtitle: _AccountLabel(accountId: transaction.accountId),
        trailing: Text(
          '$sign${formatRupiah(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        onTap: () => context.push('/transactions/${transaction.id}/edit'),
      ),
    );
  }
}

class _AccountLabel extends ConsumerWidget {
  const _AccountLabel({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);
    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (accounts) {
        final match = accounts.where((a) => a.id == accountId);
        return Text(match.isEmpty ? '' : match.first.name);
      },
    );
  }
}
