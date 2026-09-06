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
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: accountsAsync.when(
        loading: () => const SkeletonList(count: 4),
        error: (e, _) =>
            AppErrorState(onRetry: () => ref.invalidate(accountsListProvider)),
        data: (accounts) {
          if (accounts.isEmpty) {
            return AppEmptyState.accounts(onAdd: () => _openForm(context));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return _AccountTile(
                account: account,
                onTap: () => _openForm(context, account: account),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {Account? account}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AccountFormScreen(account: account)),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account, required this.onTap});

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account));
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(account.name),
      trailing: balanceAsync.when(
        loading: () => const Skeleton(width: 64, height: 16),
        error: (error, stackTrace) => const Text('-'),
        data: (balance) => Text(
          formatRupiah(balance),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      onTap: onTap,
    );
  }
}
