import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  Stream<List<Budget>> watchByPeriod(String periodId) {
    return (select(budgets)
          ..where((t) =>
              t.periodId.equals(periodId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<void> upsert(BudgetsCompanion row) =>
      into(budgets).insertOnConflictUpdate(row);

  Future<Budget?> findByPeriodAndCategory(
    String periodId,
    String categoryId,
  ) =>
      (select(budgets)
            ..where((t) =>
                t.periodId.equals(periodId) &
                t.categoryId.equals(categoryId) &
                t.deletedAt.isNull()))
          .getSingleOrNull();

  Future<void> updateFields(String id, BudgetsCompanion row) =>
      (update(budgets)..where((t) => t.id.equals(id))).write(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(budgets)..where((t) => t.id.equals(id))).write(
        BudgetsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<Budget>> findPendingSync() =>
      (select(budgets)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(budgets)..where((t) => t.id.equals(id)))
          .write(const BudgetsCompanion(pendingSync: Value(false)));
}
