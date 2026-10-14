import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/debts.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [Debts])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  Stream<List<Debt>> watchAll(String userId) {
    return (select(debts)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<void> upsert(DebtsCompanion row) =>
      into(debts).insertOnConflictUpdate(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(debts)..where((t) => t.id.equals(id))).write(
        DebtsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<Debt>> findPendingSync() =>
      (select(debts)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(debts)..where((t) => t.id.equals(id)))
          .write(const DebtsCompanion(pendingSync: Value(false)));
}
