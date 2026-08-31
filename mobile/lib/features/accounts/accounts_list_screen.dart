import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../shared/currency_formatter.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada akun'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _openForm(context),
                    child: const Text('Tambah akun'),
                  ),
                ],
              ),
            );
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

  IconData get _typeIcon => switch (account.type) {
        'Bank' => Icons.account_balance_outlined,
        'Ewallet' => Icons.smartphone_outlined,
        _ => Icons.payments_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account));
    return ListTile(
      leading: Icon(_typeIcon),
      title: Text(account.name),
      subtitle: Text(account.type),
      trailing: balanceAsync.when(
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
