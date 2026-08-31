import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll(String userId, {String? type}) {
    final query = select(categories)
      ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull());
    if (type != null) {
      query.where((t) => t.type.equals(type));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  Future<Category?> findById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(CategoriesCompanion row) =>
      into(categories).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, CategoriesCompanion row) =>
      (update(categories)..where((t) => t.id.equals(id))).write(row);

  Future<void> softDelete(String id, DateTime now) =>
      (update(categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSync: const Value(true),
        ),
      );

  Future<List<Category>> findPendingSync() =>
      (select(categories)..where((t) => t.pendingSync.equals(true))).get();

  Future<void> clearPendingSync(String id) =>
      (update(categories)..where((t) => t.id.equals(id)))
          .write(const CategoriesCompanion(pendingSync: Value(false)));
}
