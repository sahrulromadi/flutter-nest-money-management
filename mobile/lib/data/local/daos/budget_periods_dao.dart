import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budget_periods.dart';

part 'budget_periods_dao.g.dart';

@DriftAccessor(tables: [BudgetPeriods])
class BudgetPeriodsDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetPeriodsDaoMixin {
  BudgetPeriodsDao(super.db);

  Stream<List<BudgetPeriod>> watchAll(String userId) {
    return (select(budgetPeriods)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<BudgetPeriod?> findActive(String userId) =>
      (select(budgetPeriods)
            ..where((t) =>
                t.userId.equals(userId) &
                t.endedAt.isNull() &
                t.deletedAt.isNull()))
          .getSingleOrNull();

  Stream<BudgetPeriod?> watchActive(String userId) => (select(budgetPeriods)
        ..where((t) =>
            t.userId.equals(userId) &
            t.endedAt.isNull() &
            t.deletedAt.isNull()))
      .watchSingleOrNull();

  Future<void> upsert(BudgetPeriodsCompanion row) =>
      into(budgetPeriods).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, BudgetPeriodsCompanion row) =>
      (update(budgetPeriods)..where((t) => t.id.equals(id))).write(row);

  Future<List<BudgetPeriod>> findPendingSync() =>
      (select(budgetPeriods)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(budgetPeriods)..where((t) => t.id.equals(id)))
          .write(const BudgetPeriodsCompanion(pendingSync: Value(false)));
}
