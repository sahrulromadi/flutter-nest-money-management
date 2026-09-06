import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';
import '../../data/recurring/recurring_generator.dart';
import '../../data/repository/recurring_rules_repository.dart';
import '../auth/current_user_provider.dart';

final recurringRulesRepositoryProvider =
    Provider<RecurringRulesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringRulesRepository(db.recurringRulesDao);
});

final recurringRulesListProvider =
    StreamProvider.autoDispose<List<RecurringRule>>((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(recurringRulesRepositoryProvider).watchAll(userId);
});

final recurringGeneratorProvider = Provider<RecurringGenerator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringGenerator(db.recurringRulesDao, db.transactionsDao);
});

/// Jalanin generator sekali pas app launch. Di-`watch` di `main.dart` — best
/// effort, gak nge-block UI, gak butuh login (murni lokal).
final recurringStartupProvider = FutureProvider<void>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;
  await ref.read(recurringGeneratorProvider).run(userId);
});
