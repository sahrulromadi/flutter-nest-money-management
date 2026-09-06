import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/periods.dart';

part 'periods_dao.g.dart';

@DriftAccessor(tables: [Periods])
class PeriodsDao extends DatabaseAccessor<AppDatabase>
    with _$PeriodsDaoMixin {
  PeriodsDao(super.db);

  Stream<List<Period>> watchAll(String userId) {
    return (select(periods)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<Period?> findActive(String userId) =>
      (select(periods)
            ..where((t) =>
                t.userId.equals(userId) &
                t.endedAt.isNull() &
                t.deletedAt.isNull()))
          .getSingleOrNull();

  Stream<Period?> watchActive(String userId) => (select(periods)
        ..where((t) =>
            t.userId.equals(userId) &
            t.endedAt.isNull() &
            t.deletedAt.isNull()))
      .watchSingleOrNull();

  Future<void> upsert(PeriodsCompanion row) =>
      into(periods).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, PeriodsCompanion row) =>
      (update(periods)..where((t) => t.id.equals(id))).write(row);

  Future<List<Period>> findPendingSync() =>
      (select(periods)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(periods)..where((t) => t.id.equals(id)))
          .write(const PeriodsCompanion(pendingSync: Value(false)));
}
