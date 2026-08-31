import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/accounts_repository.dart';
import '../auth/current_user_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountsRepository(db.accountsDao, db.transactionsDao);
});

final accountsListProvider =
    StreamProvider.autoDispose<List<Account>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  final repo = ref.watch(accountsRepositoryProvider);
  yield* repo.watchAll(userId);
});

final accountBalanceProvider =
    StreamProvider.autoDispose.family<double, Account>((ref, account) {
  return ref.watch(accountsRepositoryProvider).watchBalance(account);
});
