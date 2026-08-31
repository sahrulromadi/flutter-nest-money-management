import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/goals.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);

  Stream<List<Goal>> watchAll(String userId) {
    return (select(goals)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<void> upsert(GoalsCompanion row) =>
      into(goals).insertOnConflictUpdate(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(goals)..where((t) => t.id.equals(id))).write(
        GoalsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<Goal>> findPendingSync() =>
      (select(goals)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(goals)..where((t) => t.id.equals(id)))
          .write(const GoalsCompanion(pendingSync: Value(false)));
}
