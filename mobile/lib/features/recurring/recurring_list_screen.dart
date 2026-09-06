import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/app_illustration.dart';
import '../../shared/currency_formatter.dart';
import '../../shared/dismiss_background.dart';
import '../../shared/skeleton.dart';
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
        loading: () => const SkeletonList(count: 4),
        error: (e, _) => AppErrorState(
            onRetry: () => ref.invalidate(recurringRulesListProvider)),
        data: (rules) {
          if (rules.isEmpty) {
            return AppEmptyState.recurring(
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
              ),
            );
          }
          return ListView(
            children: rules.map((r) {
              return Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) =>
                    ref.read(recurringRulesRepositoryProvider).delete(r.id),
                background: const DismissDeleteBackground(),
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
