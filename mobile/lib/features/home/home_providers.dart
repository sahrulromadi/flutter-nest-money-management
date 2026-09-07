import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../accounts/accounts_providers.dart';
import '../auth/current_user_provider.dart';
import '../transactions/transactions_providers.dart';

class MonthSnapshot {
  const MonthSnapshot({required this.income, required this.expense});
  final double income;
  final double expense;
}

final totalBalanceProvider = StreamProvider.autoDispose<double>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield 0;
    return;
  }
  yield* ref.watch(accountsRepositoryProvider).watchTotalBalance(userId);
});

final monthSnapshotProvider = Provider.autoDispose<AsyncValue<MonthSnapshot>>((ref) {
  final now = DateTime.now();
  final filter = TransactionFilter(from: DateTime(now.year, now.month, 1), to: now);
  final transactionsAsync = ref.watch(transactionsListProvider(filter));

  return transactionsAsync.whenData((list) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in list) {
      if (t.type == 'Income') income += t.amount;
      if (t.type == 'Expense') expense += t.amount;
    }
    return MonthSnapshot(income: income, expense: expense);
  });
});

/// Transaksi yang `occurred_at`-nya hari ini, urut `updated_at` desc.
final todayTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1));
  yield* ref
      .watch(transactionsRepositoryProvider)
      .watchAll(userId, from: start, to: end);
});
