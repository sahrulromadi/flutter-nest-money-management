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
import '../home/home_providers.dart';
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
          const _SearchField(),
          const _CategoryFilterChip(),
          const _AccountBalanceStrip(),
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

/// Dropdown filter kategori (semua type) di atas list — plan 036 item 1.
class _CategoryFilterChip extends ConsumerWidget {
  const _CategoryFilterChip();

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: DropdownButtonFormField<String?>(
        initialValue: selected,
        decoration: const InputDecoration(
          labelText: 'Kategori',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Semua kategori')),
          for (final c in categories)
            DropdownMenuItem(value: c.id, child: Text(c.name)),
          // Kategori ke-hapus/sistem yang lagi di-filter tapi ga ada di picker
          // biasa — tetep tampil biar dropdown-nya ga "lupa" pilihan lama.
          if (selected != null && categories.every((c) => c.id != selected))
            DropdownMenuItem(
              value: selected,
              child: Text(categoriesById[selected]?.name ?? '?'),
            ),
        ],
        onChanged: (v) => ref.read(txnCategoryFilterProvider.notifier).state = v,
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
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
