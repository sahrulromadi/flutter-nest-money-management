import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Alias biar nama di Home screen jelas — sumbernya sama kayak yang dipake
/// Transactions tab (`recentTransactionsProvider`).
final recentTransactionsForHomeProvider = recentTransactionsProvider;
