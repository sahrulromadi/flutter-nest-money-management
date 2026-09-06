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
    query.orderBy([
      (t) => OrderingTerm.asc(t.sortOrder),
      (t) => OrderingTerm.asc(t.createdAt),
    ]);
    return query.watch();
  }

  /// Termasuk yang udah di-soft-delete — buat lookup nama kategori di row
  /// transaksi historis (kategori kehapus tetap kebaca).
  Stream<List<Category>> watchAllIncludingDeleted(String userId) =>
      (select(categories)..where((t) => t.userId.equals(userId))).watch();

  Future<Category?> findById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Set urutan baru buat daftar id (index = sort_order). Semua ditandai dirty.
  Future<void> reorder(List<String> orderedIds, DateTime now) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(categories)..where((t) => t.id.equals(orderedIds[i]))).write(
          CategoriesCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
            pendingSync: const Value(true),
          ),
        );
      }
    });
  }

  Future<void> upsert(CategoriesCompanion row) =>
      into(categories).insertOnConflictUpdate(row);

  Future<void> updateFields(String id, CategoriesCompanion row) =>
      (update(categories)..where((t) => t.id.equals(id))).write(row);

  /// Soft delete kategori + subkategori-nya (cascade) biar sub gak jadi orphan.
  Future<void> softDelete(String id, DateTime now) =>
      (update(categories)
            ..where((t) =>
                (t.id.equals(id) | t.parentId.equals(id)) & t.deletedAt.isNull()))
          .write(
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
