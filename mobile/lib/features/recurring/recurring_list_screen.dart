import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/currency_formatter.dart';
import 'recurring_form_screen.dart';
import 'recurring_providers.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) return const Center(child: Text('Belum ada aturan berulang'));
          return ListView(
            children: rules.map((r) {
              return Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await ref.read(recurringRulesApiProvider).delete(r.id);
                  ref.invalidate(recurringRulesListProvider);
                },
                background: Container(color: Theme.of(context).colorScheme.error),
                child: ListTile(
                  title: Text('${r.type} — ${formatRupiah(r.amount)}'),
                  subtitle: Text(
                    'Tiap ${r.intervalValue} ${r.intervalUnit} · Berikutnya: '
                    '${DateFormat('d MMM yyyy', 'id_ID').format(r.nextRunDate)}',
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
