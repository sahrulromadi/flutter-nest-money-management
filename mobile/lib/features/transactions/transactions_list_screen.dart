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
import '../categories/categories_providers.dart';
import 'transaction_display.dart';
import 'transactions_providers.dart';

/// Filter akun aktif di halaman Transactions. `null` = semua akun.
final txnAccountFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Filter kategori aktif di halaman Transactions. `null` = semua kategori.
final txnCategoryFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Kata kunci search transaksi — catatan doang (plan 036 item 1).
final txnSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Transaksi yang catatannya match [query] (case-insensitive substring).
/// Kosong = ga difilter.
List<Transaction> filterTransactionsBySearch(
  List<Transaction> transactions,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return transactions;
  return transactions
      .where((t) => t.note?.toLowerCase().contains(q) == true)
      .toList();
}

class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(txnAccountFilterProvider);
    final categoryId = ref.watch(txnCategoryFilterProvider);
    final query = ref.watch(txnSearchQueryProvider);
    final filter = TransactionFilter(accountId: accountId, categoryId: categoryId);
    final transactionsAsync = ref.watch(transactionsListProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Column(
        children: [
          const _SearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const SkeletonList(count: 8),
              error: (e, _) =>
                  AppErrorState(onRetry: () => ref.invalidate(transactionsListProvider(filter))),
              data: (transactions) {
                final filtered = filterTransactionsBySearch(transactions, query);
                if (filtered.isEmpty) {
                  if (query.isNotEmpty) {
                    return const _EmptyState(
                        message: 'Ga ada transaksi yang cocok');
                  }
                  return (accountId != null || categoryId != null)
                      ? const _EmptyState(
                          message: 'Belum ada transaksi dengan filter ini')
                      : AppEmptyState.transactions(
                          onAdd: () => context.push('/transactions/add'),
                        );
                }
                return GroupedTransactionsList(transactions: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Search catatan + filter kategori (icon compact, popup menu) dalam 1 baris.
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final _controller =
      TextEditingController(text: ref.read(txnSearchQueryProvider));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = ref.watch(txnSearchQueryProvider).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Cari catatan',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(txnSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (v) => ref.read(txnSearchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(width: 4),
          const _CategoryFilterButton(),
          const SizedBox(width: 4),
          const _AccountFilterButton(),
        ],
      ),
    );
  }
}

/// Filter kategori — icon button + popup menu, biar ringkas (plan 036 item 1).
class _CategoryFilterButton extends ConsumerWidget {
  const _CategoryFilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesById = ref.watch(categoriesByIdProvider);
    final selected = ref.watch(txnCategoryFilterProvider);
    final expenseAsync = ref.watch(categoriesListProvider('Expense'));
    final incomeAsync = ref.watch(categoriesListProvider('Income'));
    final categories = [
      ...expenseAsync.valueOrNull ?? const <Category>[],
      ...incomeAsync.valueOrNull ?? const <Category>[],
    ];
    if (categories.isEmpty && selected == null) return const SizedBox.shrink();
    final active = selected != null;

    return PopupMenuButton<String?>(
      tooltip: 'Filter kategori',
      icon: Icon(
        Icons.filter_list,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      onSelected: (v) => ref.read(txnCategoryFilterProvider.notifier).state = v,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Semua kategori')),
        for (final c in categories)
          PopupMenuItem(value: c.id, child: Text(c.name)),
        // Kategori ke-hapus/sistem yang lagi di-filter tapi ga ada di picker
        // biasa — tetep tampil biar pilihan lama ga "ketelen".
        if (selected != null && categories.every((c) => c.id != selected))
          PopupMenuItem(
            value: selected,
            child: Text(categoriesById[selected]?.name ?? '?'),
          ),
      ],
    );
  }
}

/// Filter akun — icon button + popup menu (plan 036: balance card dicabut,
/// datanya udah ada di tab Akun).
class _AccountFilterButton extends ConsumerWidget {
  const _AccountFilterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsById = ref.watch(accountsByIdProvider);
    final selected = ref.watch(txnAccountFilterProvider);
    final accounts = ref.watch(accountsListProvider).valueOrNull ?? const <Account>[];
    if (accounts.isEmpty && selected == null) return const SizedBox.shrink();
    final active = selected != null;

    return PopupMenuButton<String?>(
      tooltip: 'Filter akun',
      icon: Icon(
        Icons.account_balance_wallet_outlined,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      onSelected: (v) => ref.read(txnAccountFilterProvider.notifier).state = v,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Semua akun')),
        for (final a in accounts) PopupMenuItem(value: a.id, child: Text(a.name)),
        if (selected != null && accounts.every((a) => a.id != selected))
          PopupMenuItem(
            value: selected,
            child: Text(accountsById[selected]?.name ?? '?'),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class GroupedTransactionsList extends StatelessWidget {
  const GroupedTransactionsList({super.key, required this.transactions});

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
      final label = _dayLabel(t.updatedAt.toLocal());
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
    final visual = transactionTypeVisual(context, transaction.type);
    final amountColor = switch (transaction.type) {
      'Income' => semantic.income,
      'Expense' => semantic.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };
    final sign = switch (transaction.type) {
      'Income' => '+',
      'Expense' => '-',
      _ => '',
    };
    final title =
        transactionTitle(transaction, ref.watch(categoriesByIdProvider));

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: const DismissDeleteBackground(),
      onDismissed: (_) =>
          ref.read(transactionsRepositoryProvider).delete(transaction.id),
      child: ListTile(
        leading: Icon(visual.icon, color: visual.color),
        title: Text(title),
        subtitle: _AccountLabel(accountId: transaction.accountId),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign${formatRupiah(transaction.amount)}',
              style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(transaction.updatedAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
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
