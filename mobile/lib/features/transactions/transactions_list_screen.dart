import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/skeleton.dart';
import '../../theme/app_semantic_colors.dart';
import '../accounts/accounts_providers.dart';
import '../home/home_providers.dart';
import 'transactions_providers.dart';

/// Filter akun aktif di halaman Transactions. `null` = semua akun.
final txnAccountFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(txnAccountFilterProvider);
    final transactionsAsync = ref.watch(
      transactionsListProvider(TransactionFilter(accountId: accountId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Column(
        children: [
          const _AccountBalanceStrip(),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const SkeletonList(count: 8),
              error: (e, _) => AppErrorState(
                onRetry: () => ref.invalidate(transactionsListProvider(
                    TransactionFilter(accountId: accountId))),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return accountId != null
                      ? const _EmptyState(filtered: true)
                      : AppEmptyState.transactions(
                          onAdd: () => context.push('/transactions/add'),
                        );
                }
                return _GroupedList(transactions: transactions);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(filtered
              ? 'Belum ada transaksi di akun ini'
              : 'Belum ada transaksi'),
          if (!filtered) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.push('/transactions/add'),
              child: const Text('Catat transaksi pertama'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Strip horizontal saldo per akun di atas list. Chip "Semua" (total gabungan)
/// + 1 chip per akun. Tap → filter list ke akun itu (`txnAccountFilterProvider`).
class _AccountBalanceStrip extends ConsumerWidget {
  const _AccountBalanceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);
    return accountsAsync.maybeWhen(
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: [
              const _TotalBalanceCard(),
              for (final a in accounts) _AccountBalanceCard(account: a),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TotalBalanceCard extends ConsumerWidget {
  const _TotalBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalBalanceProvider);
    final selected = ref.watch(txnAccountFilterProvider) == null;
    return _BalanceCard(
      label: 'Semua',
      value: total.maybeWhen(
        data: (v) => formatRupiah(v),
        orElse: () => '…',
      ),
      selected: selected,
      onTap: () => ref.read(txnAccountFilterProvider.notifier).state = null,
    );
  }
}

class _AccountBalanceCard extends ConsumerWidget {
  const _AccountBalanceCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountBalanceProvider(account));
    final selected = ref.watch(txnAccountFilterProvider) == account.id;
    return _BalanceCard(
      label: account.name,
      value: balance.maybeWhen(
        data: (v) => formatRupiah(v),
        orElse: () => '…',
      ),
      selected: selected,
      onTap: () =>
          ref.read(txnAccountFilterProvider.notifier).state = account.id,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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
      background: const DismissDeleteBackground(),
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
    // Include-deleted: akun yang udah dihapus tetap kebaca di histori transaksi.
    final name = ref.watch(accountsByIdProvider)[accountId]?.name ?? '';
    return Text(name);
  }
}
