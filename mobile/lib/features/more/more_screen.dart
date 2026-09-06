import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../categories/categories_list_screen.dart';
import '../goals/goals_list_screen.dart';
import '../recurring/recurring_list_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
          'Data lokal tetap tersimpan di device. Tinggal login lagi buat sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // logout() clear token & set state loggedOut → router auto-redirect ke /login.
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authPhase = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat_outlined),
            title: const Text('Transaksi Berulang'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Goals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsListScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(),
          if (authPhase == AuthPhase.unlocked)
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Keluar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmLogout(context, ref),
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              subtitle: const Text('Opsional — biar bisa sync ke server'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/login'),
            ),
        ],
      ),
    );
  }
}
