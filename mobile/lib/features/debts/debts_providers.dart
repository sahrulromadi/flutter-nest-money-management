import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/debts_repository.dart';
import '../auth/current_user_provider.dart';

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DebtsRepository(db.debtsDao, db.transactionsDao);
});

final debtsListProvider =
    StreamProvider.autoDispose<List<Debt>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(debtsRepositoryProvider).watchAll(userId);
});

/// Total udah dilunasin per debt (SUM transaksi ke-tag), reaktif.
final debtProgressProvider =
    StreamProvider.autoDispose.family<double, String>((ref, debtId) {
  return ref.watch(debtsRepositoryProvider).watchProgress(debtId);
});
