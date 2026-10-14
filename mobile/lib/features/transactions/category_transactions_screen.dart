import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_illustration.dart';
import '../../shared/skeleton.dart';
import 'transactions_list_screen.dart' show GroupedTransactionsList;
import 'transactions_providers.dart';

/// Drill-down dari breakdown kategori (Insights) — list transaksi 1 kategori
/// di 1 rentang periode (plan 036 item 3).
class CategoryTransactionsScreen extends ConsumerWidget {
  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.title,
    required this.from,
    required this.to,
  });

  final String categoryId;
  final String title;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = TransactionFilter(categoryId: categoryId, from: from, to: to);
    final transactionsAsync = ref.watch(transactionsListProvider(filter));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: transactionsAsync.when(
        loading: () => const SkeletonList(count: 6),
        error: (e, _) => AppErrorState(
          onRetry: () => ref.invalidate(transactionsListProvider(filter)),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada transaksi kategori ini di periode ini'),
            );
          }
          return GroupedTransactionsList(transactions: transactions);
        },
      ),
    );
  }
}
