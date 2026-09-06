import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/repository/goals_repository.dart';
import '../auth/current_user_provider.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return GoalsRepository(db.goalsDao, db.transactionsDao);
});

final goalsListProvider =
    StreamProvider.autoDispose<List<Goal>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(goalsRepositoryProvider).watchAll(userId);
});

/// Total terkumpul per goal (SUM transaksi ke-tag), reaktif.
final goalProgressProvider =
    StreamProvider.autoDispose.family<double, String>((ref, goalId) {
  return ref.watch(goalsRepositoryProvider).watchProgress(goalId);
});
