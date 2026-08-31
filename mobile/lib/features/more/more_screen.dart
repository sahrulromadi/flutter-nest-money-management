import 'package:flutter/material.dart';

import '../accounts/accounts_list_screen.dart';
import '../categories/categories_list_screen.dart';
import '../goals/goals_list_screen.dart';
import '../recurring/recurring_list_screen.dart';
import '../reminders/reminder_settings_tiles.dart';
import 'sync_tile.dart';

/// Sisanya (theme toggle, PIN reset) belum masuk plan manapun, backlog
/// kecil setelah scope PRD Rilis 1-3 selesai.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Akun'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountsListScreen()),
            ),
          ),
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
          const ReminderSettingsTiles(),
          const Divider(),
          const SyncTile(),
        ],
      ),
    );
  }
}
