import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/transactions_repository.dart';
import '../auth/current_user_provider.dart';
import '../categories/categories_providers.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionsRepository(
    db.transactionsDao,
    db.accountsDao,
    ref.watch(categoriesRepositoryProvider),
  );
});

class TransactionFilter {
  const TransactionFilter({this.accountId, this.categoryId, this.from, this.to});

  final String? accountId;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(accountId, categoryId, from, to);
}

final transactionsListProvider =
    StreamProvider.autoDispose.family<List<Transaction>, TransactionFilter>(
        (ref, filter) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(transactionsRepositoryProvider);
  yield* repo.watchAll(
    userId,
    accountId: filter.accountId,
    categoryId: filter.categoryId,
    from: filter.from,
    to: filter.to,
  );
});
