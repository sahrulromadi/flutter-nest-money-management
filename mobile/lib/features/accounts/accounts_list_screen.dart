import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/skeleton.dart';
import 'account_form_screen.dart';
import 'accounts_providers.dart';

class AccountsListScreen extends ConsumerWidget {
  const AccountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: const _AccountList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _openForm(BuildContext context, {Account? account}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AccountFormScreen(account: account)),
  );
}

class _AccountList extends ConsumerStatefulWidget {
  const _AccountList();

  @override
  ConsumerState<_AccountList> createState() => _AccountListState();
}

class _AccountListState extends ConsumerState<_AccountList> {
  /// Urutan optimistik abis drag — dipakai sampai stream Drift nyusul,
  /// biar item ga "mental balik" lalu lompat lagi.
  List<Account>? _pending;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);

    ref.listen(accountsListProvider, (_, next) {
      final list = next.valueOrNull;
      if (list == null || _pending == null) return;
      final streamIds = list.map((a) => a.id).toList();
      final pendingIds = _pending!.map((a) => a.id).toList();
      if (listEquals(streamIds, pendingIds)) setState(() => _pending = null);
    });

    return accountsAsync.when(
      loading: () => const SkeletonList(count: 4),
      error: (e, _) =>
          AppErrorState(onRetry: () => ref.invalidate(accountsListProvider)),
      data: (streamAccounts) {
        if (streamAccounts.isEmpty) {
          return AppEmptyState.accounts(onAdd: () => _openForm(context));
        }
        final accounts = _pending ?? streamAccounts;
        return ReorderableListView.builder(
          itemCount: accounts.length,
          onReorderItem: (oldIndex, newIndex) {
            final reordered = [...accounts];
            reordered.insert(newIndex, reordered.removeAt(oldIndex));
            setState(() => _pending = reordered);
            ref
                .read(accountsRepositoryProvider)
                .reorder(reordered.map((a) => a.id).toList());
          },
          itemBuilder: (context, index) {
            final account = accounts[index];
            return _AccountTile(
              key: ValueKey(account.id),
              account: account,
              onTap: () => _openForm(context, account: account),
            );
          },
        );
      },
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({
    super.key,
    required this.account,
    required this.onTap,
  });

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account));
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(account.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          balanceAsync.when(
            loading: () => const Skeleton(width: 64, height: 16),
            error: (error, stackTrace) => const Text('-'),
            data: (balance) => Text(
              formatRupiah(balance),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.drag_handle,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
